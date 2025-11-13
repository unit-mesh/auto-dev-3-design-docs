# Test: SessionSidebar 新建会话显示

## 问题描述
当用户点击"New Chat"按钮创建新会话时，新建的空会话没有出现在 SessionSidebar 的列表中。

## 根本原因
`ChatHistoryManager.getAllSessions()` 过滤掉了空会话（没有消息的会话），导致新创建的会话无法在侧边栏显示。

## 解决方案
修改 `getAllSessions()` 方法，返回所有会话（包括空会话），让用户可以看到新建的会话并开始对话。

### 修改内容
**文件**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/llm/ChatHistoryManager.kt`

**Before**:
```kotlin
fun getAllSessions(): List<ChatSession> {
    return sessions.values
        .filter { it.messages.isNotEmpty() }  // 只返回有消息的会话
        .sortedByDescending { it.updatedAt }
}
```

**After**:
```kotlin
fun getAllSessions(): List<ChatSession> {
    return sessions.values
        .sortedByDescending { it.updatedAt }
}
```

### 注意事项
- 空会话仍然不会被保存到磁盘（通过 `saveSessionsAsync()` 中的过滤保证）
- SessionSidebar 中的 `LocalSessionItem` 已经处理了空会话的显示（标题显示为 "New Chat"）
- 这样用户可以看到新建的会话并立即开始对话

## 测试步骤
1. 启动应用
2. 点击 SessionSidebar 中的 "+" 按钮创建新会话
3. 验证：新会话应该立即出现在列表中，标题显示为 "New Chat"
4. 在新会话中发送第一条消息
5. 验证：会话标题更新为消息的摘要，并且会话被保存到磁盘

## 预期结果
✅ 新建的空会话立即显示在 SessionSidebar 列表中
✅ 用户可以点击新会话并开始对话
✅ 空会话不会污染磁盘存储
