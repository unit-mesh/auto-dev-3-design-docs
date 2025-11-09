# PTY Handle 优化 - 快速参考

## 问题与解决方案

### 原问题
```kotlin
// ❌ 问题：renderToolCall 时 ptyHandle 为 null，会报错
override fun renderToolCall(toolName: String, paramsStr: String) {
    if (toolType == ToolType.Shell) {
        _timeline.add(TimelineItem.LiveTerminalItem(
            sessionId = sessionId,
            command = command,
            workingDirectory = workingDir,
            ptyHandle = null  // ⚠️ 这里是 null！
        ))
    }
}
```

### 解决方案
```kotlin
// ✅ 解决：根据平台能力，立即启动 PTY（如果支持）
class ComposeRenderer(
    private val shellExecutor: ShellExecutor? = null,  // 平台特定
    private val workingDirectory: String? = null,
    private val coroutineScope: CoroutineScope? = null
) : BaseRenderer() {

    override fun renderToolCall(toolName: String, paramsStr: String) {
        if (toolType == ToolType.Shell) {
            val liveExecutor = shellExecutor as? LiveShellExecutor
            
            // 检查平台能力
            if (liveExecutor != null && liveExecutor.supportsLiveExecution()) {
                // 立即异步启动 PTY
                scope.launch {
                    val session = liveExecutor.startLiveExecution(command, config)
                    updateLiveTerminalPtyHandle(sessionId, session.ptyHandle)
                }
            }
            
            // UI 立即显示（ptyHandle 会异步更新）
            _timeline.add(TimelineItem.LiveTerminalItem(...))
        }
    }
}
```

## 平台差异处理

### JVM (完整 PTY 支持)
```kotlin
// PlatformCodingAgentFactory.jvm.kt
actual fun createPlatformRenderer(...) = ComposeRenderer(
    shellExecutor = PtyShellExecutor(),  // ✅ 支持 PTY
    workingDirectory = workingDirectory,
    coroutineScope = coroutineScope
)

// 行为：
// - supportsLiveExecution() → true
// - PTY 立即异步启动
// - ptyHandle 会被设置为 PtyProcess
// - 实时终端输出
```

### Android/JS (降级到缓冲输出)
```kotlin
// PlatformCodingAgentFactory.android.kt / .js.kt
actual fun createPlatformRenderer(...) = ComposeRenderer(
    shellExecutor = DefaultShellExecutor(),  // ❌ 不支持 PTY
    workingDirectory = workingDirectory,
    coroutineScope = coroutineScope
)

// 行为：
// - supportsLiveExecution() → false
// - 不尝试启动 PTY
// - ptyHandle 保持 null
// - 使用缓冲输出（等命令完成后一次性显示）
```

## 使用方法

### 1. 自动方式（推荐）
```kotlin
// 在 ViewModel 中，自动根据平台创建正确的 renderer
class CodingAgentViewModel(...) {
    val renderer = createPlatformRenderer(
        workingDirectory = projectPath,
        coroutineScope = scope
    )
    // JVM → PtyShellExecutor
    // Android/JS → DefaultShellExecutor
}
```

### 2. 手动方式（测试/自定义）
```kotlin
// 自定义 shell executor
val customRenderer = ComposeRenderer(
    shellExecutor = MyCustomExecutor(),
    workingDirectory = "/custom/path",
    coroutineScope = myScope
)
```

### 3. 向后兼容（无 PTY）
```kotlin
// 不传参数，完全向后兼容
val renderer = ComposeRenderer()
// ptyHandle 会保持 null，使用缓冲输出
```

## 检查平台能力

```kotlin
// 在代码中检查是否支持 PTY
val liveExecutor = shellExecutor as? LiveShellExecutor

if (liveExecutor != null && liveExecutor.supportsLiveExecution()) {
    // ✅ JVM 平台 - 可以使用 PTY
    println("PTY supported")
} else {
    // ❌ Android/JS 平台 - 使用缓冲输出
    println("PTY not supported, falling back to buffered output")
}
```

## 关键 API

### ComposeRenderer 构造函数
```kotlin
ComposeRenderer(
    shellExecutor: ShellExecutor? = null,     // 平台特定的执行器
    workingDirectory: String? = null,          // 默认工作目录
    coroutineScope: CoroutineScope? = null     // 用于异步启动 PTY
)
```

### 平台工厂
```kotlin
// 根据平台自动创建合适的 renderer
expect fun createPlatformRenderer(
    workingDirectory: String?,
    coroutineScope: CoroutineScope?
): ComposeRenderer
```

### PTY Handle 更新
```kotlin
// 异步更新 ptyHandle（只在为 null 时更新）
fun updateLiveTerminalPtyHandle(
    sessionId: String,
    ptyHandle: Any
): Boolean  // true = 更新成功，false = handle 已存在
```

## 错误处理

### PTY 启动失败
```kotlin
scope.launch {
    try {
        val session = liveExecutor.startLiveExecution(command, config)
        updateLiveTerminalPtyHandle(sessionId, session.ptyHandle ?: return@launch)
    } catch (e: Exception) {
        // PTY 创建失败，但不影响整体流程
        // LiveTerminalItem 已创建，ptyHandle 保持 null
        // 自动降级到缓冲输出模式
        println("Failed to start PTY: ${e.message}")
    }
}
```

### 平台不支持 PTY
```kotlin
// 平台检测自动处理
val liveExecutor = shellExecutor as? LiveShellExecutor

if (liveExecutor == null || !liveExecutor.supportsLiveExecution()) {
    // 跳过 PTY 启动，直接创建 LiveTerminalItem
    // ptyHandle 保持 null，使用缓冲模式
}
```

## 测试

### 运行测试
```bash
# 运行 ComposeRenderer 的 shell 测试
./gradlew :mpp-ui:cleanTest :mpp-ui:test --tests "ComposeRendererShellTest"
```

### 测试覆盖
- ✅ 无 shell executor
- ✅ 非 LiveShellExecutor
- ✅ 有 LiveShellExecutor（PTY 启动）
- ✅ PTY handle 更新安全性
- ✅ 工作目录回退

## 调试技巧

### 检查 renderer 配置
```kotlin
val renderer = viewModel.renderer
println("Shell executor: ${renderer.shellExecutor?.javaClass?.simpleName}")
println("Supports live: ${(renderer.shellExecutor as? LiveShellExecutor)?.supportsLiveExecution()}")
```

### 监控 PTY 启动
```kotlin
// 在 ComposeRenderer.renderToolCall 中添加日志
println("🚀 Shell tool detected")
println("✅ LiveShellExecutor: ${liveExecutor != null}")
println("✅ Supports live: ${liveExecutor?.supportsLiveExecution()}")
```

### 检查 ptyHandle 状态
```kotlin
val item = renderer.timeline.last() as TimelineItem.LiveTerminalItem
println("PTY handle: ${item.ptyHandle}")
println("Session ID: ${item.sessionId}")
```

## 最佳实践

1. **使用平台工厂**：总是使用 `createPlatformRenderer()` 而不是直接 `new ComposeRenderer()`
2. **传递 scope**：确保传递 CoroutineScope 以支持异步 PTY 启动
3. **不要假设 PTY**：UI 代码应该同时处理 ptyHandle 为 null 和非 null 的情况
4. **测试所有平台**：确保在 JVM、Android、JS 上都测试过

## 相关文件

- `ComposeRenderer.kt` - 核心渲染器
- `PlatformCodingAgentFactory.kt` - 平台工厂接口
- `PlatformCodingAgentFactory.jvm.kt` - JVM 实现
- `PlatformCodingAgentFactory.android.kt` - Android 实现
- `PlatformCodingAgentFactory.js.kt` - JS 实现
- `ComposeRendererShellTest.kt` - 单元测试
- `LiveShellSession.kt` - PTY 会话数据结构
- `PtyShellExecutor.kt` - JVM PTY 实现
