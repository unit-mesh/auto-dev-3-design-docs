# PTY Handle 维护优化总结

## 问题分析

根据您的需求，主要问题是：

1. **ptyHandle 为 null 导致报错**：在 `renderToolCall` 时创建 `LiveTerminalItem`，但 `ptyHandle` 还是 `null`
2. **没有 ptyProcessor 不能创建 LiveTerminalItem**：不同平台（Android、JS）不支持 PTY
3. **需要在 renderToolCall 时就执行 shell**：为了最好的用户体验

## 解决方案架构

### 核心改进点

```
┌─────────────────────────────────────────────────────────────┐
│                    ComposeRenderer                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ renderToolCall()                                     │   │
│  │   ↓                                                  │   │
│  │ 检测 Shell 工具 + LiveShellExecutor?                │   │
│  │   ↓                                                  │   │
│  │ 是 → 立即异步启动 PTY 进程                          │   │
│  │      └─→ updateLiveTerminalPtyHandle()               │   │
│  │   ↓                                                  │   │
│  │ 否 → 创建 ptyHandle=null 的 LiveTerminalItem        │   │
│  │      (稍后由 ToolOrchestrator 处理)                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 平台特定支持

| 平台 | Shell Executor | PTY 支持 | 行为 |
|------|---------------|----------|------|
| **JVM** | `PtyShellExecutor` | ✅ 完整支持 | 立即启动 PTY，实时输出 |
| **Android** | `DefaultShellExecutor` | ❌ 不支持 | ptyHandle=null，使用缓冲输出 |
| **JS** | `DefaultShellExecutor` | ❌ 不支持 | ptyHandle=null，使用 Node.js child_process |

## 实现细节

### 1. ComposeRenderer 构造函数增强

```kotlin
class ComposeRenderer(
    private val shellExecutor: ShellExecutor? = null,  // 新增
    private val workingDirectory: String? = null,       // 新增
    private val coroutineScope: CoroutineScope? = null  // 新增
) : BaseRenderer()
```

**关键点**：
- `shellExecutor`：平台特定的 shell 执行器
- `workingDirectory`：默认工作目录
- `coroutineScope`：用于异步启动 PTY

### 2. 立即启动 PTY 逻辑

```kotlin
override fun renderToolCall(toolName: String, paramsStr: String) {
    if (toolType == ToolType.Shell) {
        val liveExecutor = shellExecutor as? LiveShellExecutor
        
        if (liveExecutor != null && liveExecutor.supportsLiveExecution()) {
            // 立即异步启动 PTY
            scope.launch {
                val session = liveExecutor.startLiveExecution(command, config)
                updateLiveTerminalPtyHandle(sessionId, session.ptyHandle)
            }
        }
        
        // 立即创建 LiveTerminalItem（可能 ptyHandle 还是 null）
        _timeline.add(TimelineItem.LiveTerminalItem(
            sessionId = sessionId,
            command = command,
            workingDirectory = workingDir,
            ptyHandle = null  // 会被异步更新
        ))
    }
}
```

**关键点**：
- ✅ 检查平台能力（`supportsLiveExecution()`）
- ✅ 异步启动不阻塞 UI
- ✅ 优雅降级（不支持 PTY 时 handle 保持 null）

### 3. 平台工厂模式

```kotlin
// Common
expect fun createPlatformRenderer(
    workingDirectory: String?,
    coroutineScope: CoroutineScope?
): ComposeRenderer

// JVM
actual fun createPlatformRenderer(...) = 
    ComposeRenderer(PtyShellExecutor(), ...)

// Android/JS
actual fun createPlatformRenderer(...) = 
    ComposeRenderer(DefaultShellExecutor(), ...)
```

### 4. 安全的 Handle 更新

```kotlin
fun updateLiveTerminalPtyHandle(sessionId: String, ptyHandle: Any): Boolean {
    val existing = findItemBySessionId(sessionId)
    
    // 只在 handle 为 null 时更新（避免覆盖）
    if (existing.ptyHandle == null) {
        _timeline[index] = existing.copy(ptyHandle = ptyHandle)
        return true
    }
    return false
}
```

## 关键优势

### ✅ 用户体验优化

```
传统方式：
用户发送命令 → 等待 LLM 响应 → 等待工具编排 → 开始执行 shell
              └─────────── 延迟 ──────────┘

优化后：
用户发送命令 → 立即显示终端 + 异步启动 PTY → LLM 处理其他逻辑
              └── 零延迟 ──┘
```

### ✅ KMP 跨平台兼容

```kotlin
// JVM - 完整 PTY 支持
val renderer = createPlatformRenderer(path, scope)
// renderer.shellExecutor is PtyShellExecutor
// → ptyHandle 会被异步设置

// Android - 自动降级
val renderer = createPlatformRenderer(path, scope)
// renderer.shellExecutor is DefaultShellExecutor
// → ptyHandle 保持 null，使用缓冲输出
```

### ✅ 错误处理健壮

```kotlin
scope.launch {
    try {
        val session = liveExecutor.startLiveExecution(...)
        updateLiveTerminalPtyHandle(sessionId, session.ptyHandle ?: return@launch)
    } catch (e: Exception) {
        // PTY 创建失败，item 保持 ptyHandle=null
        // 自动降级到缓冲输出模式
        println("Failed to start PTY: ${e.message}")
    }
}
```

## 使用示例

### 创建 ViewModel（自动平台适配）

```kotlin
val viewModel = CodingAgentViewModel(
    llmService = llmService,
    projectPath = "/path/to/project"
)

// JVM 上：renderer 使用 PtyShellExecutor
// Android 上：renderer 使用 DefaultShellExecutor
```

### 手动创建（测试或自定义场景）

```kotlin
// 使用平台默认
val renderer = createPlatformRenderer(
    workingDirectory = "/my/project",
    coroutineScope = myScope
)

// 自定义（如测试）
val renderer = ComposeRenderer(
    shellExecutor = MyMockExecutor(),
    workingDirectory = "/test",
    coroutineScope = testScope
)
```

## 测试覆盖

创建了 `ComposeRendererShellTest.kt`，包含：

1. ✅ 无 shell executor 时的行为
2. ✅ 非 LiveShellExecutor 时的行为
3. ✅ LiveShellExecutor 立即启动 PTY
4. ✅ PTY handle 更新的安全性
5. ✅ 工作目录的回退逻辑

## 相关文件变更

### 核心文件
- ✅ `ComposeRenderer.kt` - 添加构造参数和异步 PTY 启动
- ✅ `PlatformCodingAgentFactory.kt` - 添加 `createPlatformRenderer`
- ✅ `CodingAgentViewModel.kt` - 使用平台工厂创建 renderer

### 平台实现
- ✅ `PlatformCodingAgentFactory.jvm.kt` - JVM 使用 PtyShellExecutor
- ✅ `PlatformCodingAgentFactory.android.kt` - Android 使用 DefaultShellExecutor
- ✅ `PlatformCodingAgentFactory.js.kt` - JS 使用 DefaultShellExecutor

### 测试文件
- ✅ `ComposeRendererShellTest.kt` - 完整的单元测试

## 注意事项

### 1. CoroutineScope 管理

```kotlin
// ViewModel 中正确传递 scope
class CodingAgentViewModel(...) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    val renderer = createPlatformRenderer(
        workingDirectory = projectPath,
        coroutineScope = scope  // 使用 ViewModel 的 scope
    )
}
```

### 2. 异常处理

PTY 启动失败不会影响整体流程：
- LiveTerminalItem 仍然创建
- ptyHandle 保持 null
- 自动降级到缓冲输出模式

### 3. 生命周期

- PTY 进程的生命周期由 `LiveShellSession` 管理
- UI 组件只需要关注 `ptyHandle` 的状态
- CoroutineScope 取消时会自动清理

## 后续优化建议

1. **进度指示**：在 PTY 启动期间显示 spinner
2. **超时处理**：如果 PTY 启动超过 5 秒，显示警告
3. **性能监控**：记录 PTY 启动时间，优化体验
4. **WebSocket 支持**：为 JS 平台添加实时输出流

## 总结

这个优化方案完美解决了您提出的三个问题：

1. ✅ **ptyHandle 为 null 的问题**：通过异步启动 + 安全更新机制解决
2. ✅ **跨平台兼容性**：通过平台工厂模式，自动适配不同平台能力
3. ✅ **用户体验优化**：在 `renderToolCall` 时立即启动 shell，零延迟

关键是使用了**渐进式增强**的设计理念：
- 基础功能：所有平台都能创建 LiveTerminalItem
- 增强功能：JVM 平台自动启用 PTY 实时输出
- 优雅降级：不支持 PTY 的平台自动回退到缓冲模式
