# Live Terminal PTY Handle 优化

## 问题描述

之前的实现中，`LiveTerminalItem` 在 `renderToolCall` 阶段创建时 `ptyHandle` 为 `null`，真正的 PTY 进程在 `ToolOrchestrator.executeToolCall` 中才创建。这导致两个问题：

1. **用户体验延迟**：用户在 UI 中看到终端框，但需要等待 agent 处理完其他逻辑后才开始执行 shell 命令
2. **平台兼容性问题**：在不支持 PTY 的平台（Android、JS）上，`ptyHandle` 为 `null` 会导致错误

## 解决方案

### 1. ComposeRenderer 增强

给 `ComposeRenderer` 添加了可选的 `shellExecutor` 参数，让它能在 `renderToolCall` 时就检查平台能力并立即启动 PTY：

```kotlin
class ComposeRenderer(
    private val shellExecutor: ShellExecutor? = null,
    private val workingDirectory: String? = null,
    private val coroutineScope: CoroutineScope? = null
) : BaseRenderer()
```

### 2. 立即启动 PTY

在 `renderToolCall` 方法中，如果检测到：
- 工具类型是 Shell
- shellExecutor 是 LiveShellExecutor
- 平台支持 live execution

则立即异步启动 PTY 进程：

```kotlin
if (liveExecutor != null && liveExecutor.supportsLiveExecution()) {
    scope.launch {
        val session = liveExecutor.startLiveExecution(command, shellConfig)
        updateLiveTerminalPtyHandle(sessionId, session.ptyHandle ?: return@launch)
    }
}
```

### 3. 平台特定工厂

创建了平台特定的 renderer 工厂方法：

```kotlin
expect fun createPlatformRenderer(
    workingDirectory: String?,
    coroutineScope: CoroutineScope?
): ComposeRenderer
```

各平台实现：

- **JVM**: 使用 `PtyShellExecutor`，支持完整的 PTY 功能
- **Android**: 使用 `DefaultShellExecutor`，仅支持缓冲输出
- **JS**: 使用 `DefaultShellExecutor`，仅支持缓冲输出

### 4. 安全的 PTY Handle 更新

增强了 `updateLiveTerminalPtyHandle` 方法：

```kotlin
fun updateLiveTerminalPtyHandle(sessionId: String, ptyHandle: Any): Boolean {
    // 只在 handle 为 null 时更新，避免覆盖
    if (existing.ptyHandle == null) {
        _timeline[index] = existing.copy(ptyHandle = ptyHandle)
        return true
    }
    return false
}
```

## 架构优势

### KMP 跨平台兼容

- ✅ **JVM**: 完整 PTY 支持，实时终端交互
- ✅ **Android**: 降级到缓冲输出，避免 PTY 相关错误
- ✅ **JS**: 降级到缓冲输出，使用 Node.js child_process

### 用户体验优化

1. **零延迟启动**：Shell 命令在 UI 渲染的同时就开始执行
2. **渐进式增强**：PTY 进程异步启动，UI 立即显示
3. **优雅降级**：不支持 PTY 的平台自动回退到缓冲模式

### 代码结构清晰

```
ComposeRenderer (UI Layer)
    ↓ 使用
LiveShellExecutor (接口)
    ↓ 平台实现
├── PtyShellExecutor (JVM - 完整 PTY)
├── DefaultShellExecutor.jvm (JVM - 兼容模式)
├── DefaultShellExecutor.js (JS - Node.js)
└── DefaultShellExecutor (Android - 降级)
```

## 使用示例

### 创建 ViewModel

```kotlin
val viewModel = CodingAgentViewModel(
    llmService = llmService,
    projectPath = "/path/to/project",
    maxIterations = 100
)

// renderer 会根据平台自动配置正确的 shell executor
val renderer = viewModel.renderer
```

### 平台检测

```kotlin
// 在 JVM 上
val renderer = createPlatformRenderer(projectPath, scope)
// → ComposeRenderer(PtyShellExecutor) - 支持 PTY

// 在 Android 上
val renderer = createPlatformRenderer(projectPath, scope)
// → ComposeRenderer(DefaultShellExecutor) - 仅缓冲输出
```

## 测试要点

1. **JVM 平台**：验证 PTY 进程能立即启动
2. **Android 平台**：验证不会尝试创建 PTY，使用缓冲输出
3. **JS 平台**：验证 Node.js child_process 正确工作
4. **错误处理**：验证 PTY 创建失败时能优雅降级

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ComposeRenderer.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/PlatformCodingAgentFactory.kt`
- `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/agent/PlatformCodingAgentFactory.jvm.kt`
- `mpp-ui/src/androidMain/kotlin/cc/unitmesh/devins/ui/compose/agent/PlatformCodingAgentFactory.android.kt`
- `mpp-ui/src/jsMain/kotlin/cc/unitmesh/devins/ui/compose/agent/PlatformCodingAgentFactory.js.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/shell/LiveShellSession.kt`
- `mpp-core/src/jvmMain/kotlin/cc/unitmesh/agent/tool/shell/PtyShellExecutor.kt`

## 后续改进

1. **流式输出**：在 PTY 不可用时，考虑使用轮询或 WebSocket 提供实时反馈
2. **进度指示**：在 PTY 启动期间显示加载指示器
3. **错误恢复**：PTY 失败时自动切换到缓冲模式
4. **性能监控**：记录 PTY 启动时间，优化用户体验
