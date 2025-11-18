# Session Management Implementation Summary

## Overview
实现了完整的 session 管理功能，使 Agent 模式能够正确保存、加载和切换会话历史。

## 主要改进

### 1. 完整的对话历史保存
**文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/CodingAgentViewModel.kt`

#### 改进前
- 只保存简化的消息: `"Agent task completed: $task"`
- 丢失了所有工具调用、终端输出等详细信息

#### 改进后
`saveAgentExecutionHistory()` 函数保存完整的对话历史：
- ✅ LLM 的推理消息（ASSISTANT 消息）
- ✅ 工具调用和执行结果（包括工具名称、参数、输出）
- ✅ 终端命令和输出（包括退出码）
- ✅ 任务完成状态
- ✅ 错误信息

#### 数据格式示例
```json
{
  "role": "ASSISTANT",
  "content": "🔧 Tool: read-file\n   Read file: /path/to/file.js\n   Result: ✅ Success",
  "timestamp": 1763012345678
}
```

### 2. Session 切换功能
**文件**: `CodingAgentViewModel.kt`

#### 实现的方法
```kotlin
fun newSession() {
    renderer.clearMessages()
    chatHistoryManager?.createSession()
}

fun switchSession(sessionId: String) {
    chatHistoryManager?.let { manager ->
        val session = manager.switchSession(sessionId)
        if (session != null) {
            // Clear current renderer state
            renderer.clearMessages()
            
            // Load messages from the switched session
            val messages = manager.getMessages()
            messages.forEach { message ->
                when (message.role) {
                    MessageRole.USER -> renderer.addUserMessage(message.content)
                    MessageRole.ASSISTANT -> {
                        renderer.renderLLMResponseStart()
                        renderer.renderLLMResponseChunk(message.content)
                        renderer.renderLLMResponseEnd()
                    }
                    else -> {}
                }
            }
        }
    }
}
```

#### 功能特性
- ✅ 创建新会话时清空 renderer
- ✅ 切换会话时正确加载历史消息
- ✅ 保持 renderer 状态与 ChatHistoryManager 同步

### 3. AutoDevApp 集成
**文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`

#### Session 切换触发器机制
由于 `CodingAgentViewModel` 在 `AgentChatInterface` 内部创建，`AutoDevApp` 无法直接访问它。因此使用触发器（Trigger）模式：

```kotlin
// 1. 在 AutoDevApp 中创建触发器状态变量
var agentSessionSwitchTrigger by remember { mutableStateOf<Pair<String, Long>?>(null) }
var agentNewChatTrigger by remember { mutableStateOf(0L) }

// 2. SessionSidebar 根据模式设置触发器
SessionSidebar(
    onSessionSelected = { sessionId ->
        if (useAgentMode) {
            // Agent 模式：设置触发器
            agentSessionSwitchTrigger = Pair(sessionId, System.currentTimeMillis())
        } else {
            // Chat 模式：直接更新本地状态
            chatHistoryManager.switchSession(sessionId)
            messages = chatHistoryManager.getMessages()
        }
    },
    onNewChat = {
        if (useAgentMode) {
            agentNewChatTrigger = System.currentTimeMillis()
        } else {
            chatHistoryManager.createSession()
            messages = emptyList()
        }
    }
)

// 3. AgentChatInterface 接收触发器参数
AgentChatInterface(
    sessionSwitchTrigger = agentSessionSwitchTrigger,
    newChatTrigger = agentNewChatTrigger,
    ...
)

// 4. AgentChatInterface 内部监听触发器变化
LaunchedEffect(sessionSwitchTrigger) {
    sessionSwitchTrigger?.let { (sessionId, _) ->
        viewModel.switchSession(sessionId)
    }
}

LaunchedEffect(newChatTrigger) {
    if (newChatTrigger > 0L) {
        viewModel.newSession()
    }
}
```

#### 工作流程
1. 用户在 SessionSidebar 中选择会话
2. SessionSidebar 检查当前模式，设置 `agentSessionSwitchTrigger`
3. `AgentChatInterface` 的 `LaunchedEffect` 监听到触发器变化
4. 调用 `viewModel.switchSession(sessionId)`
5. ViewModel 清空 renderer 并加载历史消息
6. UI 自动更新显示历史对话

#### 为什么使用触发器模式？
- ViewModel 在 `AgentChatInterface` 内部创建，外部无法访问
- 触发器使用时间戳确保每次都能触发（即使切换到同一个 session）
- 支持 Chat 和 Agent 两种模式的不同处理逻辑
- 保持组件解耦，避免将 ViewModel 提升到全局

## 保存的对话内容示例

### 完整的对话历史（JSON）
```json
[
  {
    "id": "session-1",
    "messages": [
      {
        "role": "USER",
        "content": "编写一个 Node.js hello world",
        "timestamp": 1763012325638
      },
      {
        "role": "ASSISTANT",
        "content": "我将帮你创建一个简单的 Node.js Hello World 程序...",
        "timestamp": 1763012326000
      },
      {
        "role": "ASSISTANT",
        "content": "🔧 Tool: write-file\n   Write to: hello.js\n   Result: ✅ File created successfully",
        "timestamp": 1763012327000
      },
      {
        "role": "ASSISTANT",
        "content": "💻 Command: node hello.js\n   Exit code: 0\n   Output:\n   Hello, World!",
        "timestamp": 1763012328000
      },
      {
        "role": "ASSISTANT",
        "content": "✅ Task completed successfully",
        "timestamp": 1763012329000
      }
    ],
    "createdAt": 1763012325638,
    "updatedAt": 1763012329000
  }
]
```

## 与 ConversationManager 的关系

### ConversationManager
- **职责**: 管理 Agent 与 LLM 的多轮对话
- **范围**: 单个 Agent 任务的对话历史
- **内容**: 包括 SYSTEM、USER、ASSISTANT 消息，以及工具调用结果

### ChatHistoryManager
- **职责**: 管理多个会话的历史记录
- **范围**: 跨任务的会话历史
- **内容**: 简化的对话摘要，便于持久化和 UI 显示

### 数据流
```
用户输入
  ↓
CodingAgentViewModel
  ↓
ConversationManager (完整的 LLM 对话)
  ↓
CodingAgent.getConversationHistory()
  ↓
saveAgentExecutionHistory() (提取摘要)
  ↓
ChatHistoryManager (持久化)
  ↓
SessionStorage (JSON 文件)
```

## 测试步骤

### 1. 创建新会话
```kotlin
// 用户点击 "New Chat"
viewModel.newSession()
// ✅ 清空 renderer
// ✅ 创建新的 session
// ✅ chatHistoryManager.currentSessionId 更新
```

### 2. 执行任务
```kotlin
// 用户输入任务
viewModel.executeTask("编写一个 Node.js hello world")
// ✅ 保存用户消息
// ✅ 执行 Agent 任务
// ✅ 保存完整的对话历史（工具调用、输出等）
```

### 3. 切换会话
```kotlin
// 用户在 SessionSidebar 中选择另一个会话
viewModel.switchSession(sessionId)
// ✅ 清空 renderer
// ✅ 加载该会话的历史消息
// ✅ UI 显示历史对话
```

### 4. 验证持久化
```bash
# 检查保存的 JSON 文件
cat ~/.autodev/sessions/chat-sessions.json
# 应该包含完整的对话内容（工具调用、终端输出等）
```

## 已验证的功能
- ✅ 编译通过（无错误）
- ✅ Session 创建功能
- ✅ Session 切换功能
- ✅ 完整对话历史保存
- ✅ 历史消息加载到 renderer
- ✅ UI 回调正确连接

## 注意事项

### 避免重复保存
`saveAgentExecutionHistory()` 使用 `timelineSizeBeforeExecution` 来追踪任务开始前的 timeline 大小，只保存新增的消息，避免重复保存之前的历史。

### 内容截断
为了避免保存过大的内容，终端输出会被截断到 500 字符：
```kotlin
val truncatedOutput = if (item.output.length > 500) {
    "${item.output.take(500)}...\n[Output truncated]"
} else {
    item.output
}
```

### 空会话不保存
`ChatHistoryManager` 只保存有消息的会话，空会话不会写入磁盘。

## 下一步优化（可选）

1. **会话摘要生成**: 使用 LLM 为每个会话生成简短的标题/摘要
2. **搜索功能**: 在历史会话中搜索关键词
3. **导出功能**: 导出会话为 Markdown 或 PDF 格式
4. **云同步**: 将会话历史同步到云端（如果有远程服务器）
5. **压缩历史**: 对于非常长的对话，使用 ConversationManager 的压缩功能

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/CodingAgentViewModel.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentChatInterface.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/llm/ChatHistoryManager.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/conversation/ConversationManager.kt`

