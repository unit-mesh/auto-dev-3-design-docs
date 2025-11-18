# Remote Agent 使用指南

## 快速开始

### 1. 启动 mpp-server

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-server:run

# 服务器将在 http://localhost:8080 启动
```

### 2. 配置客户端

在 `~/.autodev/config.yaml` 中添加：

```yaml
active: default
configs:
  - name: default
    provider: openai
    model: gpt-4
    apiKey: sk-xxx
    
# 远程服务器配置
remoteServer:
  url: "http://localhost:8080"
  enabled: true
  useServerConfig: false  # false = 使用本地 LLM 配置
```

### 3. 在 Compose 中使用

```kotlin
import cc.unitmesh.devins.ui.config.ConfigManager
import cc.unitmesh.devins.ui.remote.RemoteAgentChatInterface

@Composable
fun MyApp() {
    val config = ConfigManager.load()
    val remoteServer = config.getRemoteServer()
    
    // 项目 ID 状态
    var selectedProjectId by remember { mutableStateOf("") }
    
    if (remoteServer.enabled) {
        // 远程模式
        RemoteAgentChatInterface(
            serverUrl = remoteServer.url,
            useServerConfig = remoteServer.useServerConfig,
            projectId = selectedProjectId,
            onProjectChange = { selectedProjectId = it },
            onConfigWarning = { /* 打开配置对话框 */ }
        )
    } else {
        // 本地模式
        AgentChatInterface(
            llmService = myLLMService,
            onConfigWarning = { /* 打开配置对话框 */ }
        )
    }
}
```

## 配置选项

### RemoteServerConfig

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `url` | String | `"http://localhost:8080"` | mpp-server 地址 |
| `enabled` | Boolean | `false` | 是否启用远程模式 |
| `useServerConfig` | Boolean | `false` | 是否使用服务器的 LLM 配置 |

### 使用场景

#### 场景 1：使用本地 LLM 配置

```yaml
remoteServer:
  url: "http://localhost:8080"
  enabled: true
  useServerConfig: false  # 使用本地配置
  
# 本地 LLM 配置会发送到服务器
configs:
  - name: default
    provider: openai
    model: gpt-4
    apiKey: sk-xxx
```

#### 场景 2：使用服务器 LLM 配置

```yaml
remoteServer:
  url: "http://localhost:8080"
  enabled: true
  useServerConfig: true  # 使用服务器配置
  
# 不需要本地 LLM 配置，服务器会提供
```

## 服务器端配置

在服务器端 (`application.conf`):

```hocon
llm {
  provider = "openai"
  model = "gpt-4"
  apiKey = "sk-xxx"
  baseUrl = ""  # 可选
}

projects {
  autocrud {
    name = "AutoCrud"
    path = "/path/to/autocrud"
    description = "AutoCrud project"
  }
}
```

## 功能特性

### ✅ 已实现

1. **远程连接**
   - 健康检查
   - 自动重连
   - 连接状态显示

2. **项目管理**
   - 获取服务器项目列表
   - 项目选择器 UI
   - Git URL 智能检测

3. **SSE 流式输出**
   - LLM 响应实时流
   - 工具调用/结果显示
   - Git 克隆进度
   - 错误处理

4. **配置管理**
   - 本地/服务器配置切换
   - 配置持久化
   - 多平台支持

### 🎯 使用提示

1. **首次使用**
   - 先启动 mpp-server
   - 配置 `~/.autodev/config.yaml`
   - 检查连接状态指示器

2. **项目选择**
   - 可以选择服务器上的现有项目
   - 也可以输入 Git URL（自动克隆）

3. **调试**
   - 查看服务器日志：`~/.autodev/logs/autodev-app.log`
   - 查看聊天历史：`~/.autodev/logs/chat-history-*.json`

## 架构对比

| 组件 | CLI (TypeScript) | Compose (Kotlin) |
|------|------------------|------------------|
| HTTP 客户端 | node-fetch | Ktor HttpClient |
| SSE 解析 | 手动 Buffer | Ktor + Flow |
| 渲染器 | ServerRenderer | ComposeRenderer |
| UI 框架 | Ink (TUI) | Compose Multiplatform |

## 故障排除

### 连接失败

```
❌ Connection Error: Failed to connect to server
```

**解决方法**：
1. 确认 mpp-server 正在运行
2. 检查 `serverUrl` 配置
3. 检查防火墙设置

### 项目未找到

```
❌ Error: Project not found: xxx
```

**解决方法**：
1. 检查服务器 `application.conf` 中的项目配置
2. 或使用 Git URL 让服务器自动克隆

### LLM 配置错误

```
❌ No active LLM configuration found
```

**解决方法**：
- 如果 `useServerConfig = false`，确保本地有 LLM 配置
- 或设置 `useServerConfig = true` 使用服务器配置

## 示例项目

查看完整示例：
- 本地模式：`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentChatInterface.kt`
- 远程模式：`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/remote/RemoteAgentChatInterface.kt`

## 相关文档

- [架构设计](remote-agent-compose.md)
- [服务器配置](../../mpp-server/README.md)
- [CLI 使用](../../mpp-ui/README.md)

