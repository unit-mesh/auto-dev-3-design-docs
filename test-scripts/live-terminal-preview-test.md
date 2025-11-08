# Live Terminal Preview 测试

## 概述

为 `ComposeRenderer.addLiveTerminal()` 功能添加了 Preview 测试支持。

## 修改内容

### 文件：`mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/agent/test/AgentMessageListPreview.kt`

**新增功能：**

1. **添加 Mock Terminal Process**：创建了 `createMockTerminalProcess()` 函数，模拟一个长期运行的终端进程
   - 模拟 `npm run dev` 命令的输出
   - 提供虚拟的 stdin/stdout/stderr 流
   - 适合在 Preview 中测试 Live Terminal 渲染

2. **在 Timeline 中添加 Live Terminal**：在现有的 mock workflow 中新增了第 6 个迭代
   - 调用 `renderer.addLiveTerminal()` 添加实时终端会话
   - 使用 mock Process 作为 ptyHandle 参数

## 运行 Preview

```bash
./gradlew :mpp-ui:run -PmainClass=cc.unitmesh.devins.ui.compose.agent.test.AgentMessageListPreviewKt
```

## Preview 展示内容

Preview 窗口会展示一个完整的 Agent 工作流，包括：

1. ✅ Agent Reasoning (AI 思考过程)
2. ✅ Tool Calls (读取文件、写入文件、执行 shell 命令)
3. ✅ Tool Results (成功/失败的结果)
4. ✅ Error Handling (测试失败及恢复)
5. ✅ **Live Terminal** (实时终端会话 - 新增)
6. ✅ Final Result (任务完成状态)

## 技术细节

### Mock Process 实现

```kotlin
private fun createMockTerminalProcess(): Process {
    return object : Process() {
        private val mockOutput = """
> dev-server@1.0.0 dev
> vite

  VITE v5.0.0  ready in 423 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
        """.trimIndent()
        
        override fun getInputStream() = 
            java.io.ByteArrayInputStream(mockOutput.toByteArray())
        // ... 其他方法实现
    }
}
```

### Timeline Item

Live Terminal 在 Timeline 中表现为 `TimelineItem.LiveTerminalItem`，包含：
- `sessionId`: 唯一的会话标识
- `command`: 执行的命令（如 "npm run dev"）
- `workingDirectory`: 工作目录
- `ptyHandle`: PTY 进程句柄（在 JVM 上是 `Process` 对象）

## 预期效果

在 Preview 窗口中，你应该能看到：
- 💻 Live Terminal 图标
- 命令显示：`npm run dev`
- 工作目录：`/project/root`
- **实时终端输出**（通过 JediTerm 渲染）

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ComposeRenderer.kt` - `addLiveTerminal()` 实现
- `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/agent/LiveTerminalItem.jvm.kt` - JVM 平台的 Live Terminal 渲染
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentMessageList.kt` - Timeline 渲染逻辑

## 注意事项

- Live Terminal 功能目前仅在 JVM 平台支持（使用 JediTerm）
- Android 和 JS 平台有对应的 stub 实现
- Mock Process 提供静态输出，实际使用中 PTY 会提供实时流式输出
