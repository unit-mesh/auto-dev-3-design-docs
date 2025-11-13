# Session Switching Test - 完整测试指南

## 问题诊断与修复历史

### 第一版问题（已修复）
1. **AgentChatInterface 中会话功能不工作** - 消息列表为空
2. **新建 Session 不工作** - 创建新会话后无反应

**根本原因**:
- Desktop 平台未传入 `chatHistoryManager`
- `CodingAgentViewModel` 未加载历史消息

### 第二版问题（本次修复）

**问题描述**:
Agent 模式保存的聊天历史不完整，只保存了简化的"任务完成"消息：

```json
{
    "role": "ASSISTANT",
    "content": "Agent task completed: 编写一个 Node.js hello world"
}
```

**期望的完整历史**:
应该像 Chat 模式一样保存完整的对话，包括：
- Agent 的推理过程
- 所有工具调用和结果
- 迭代信息
- 最终结果

**根本原因**:
在 `CodingAgentViewModel.executeTask()` 中，只保存了一行简单的摘要：
```kotlin
val resultSummary = "Agent task completed: $task"
chatHistoryManager?.addAssistantMessage(resultSummary)  // ❌ 信息丢失
```

而 `ComposeRenderer.timeline` 已经维护了完整的执行历史，包括：
- `MessageItem` - LLM 的推理和响应
- `CombinedToolItem` - 工具调用和结果
- `TaskCompleteItem` - 最终完成状态

## 修复方案

### 修改的文件

**CodingAgentViewModel.kt** - 从 renderer.timeline 提取完整历史

```kotlin
val result = codingAgent.executeTask(agentTask)

// 保存完整的 Agent 执行历史到会话
val executionSummary = buildString {
    appendLine("=== Agent Execution Summary ===")
    
    // 统计信息
    val toolCalls = renderer.timeline.filterIsInstance<ComposeRenderer.TimelineItem.CombinedToolItem>()
    val assistantMessages = renderer.timeline
        .filterIsInstance<ComposeRenderer.TimelineItem.MessageItem>()
        .filter { it.message.role == MessageRole.ASSISTANT }
    
    appendLine("Task: $task")
    appendLine("Iterations: ${renderer.currentIteration} / ${renderer.maxIterations}")
    appendLine("Tool Calls: ${toolCalls.size}")
    
    // Agent 的推理过程
    appendLine("--- Agent Reasoning ---")
    assistantMessages.forEach { item ->
        appendLine(item.message.content)
    }
    
    // 工具调用历史
    appendLine("--- Tool Execution History ---")
    toolCalls.forEachIndexed { index, tool ->
        appendLine("${index + 1}. ${tool.toolName}")
        appendLine("   Description: ${tool.description}")
        tool.summary?.let { appendLine("   Result: $it") }
    }
    
    // 最终结果
    val taskComplete = renderer.timeline
        .filterIsInstance<ComposeRenderer.TimelineItem.TaskCompleteItem>()
        .lastOrNull()
    taskComplete?.let {
        appendLine("--- Final Result ---")
        appendLine(if (it.success) "✅ Success" else "❌ Failed")
        appendLine(it.message)
    }
}

chatHistoryManager?.addAssistantMessage(executionSummary)
```

### 保存的历史示例

修复后，Agent 执行会保存完整的结构化历史：

```json
{
    "role": "USER",
    "content": "编写一个 Node.js hello world"
},
{
    "role": "ASSISTANT",
    "content": "=== Agent Execution Summary ===\n\nTask: 编写一个 Node.js hello world\nIterations: 3 / 100\nTool Calls: 5\nAssistant Messages: 3\n\n--- Agent Reasoning ---\nI'll create a simple Node.js hello world application...\n\nFirst, I need to check if there's a package.json...\n\nNow I'll create the main file...\n\n--- Tool Execution History ---\n1. read-file\n   Description: Read package.json\n   Result: File not found\n\n2. write-file\n   Description: Create package.json\n   Result: ✅ File created successfully\n\n3. write-file\n   Description: Create index.js with hello world code\n   Result: ✅ File created successfully\n\n4. shell\n   Description: Run node index.js to test\n   Result: Hello, World!\n\n5. read-file\n   Description: Verify index.js contents\n   Result: ✅ File contents verified\n\n--- Final Result ---\n✅ Success\nSuccessfully created a Node.js hello world application with package.json and index.js"
}
```

## 测试步骤

### Test 1: Agent 模式完整历史保存

#### 步骤 1: 执行一个简单任务
```
1. 启动应用，切换到 Agent 模式
2. 输入任务："创建一个 Python hello world 文件"
3. 等待 Agent 执行完成
```

#### 步骤 2: 检查保存的历史
```bash
cat ~/.autodev/sessions/chat-sessions.json | jq '.[0].messages[-1]'
```

**验证点**:
- ✅ 包含 "=== Agent Execution Summary ===" 标题
- ✅ 显示任务描述和迭代次数
- ✅ 列出所有工具调用
- ✅ 包含 Agent 的推理过程
- ✅ 显示最终结果状态

#### 步骤 3: 多轮对话测试
```
1. 继续在同一会话中输入："修改文件，添加一个函数"
2. 等待执行完成
3. 再次检查历史文件
```

**验证点**:
- ✅ 历史文件包含两条 USER 消息
- ✅ 历史文件包含两条完整的 ASSISTANT 响应
- ✅ 每条响应都是独立完整的

### Test 2: 会话切换后历史正确

#### 步骤 1: 切换到 Chat 模式
1. 使用顶部切换按钮切换到 Chat 模式
2. 验证：
   - ✅ SessionSidebar 可见（Desktop）
   - ✅ 显示所有历史会话

#### 步骤 2: 创建多个会话
1. 发送消息："Hello from session 1"
2. 点击 "New Chat" 按钮
3. 发送消息："Hello from session 2"
4. 点击 "New Chat" 按钮
5. 发送消息："Hello from session 3"

#### 步骤 3: 切换会话
1. 在 SessionSidebar 点击第一个会话
2. 验证：
   - ✅ 消息区域显示 "Hello from session 1"
   - ✅ 该会话在 sidebar 高亮显示
3. 点击第二个会话
4. 验证：
   - ✅ 消息区域显示 "Hello from session 2"
   - ✅ 该会话在 sidebar 高亮显示

#### 步骤 4: 删除会话
1. 在 SessionSidebar 点击某个会话的删除按钮
2. 确认删除
3. 验证：
   - ✅ 会话从列表中消失
   - ✅ 如果删除的是当前会话，自动切换到其他会话
   - ✅ `~/.autodev/sessions/chat-sessions.json` 更新

### Test 3: 跨模式会话共享

#### 步骤 1: 在 Chat 模式创建会话
1. Chat 模式下发送消息："Test message in chat mode"
2. 记下会话 ID（在 sidebar 或日志中）

#### 步骤 2: 切换到 Agent 模式
1. 切换到 Agent 模式
2. 执行任务："Create a test file"
3. 验证：
   - ✅ 新消息保存到同一个会话历史
   - ✅ Agent 模式和 Chat 模式共享会话数据

#### 步骤 3: 切换回 Chat 模式
1. 切换回 Chat 模式
2. 验证：
   - ✅ 显示包括 Agent 任务在内的完整历史

## 单元测试（未来添加）

### Test: switchSession saves current session
```kotlin
@Test
fun testSwitchSessionSavesCurrentSession() = runTest {
    val manager = ChatHistoryManager()
    manager.initialize()
    
    // Create first session with message
    val session1 = manager.createSession()
    manager.addUserMessage("Message 1")
    
    // Create second session
    val session2 = manager.createSession()
    
    // Switch back to first session
    manager.switchSession(session1.id)
    
    // Verify session was saved
    val savedSessions = manager.getAllSessions()
    assertTrue(savedSessions.any { it.id == session2.id })
}
```

### Test: CodingAgentViewModel loads history
```kotlin
@Test
fun testViewModelLoadsHistory() = runTest {
    val manager = ChatHistoryManager()
    manager.initialize()
    manager.addUserMessage("Historic message")
    
    val viewModel = CodingAgentViewModel(
        llmService = mockLLMService,
        projectPath = "/tmp/test",
        chatHistoryManager = manager
    )
    
    // Verify renderer has the historic message
    assertTrue(viewModel.renderer.timeline.any { 
        it is TimelineItem.MessageItem && 
        it.message.content == "Historic message"
    })
}
```

## 已知限制

1. **Agent 模式暂不支持 SessionSidebar**
   - Agent 模式主要用于单次任务执行
   - 会话历史保存在后台，但 UI 不显示切换选项
   - 未来可通过添加 `onSessionSelected` 和 `onNewChat` 回调支持

2. **WASM 平台限制**
   - WASM 不显示 SessionSidebar（空间限制）
   - 但会话数据仍会保存到浏览器 LocalStorage

3. **会话标题**
   - 当前使用第一条消息的摘要作为标题
   - 暂不支持自定义会话标题

## 相关文件

### 核心文件
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/llm/ChatHistoryManager.kt`
  - 会话管理核心逻辑
  - `switchSession()` 方法：保存当前会话并切换

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/CodingAgentViewModel.kt`
  - Agent 模式 ViewModel
  - 新增：`switchSession()` 方法
  - 修改：`init` 块加载历史消息

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentChatInterface.kt`
  - Agent 模式 UI 组件
  - 新增：会话切换回调参数

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`
  - 主应用入口
  - 修复：Desktop 平台传入 chatHistoryManager

### 辅助文件
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/SessionSidebar.kt`
  - 会话侧边栏 UI
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ComposeRenderer.kt`
  - Agent 消息渲染器

## 调试技巧

### 启用调试日志
查看 `~/.autodev/logs/autodev-app.log` 了解：
- 会话创建/切换事件
- 消息保存操作
- 错误信息

### 检查会话文件
```bash
# 查看保存的会话
cat ~/.autodev/sessions/chat-sessions.json | jq .

# 监控文件变化
watch -n 1 'cat ~/.autodev/sessions/chat-sessions.json | jq .'
```

### 清空会话（测试用）
```bash
rm -f ~/.autodev/sessions/chat-sessions.json
```

## 总结

**修复前**:
- ❌ Agent 模式无会话管理
- ❌ Desktop 平台 AgentChatInterface 消息为空
- ❌ 切换会话后看不到历史消息

**修复后**:
- ✅ Agent 模式支持会话历史
- ✅ 所有平台消息正常显示
- ✅ 切换会话自动加载历史
- ✅ 自动保存当前会话
- ✅ 完整的会话生命周期管理

