# 修复 Compose UI 远程 Agent 流式显示问题

## 问题描述

RemoteAgentChatInterface 虽然客户端使用了流式读取 SSE（`ByteReadChannel.readUTF8Line()`），但在 Compose UI 中仍然不是流式显示，表现为一次性显示完整内容。

**关键发现**：CLI（TypeScript）版本流式显示正常，说明服务器端完全没有问题。

## 根本原因

**协程调度器使用错误**！

```kotlin
// ❌ 问题代码
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
```

使用 `Dispatchers.Default`（后台线程池）来收集 Flow 和更新 Compose 状态，导致：
1. 状态更新不在主线程
2. Compose 重组被延迟或批处理
3. UI 无法实时更新

## CLI vs Compose UI 对比

### CLI（TypeScript）- 流式正常 ✅

```typescript
// ServerAgentClient.ts
async *executeStream(request: AgentRequest): AsyncGenerator<AgentEvent> {
  for await (const chunk of response.body as any) {
    buffer += decoder.decode(chunk, { stream: true });
    // ... 解析
    yield event;  // 立即 yield
  }
}

// index.tsx
for await (const event of client.executeStream(requestParams)) {
  renderer.renderEvent(event);  // 主事件循环，立即渲染到终端
}
```

- **运行在主事件循环**
- **立即输出到终端**：`process.stdout.write(content)`
- **无缓冲/批处理**

### Compose UI（Kotlin）- 非流式 ❌

```kotlin
// ❌ 问题代码
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

scope.launch {
    client.executeStream(request).collect { event ->
        handleRemoteEvent(event)  // 在后台线程更新状态
        // ComposeRenderer 更新 mutableStateOf
    }
}
```

- **运行在后台线程**（`Dispatchers.Default`）
- **更新 Compose 状态**：`_currentStreamingOutput = content`
- **重组被延迟/批处理**

## 解决方案

### 核心修改

将协程调度器从 `Dispatchers.Default` 改为 `Dispatchers.Main`：

```kotlin
// ✅ 正确代码
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
```

这样：
1. **Flow 收集在主线程执行**
2. **状态更新立即触发 Compose 重组**
3. **UI 实时更新，实现流式显示**

### 具体修改

**文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/remote/RemoteCodingAgentViewModel.kt`

```kotlin
class RemoteCodingAgentViewModel(
    private val serverUrl: String,
    private val useServerConfig: Boolean = false
) {
    // ⚠️ 使用 Dispatchers.Main 确保 UI 状态更新在主线程，实现流式渲染
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val client = RemoteAgentClient(serverUrl)
    
    // ...
    
    fun executeTask(projectId: String, task: String, gitUrl: String = "") {
        currentExecutionJob = scope.launch {
            // ... 
            
            // Stream events from server and forward to renderer
            // ⚠️ 关键：collect 在 Main 线程执行（由 scope 决定），确保 UI 状态实时更新
            client.executeStream(request).collect { event ->
                handleRemoteEvent(event)
                // ...
            }
        }
    }
}
```

## 技术原理

### Kotlin Coroutines + Compose

1. **协程上下文继承**：
   - `scope.launch {}` 继承 scope 的调度器
   - 如果 scope 使用 `Dispatchers.Main`，则 `launch` 块在主线程执行

2. **Compose 状态更新**：
   - `mutableStateOf` 的更新可以在任何线程
   - 但 Compose 重组调度器会优化/批处理更新
   - **在主线程更新状态 = 立即调度重组**

3. **Flow 收集**：
   - `flow.collect {}` 在调用者的协程上下文中执行
   - 网络 IO（`ByteReadChannel.readUTF8Line()`）会自动切换到 IO 线程
   - 但 `emit()` 和 `collect {}` 回调在原上下文执行

### 为什么 CLI 不需要考虑这个？

TypeScript/Node.js：
- 单线程事件循环
- 所有回调都在主线程
- `process.stdout.write()` 直接写入底层文件描述符，无缓冲

Kotlin/Compose：
- 多线程协程
- 需要显式管理线程切换
- Compose 重组有调度机制

## 验证结果

✅ JVM 平台编译成功  
✅ 所有测试通过  
✅ 与 CLI 行为一致

## 流式渲染流程（修复后）

```
服务器发送 SSE chunk
  ↓
Ktor Client 逐行读取 (IO 线程)
  ↓
parseSSEStreamRealtime emit event
  ↓
RemoteCodingAgentViewModel.collect (Main 线程) ← 关键！
  ↓
handleRemoteEvent()
  ↓
ComposeRenderer.renderLLMResponseChunk() (Main 线程)
  ↓
_currentStreamingOutput.value = ... (Main 线程)
  ↓
Compose 立即调度重组
  ↓
UI 实时更新 ✨
```

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/remote/RemoteCodingAgentViewModel.kt` - 修复协程调度器
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ComposeRenderer.kt` - 状态更新
- `mpp-ui/src/jsMain/typescript/agents/ServerAgentClient.ts` - CLI 参考实现

## 经验教训

1. **Compose 状态更新最好在 Main 线程**
   - 虽然技术上可以在任何线程更新 `mutableStateOf`
   - 但在主线程更新能确保立即调度重组，实现流式 UI

2. **对比不同实现很有价值**
   - CLI（TypeScript）正常 → 排除服务器问题
   - 快速定位到客户端实现差异

3. **协程调度器选择很重要**
   - `Dispatchers.Default` 适合 CPU 密集型计算
   - `Dispatchers.IO` 适合阻塞 IO
   - **`Dispatchers.Main` 适合 UI 更新和轻量级协调**

4. **不要过度优化**
   - 网络 IO 已经在 Ktor 内部用 IO 调度器处理
   - 不需要手动 `flowOn(Dispatchers.IO)`
   - 保持简单，让框架处理底层细节

