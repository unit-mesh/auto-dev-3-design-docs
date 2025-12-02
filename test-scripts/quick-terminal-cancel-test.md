# 快速测试 Terminal Cancel 功能

## 当前状态

✅ **代码已修改并编译成功**
- mpp-core 模块已编译
- mpp-idea 模块已编译
- IDEA 插件正在启动中...

## 测试步骤（简化版）

### 1. 等待 IDEA 插件启动完成

当前正在运行：`cd mpp-idea && ../gradlew runIde`

等待看到新的 IntelliJ IDEA 窗口打开。

### 2. 在新打开的 IDEA 中

1. **打开测试项目**
   - File → Open
   - 选择：`/Users/phodal/IdeaProjects/untitled`

2. **打开 AutoDev Tool Window**
   - 点击右侧工具栏的 "AutoDev" 图标
   - 或者使用快捷键

3. **执行测试命令**

   在 AutoDev 聊天框中输入：
   ```
   请运行 Spring Boot 项目
   ```
   
   或者直接使用命令：
   ```
   /run ./gradlew bootRun
   ```

4. **观察输出**

   等待看到 Spring Boot 启动日志：
   ```
     .   ____          _            __ _ _
    /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
   ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
    \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
     '  |____| .__|_| |_|_| |_\__, | / / / /
    =========|_|==============|___/=/_/_/_/
   ```

5. **点击 Cancel 按钮**

   在终端输出区域找到并点击 Cancel 按钮

6. **验证 AI 的响应**

   ✅ **应该看到**：
   ```
   ⚠️ Command cancelled by user
   
   Command: ./gradlew bootRun
   Output before cancellation:
   [Spring Boot 启动日志...]
   ```

   ❌ **不应该看到**：
   ```
   Command failed with exit code: 137
   [没有输出日志]
   ```

## 预期改进

### 修复前的问题
1. AI 只看到：`Command failed with exit code: 137`
2. AI 看不到取消前的输出
3. AI 不知道是用户主动取消的

### 修复后的效果
1. ✅ AI 收到明确的"用户取消"消息
2. ✅ AI 收到取消前的完整输出日志
3. ✅ 元数据包含 `cancelled: true` 和 `exit_code: 137`
4. ✅ 没有重复的错误消息

## 关键代码改动

### 1. ShellSessionManager.kt
```kotlin
// 添加用户取消标记
private var _cancelledByUser: Boolean = false
val cancelledByUser: Boolean get() = _cancelledByUser

fun markCancelledByUser() {
    _cancelledByUser = true
}
```

### 2. IdeaAgentViewModel.kt
```kotlin
fun handleProcessCancel(cancelEvent: CancelEvent) {
    // 1. 先标记会话为用户取消
    GlobalScope.launch {
        val session = ShellSessionManager.getSession(cancelEvent.sessionId)
        session?.markCancelledByUser()
    }
    
    // 2. 终止进程
    cancelEvent.process.destroyForcibly()
    
    // 3. 渲染取消消息（包含输出日志）
    renderer.renderToolResult(
        toolName = "shell",
        success = false,
        output = cancelMessage,
        fullOutput = cancelEvent.output,  // ← 关键：发送输出日志
        metadata = mapOf(
            "exit_code" to "137",
            "cancelled" to "true"  // ← 关键：标记为用户取消
        )
    )
}
```

### 3. ToolOrchestrator.kt
```kotlin
private fun startSessionMonitoring(...) {
    backgroundScope.launch {
        try {
            val exitCode = shellExecutor.waitForSession(session, timeoutMs)
            val managedSession = ShellSessionManager.getSession(session.sessionId)
            
            // 检查是否为用户取消
            if (managedSession?.cancelledByUser == true) {
                // 跳过渲染更新，避免重复消息
                return@launch
            }
            
            // 正常完成才更新渲染器
            renderer.updateLiveTerminalStatus(...)
        }
    }
}
```

## 调试日志

如果需要查看详细日志：

```bash
tail -f ~/.autodev/logs/autodev-app.log
```

查找关键字：
- `Session was cancelled by user`
- `markCancelledByUser`
- `handleProcessCancel`

## 备选测试命令

如果 Spring Boot 项目不可用，可以测试其他命令：

```bash
# 简单的 sleep 命令
/run sleep 30

# Gradle build
/run ./gradlew build

# 任何长时间运行的命令
/run find / -name "*.java" 2>/dev/null
```

## 成功标准

- [ ] 进程被正确终止
- [ ] AI 收到"用户取消"消息
- [ ] AI 收到取消前的输出日志
- [ ] 没有重复的错误消息
- [ ] 用户体验流畅

