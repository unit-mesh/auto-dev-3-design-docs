# 修复：Agent 模式下 SessionSidebar 新建会话时清空聊天记录

## 问题描述
当用户在 SessionSidebar 点击 "New Chat" 按钮创建新会话时：
1. ✅ 新会话显示在 SessionSidebar 列表中（已通过 `getAllSessions()` 修复）
2. ❌ **AgentChatInterface 中的聊天记录没有清空**（本次修复）

## 根本原因
在 `AutoDevApp.kt` 中，SessionSidebar 的 `onNewChat` 和 `onSessionSelected` 回调只更新了本地的 `messages` 状态，但没有调用 `AgentChatInterface` 内部 `CodingAgentViewModel` 的相应方法来清空 Renderer 中的消息。

## 解决方案

### 1. 在 AgentChatInterface 中导出内部处理器

**文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentChatInterface.kt`

添加两个新参数来导出 ViewModel 的会话处理器：

```kotlin
fun AgentChatInterface(
    // ... 其他参数 ...
    // 内部会话处理器导出（用于 SessionSidebar）
    onInternalSessionSelected: (((String) -> Unit) -> Unit)? = null,
    onInternalNewChat: ((() -> Unit) -> Unit)? = null,
) {
    // ViewModel 的内部处理器
    val handleSessionSelected: (String) -> Unit = remember(viewModel) {
        { sessionId ->
            viewModel.switchSession(sessionId)
            onSessionSelected?.invoke(sessionId)
        }
    }

    val handleNewChat: () -> Unit = remember(viewModel) {
        {
            viewModel.newSession()  // 清空 Renderer 消息
            onNewChat?.invoke()
        }
    }

    // 导出给父组件
    LaunchedEffect(handleSessionSelected, handleNewChat) {
        onInternalSessionSelected?.invoke(handleSessionSelected)
        onInternalNewChat?.invoke(handleNewChat)
    }
}
```

### 2. 在 AutoDevApp 中连接 SessionSidebar 到 Agent ViewModel

**文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`

#### (1) 添加状态变量存储 Agent 的处理器

```kotlin
// Agent 模式的会话处理器（用于连接 SessionSidebar 和 AgentChatInterface）
var agentSessionSelectedHandler by remember { mutableStateOf<((String) -> Unit)?>(null) }
var agentNewChatHandler by remember { mutableStateOf<(() -> Unit)?>(null) }
```

#### (2) 在 SessionSidebar 回调中判断模式并调用相应处理器

```kotlin
SessionSidebar(
    // ...
    onSessionSelected = { sessionId ->
        // Agent 模式：调用 Agent ViewModel 的处理器
        if (useAgentMode && agentSessionSelectedHandler != null) {
            agentSessionSelectedHandler?.invoke(sessionId)
        } else {
            // Chat 模式：直接更新本地状态
            chatHistoryManager.switchSession(sessionId)
            messages = chatHistoryManager.getMessages()
            currentStreamingOutput = ""
        }
    },
    onNewChat = {
        // Agent 模式：调用 Agent ViewModel 的处理器
        if (useAgentMode && agentNewChatHandler != null) {
            agentNewChatHandler?.invoke()
        } else {
            // Chat 模式：直接更新本地状态
            chatHistoryManager.createSession()
            messages = emptyList()
            currentStreamingOutput = ""
        }
    },
)
```

#### (3) 在 AgentChatInterface 调用时传入处理器接收回调

```kotlin
AgentChatInterface(
    // ...
    // 导出内部处理器给 SessionSidebar 使用
    onInternalSessionSelected = { handler ->
        agentSessionSelectedHandler = handler
    },
    onInternalNewChat = { handler ->
        agentNewChatHandler = handler
    },
)
```

## 技术细节

### 为什么需要导出处理器？

因为 `AgentChatInterface` 内部有自己的 `CodingAgentViewModel`，它管理着 `ComposeRenderer` 中的消息列表。当在 SessionSidebar 中切换或新建会话时，需要调用 ViewModel 的 `switchSession()` 或 `newSession()` 方法来清空 Renderer。

### 类型签名解释

```kotlin
onInternalSessionSelected: (((String) -> Unit) -> Unit)? = null
```

这是一个"接收函数的函数"：
- 外层 `(... -> Unit)`: 这个回调本身是一个函数
- 内层 `(String) -> Unit`: 传递给这个回调的参数是另一个函数（会话处理器）

在调用时：
```kotlin
onInternalSessionSelected = { handler ->  // handler 是 (String) -> Unit
    agentSessionSelectedHandler = handler  // 保存到状态变量
}
```

## 测试步骤

### Agent 模式测试
1. 启动应用（Agent 模式）
2. 在 AgentChatInterface 中发送几条消息
3. 在 SessionSidebar 点击 "+" 按钮创建新会话
4. **验证**：
   - ✅ 新会话立即出现在 SessionSidebar 列表中
   - ✅ AgentChatInterface 中的聊天记录被清空
   - ✅ 显示空的聊天界面，可以开始新对话

### Chat 模式测试
1. 切换到 Chat 模式（非 Agent）
2. 发送几条消息
3. 在 SessionSidebar 点击 "+" 按钮
4. **验证**：
   - ✅ 新会话出现在列表中
   - ✅ Chat 界面清空
   - ✅ 功能正常工作

### 会话切换测试
1. 创建多个会话（每个会话发送不同的消息）
2. 在 SessionSidebar 中点击不同的会话
3. **验证**：
   - ✅ Agent 模式：切换会话时加载对应的历史消息
   - ✅ Chat 模式：切换会话时加载对应的历史消息
   - ✅ 消息显示正确

## 预期结果
✅ SessionSidebar 和 AgentChatInterface/Chat 界面完全同步  
✅ 新建会话时聊天记录被正确清空  
✅ 切换会话时加载正确的历史消息  
✅ Agent 模式和 Chat 模式都正常工作
