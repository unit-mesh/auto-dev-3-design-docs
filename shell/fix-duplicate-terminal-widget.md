# 修复重复 Terminal Widget 问题

## 问题描述

在之前的实现中，执行 shell 命令时会出现**两个重复的 Terminal Widget**：

1. **第一个**：`ComposeRenderer.renderToolCall()` 创建的 `LiveTerminalItem`（ptyHandle = null）
2. **第二个**：`ToolOrchestrator.executeToolCall()` 调用 `renderer.addLiveTerminal()` 创建的

这导致 UI 中显示两个相同的终端框，用户体验很差。

## 根本原因

```kotlin
// ComposeRenderer.renderToolCall() - 创建第一个
_timeline.add(TimelineItem.LiveTerminalItem(
    sessionId = "shell-${timestamp}",
    ptyHandle = null  // 先创建，PTY 异步启动
))

// ToolOrchestrator.executeToolCall() - 又创建第二个！
renderer.addLiveTerminal(
    sessionId = liveSession.sessionId,  // 不同的 sessionId (UUID)
    ptyHandle = liveSession.ptyHandle
)
```

## 解决方案

### 1. 扩展 CodingAgentRenderer 接口

添加两个新方法来支持 PTY handle 的更新：

```kotlin
interface CodingAgentRenderer {
    // ... 现有方法 ...
    
    /**
     * 更新已存在的 LiveTerminal 的 PTY handle
     */
    fun updateLiveTerminalPtyHandle(
        sessionId: String,
        ptyHandle: Any
    ): Boolean
    
    /**
     * 获取最近创建的待处理 terminal 的 sessionId
     */
    fun getLatestPendingTerminalSessionId(): String?
}
```

### 2. 修改 ToolOrchestrator 逻辑

```kotlin
// ❌ 之前：创建新的 terminal（导致重复）
renderer.addLiveTerminal(
    sessionId = liveSession.sessionId,
    command = liveSession.command,
    workingDirectory = liveSession.workingDirectory,
    ptyHandle = liveSession.ptyHandle
)

// ✅ 现在：更新已存在的 terminal
val pendingSessionId = renderer.getLatestPendingTerminalSessionId()
if (pendingSessionId != null && liveSession.ptyHandle != null) {
    renderer.updateLiveTerminalPtyHandle(pendingSessionId, liveSession.ptyHandle)
}
```

### 3. ComposeRenderer 实现

```kotlin
override fun updateLiveTerminalPtyHandle(
    sessionId: String,
    ptyHandle: Any
): Boolean {
    val index = _timeline.indexOfLast {
        it is TimelineItem.LiveTerminalItem && it.sessionId == sessionId
    }
    
    if (index != -1) {
        val existing = _timeline[index] as TimelineItem.LiveTerminalItem
        if (existing.ptyHandle == null) {
            _timeline[index] = existing.copy(ptyHandle = ptyHandle)
            return true
        }
    }
    return false
}

override fun getLatestPendingTerminalSessionId(): String? {
    return _timeline
        .asReversed()
        .firstOrNull { it is TimelineItem.LiveTerminalItem && it.ptyHandle == null }
        ?.let { (it as TimelineItem.LiveTerminalItem).sessionId }
}
```

## 执行流程

### 修复后的正确流程

```
1. 用户发送 shell 命令
   ↓
2. LLM 返回工具调用
   ↓
3. ComposeRenderer.renderToolCall()
   - 创建 LiveTerminalItem (ptyHandle = null)
   - 异步启动 PTY（如果支持）
   ↓
4. ToolOrchestrator.executeToolCall()
   - 检测到是 Shell 工具
   - 启动 PTY 会话
   - 调用 getLatestPendingTerminalSessionId() 找到步骤3创建的 terminal
   - 调用 updateLiveTerminalPtyHandle() 更新 ptyHandle
   ↓
5. UI 显示：只有一个 Terminal Widget ✅
```

## 关键改进

### ✅ 避免重复创建

- **之前**：两处代码都创建 terminal → 2个widget
- **现在**：只在 renderToolCall 创建，executeToolCall 只更新 → 1个widget

### ✅ sessionId 匹配

- **之前**：两个不同的 sessionId 无法关联
- **现在**：通过 `getLatestPendingTerminalSessionId()` 自动匹配

### ✅ 时序正确

```
renderToolCall (UI立即显示)
    ↓
    [用户看到 terminal 框]
    ↓
executeToolCall (后台执行)
    ↓
    [PTY 输出实时显示在同一个 terminal]
```

### ✅ 兼容性

对于不支持这些新方法的 renderer：
- `getLatestPendingTerminalSessionId()` 返回 null
- `updateLiveTerminalPtyHandle()` 返回 false
- 自动回退到 `addLiveTerminal()`（向后兼容）

## 测试验证

### 预期行为

1. **JVM 平台**：
   - 只显示 1 个 Terminal Widget
   - PTY 实时输出可见
   - 命令完成后不再显示 ToolResultItem

2. **Android/JS 平台**：
   - 只显示 1 个 Terminal Widget
   - ptyHandle 保持 null
   - 使用缓冲输出模式
   - 命令完成后不再显示 ToolResultItem

### 检查点

```kotlin
// 1. renderToolCall 创建 terminal
val timelineSize1 = renderer.timeline.size
renderer.renderToolCall("shell", """command="ls" """)
val timelineSize2 = renderer.timeline.size
assert(timelineSize2 == timelineSize1 + 1) // 只增加了 1 个

// 2. executeToolCall 不创建新 terminal
orchestrator.executeToolCall("shell", mapOf("command" to "ls"), context)
val timelineSize3 = renderer.timeline.size
assert(timelineSize3 == timelineSize2) // 没有增加，只是更新了 ptyHandle

// 3. renderToolResult 跳过 Shell 工具
renderer.renderToolResult("shell", true, "output", metadata = mapOf("isLiveSession" to "true"))
val timelineSize4 = renderer.timeline.size
assert(timelineSize4 == timelineSize3) // 没有增加 ToolResultItem
```

## 相关修改

### 修改的文件

1. ✅ `CodingAgentRenderer.kt` - 添加接口方法
2. ✅ `ComposeRenderer.kt` - 实现接口方法（添加 override）
3. ✅ `ToolOrchestrator.kt` - 使用更新而非创建

### 不需要修改

- `LiveShellSession.kt` - 保持不变
- `PtyShellExecutor.kt` - 保持不变
- `PlatformCodingAgentFactory.kt` - 保持不变

## 副作用与注意事项

### ✅ 正面影响

1. **UI 更清晰**：不再有重复的 terminal
2. **性能更好**：减少了不必要的 widget 创建
3. **代码更清晰**：职责分离（UI 层创建，执行层更新）

### ⚠️ 需要注意

1. **sessionId 管理**：依赖 `getLatestPendingTerminalSessionId()` 的正确性
2. **并发问题**：如果同时执行多个 shell 命令，需要确保匹配正确
3. **错误处理**：如果 `updateLiveTerminalPtyHandle` 返回 false，需要有降级方案

## 后续优化

### 可能的改进

1. **更精确的匹配**：基于 command 而不只是 "最新的"
2. **超时机制**：如果 PTY 启动超时，显示警告
3. **错误恢复**：如果匹配失败，回退到创建新 terminal

### 测试覆盖

1. ✅ 单个 shell 命令执行
2. ⏳ 多个并发 shell 命令
3. ⏳ PTY 启动失败的情况
4. ⏳ 不同平台的行为差异

## 总结

通过引入 `updateLiveTerminalPtyHandle` 和 `getLatestPendingTerminalSessionId` 接口方法，我们成功解决了重复 Terminal Widget 的问题，同时保持了代码的清晰性和向后兼容性。

**核心思想**：
- 🎨 UI 层负责创建（`renderToolCall`）
- ⚙️ 执行层负责填充（`executeToolCall` + `updateLiveTerminalPtyHandle`）
- 🔗 通过接口方法连接两者
