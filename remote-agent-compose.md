# Remote Agent Implementation for Compose

## 概述

成功为 Compose 实现了远程 AI Agent 功能，与 CLI 的 `runServerAgent` 功能对等。

## 架构分析

### 核心原理

**关键洞察**：本地模式和远程模式的区别仅在于 **Renderer 的数据源不同**

- **本地模式**：`CodingAgent` → 直接调用 `ComposeRenderer` 方法
- **远程模式**：`mpp-server` → SSE 事件流 → `RemoteAgentClient` → `ComposeRenderer` 方法

由于 `ServerSideRenderer` (服务器端) 和 `ComposeRenderer` (客户端) 都实现了 `CodingAgentRenderer` 接口，事件完全兼容。

### 组件架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Compose UI (Client)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  RemoteAgentChatInterface                        │      │
│  │  ├─ RemoteCodingAgentViewModel                   │      │
│  │  │  ├─ RemoteAgentClient (Ktor HTTP)             │      │
│  │  │  └─ ComposeRenderer                           │      │
│  │  └─ Project Selector / Connection Status         │      │
│  └──────────────────────────────────────────────────┘      │
│                          ▲                                   │
│                          │ SSE Events                        │
│                          │                                   │
└──────────────────────────┼──────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │    HTTP/SSE Stream      │
              │ /api/agent/stream       │
              └────────────┬────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   mpp-server (Backend)                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  AgentService                                     │      │
│  │  ├─ CodingAgent                                   │      │
│  │  └─ ServerSideRenderer                           │      │
│  │     └─ Channel<AgentEvent> → SSE Stream          │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 实现的组件

### 1. RemoteAgentClient.kt (commonMain)

**功能**：使用 Ktor HTTP 客户端连接到 mpp-server

**关键特性**：
- 健康检查 (`/health`)
- 获取项目列表 (`/api/projects`)
- SSE 流式执行 (`/api/agent/stream`)
- 事件类型解析：
  - `clone_progress` / `clone_log` - Git 克隆进度
  - `iteration` - 迭代开始
  - `llm_chunk` - LLM 响应流
  - `tool_call` / `tool_result` - 工具调用和结果
  - `error` / `complete` - 错误和完成

**代码示例**：
```kotlin
val client = RemoteAgentClient("http://localhost:8080")
client.executeStream(request).collect { event ->
    when (event) {
        is RemoteAgentEvent.LLMChunk -> // 处理 LLM 输出
        is RemoteAgentEvent.ToolCall -> // 工具调用
        is RemoteAgentEvent.Complete -> // 完成
    }
}
```

### 2. RemoteCodingAgentViewModel.kt (commonMain)

**功能**：管理远程连接和事件转发到 `ComposeRenderer`

**关键方法**：
- `checkConnection()` - 检查服务器连接
- `executeTask(projectId, task)` - 执行远程任务
- `handleRemoteEvent(event)` - **核心桥接**：将 `RemoteAgentEvent` 转换为 `ComposeRenderer` 调用

**事件转发示例**：
```kotlin
private fun handleRemoteEvent(event: RemoteAgentEvent) {
    when (event) {
        is RemoteAgentEvent.Iteration -> 
            renderer.renderIterationHeader(event.current, event.max)
        
        is RemoteAgentEvent.LLMChunk -> 
            renderer.renderLLMResponseChunk(event.chunk)
        
        is RemoteAgentEvent.ToolCall -> 
            renderer.renderToolCall(event.toolName, event.params)
        
        is RemoteAgentEvent.ToolResult -> 
            renderer.renderToolResult(event.toolName, event.success, event.output)
    }
}
```

### 3. RemoteAgentChatInterface.kt (commonMain)

**功能**：远程 Agent 的 Compose UI 界面

**UI 组件**：
- `ProjectSelector` - 项目选择下拉菜单
- `RemoteConnectionStatusBar` - 连接状态指示器
- `AgentMessageList` - 消息列表（复用本地组件）
- `DevInEditorInput` - 输入框（复用本地组件）

### 4. 配置管理扩展

**新增配置项** (`ConfigFile.kt`):
```kotlin
@Serializable
data class ConfigFile(
    // ... 现有字段
    val remoteServer: RemoteServerConfig? = null
)

@Serializable
data class RemoteServerConfig(
    val url: String = "http://localhost:8080",
    val enabled: Boolean = false,
    val useServerConfig: Boolean = false // 是否使用服务器的 LLM 配置
)
```

**配置文件示例** (`~/.autodev/config.yaml`):
```yaml
active: default
configs:
  - name: default
    provider: openai
    model: gpt-4
    apiKey: sk-xxx
remoteServer:
  url: "http://localhost:8080"
  enabled: true
  useServerConfig: false
```

## 使用方式

### 1. 启动 mpp-server

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-server:run

# 服务器将在 http://localhost:8080 启动
```

### 2. 配置远程服务器

在 `~/.autodev/config.yaml` 中添加：

```yaml
remoteServer:
  url: "http://localhost:8080"
  enabled: true
  useServerConfig: false  # false = 使用本地 LLM 配置，true = 使用服务器配置
```

### 3. 在 Compose UI 中使用

```kotlin
@Composable
fun MyApp() {
    val config = ConfigManager.load()
    val remoteServer = config.getRemoteServer()
    
    if (remoteServer.enabled) {
        RemoteAgentChatInterface(
            serverUrl = remoteServer.url,
            useServerConfig = remoteServer.useServerConfig,
            projectId = "my-project",
            onProjectChange = { /* ... */ }
        )
    } else {
        AgentChatInterface(
            // 本地模式
        )
    }
}
```

## 与 CLI 实现的对比

| 特性 | CLI (TypeScript) | Compose (Kotlin) |
|------|-----------------|------------------|
| HTTP 客户端 | node-fetch | Ktor HttpClient |
| SSE 解析 | 手动 Buffer 解析 | Ktor + Flow |
| 渲染器 | ServerRenderer.ts | ComposeRenderer |
| 事件类型 | TypeScript AgentEvent | Kotlin RemoteAgentEvent |
| UI 框架 | Ink (TUI) | Compose Multiplatform |

## 优势

1. **代码复用**：`ComposeRenderer` 既用于本地又用于远程，无需重复实现
2. **类型安全**：Kotlin 的类型系统提供编译时检查
3. **多平台支持**：Ktor 支持 JVM/Android/JS/Native
4. **统一体验**：远程模式和本地模式的 UI 完全一致

## 测试步骤

```bash
# 1. 构建 mpp-core
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:assembleJsPackage

# 2. 启动 mpp-server
./gradlew :mpp-server:run

# 3. 构建并运行 Compose UI
./gradlew :mpp-ui:run

# 4. 在 UI 中切换到远程模式，选择项目，输入任务
```

## 未来扩展

- [ ] 添加 WebSocket 支持以替代 SSE（更好的双向通信）
- [ ] 支持远程项目的 Git 克隆进度显示
- [ ] 添加远程服务器健康监控和自动重连
- [ ] 支持多个远程服务器配置和切换
- [ ] 添加远程任务队列和历史记录

## 参考文件

- CLI 实现：`mpp-ui/src/jsMain/typescript/index.tsx` (runServerAgent)
- 服务器端：`mpp-server/src/main/kotlin/cc/unitmesh/server/render/ServerSideRenderer.kt`
- 路由配置：`mpp-server/src/main/kotlin/cc/unitmesh/server/plugins/Routing.kt`

