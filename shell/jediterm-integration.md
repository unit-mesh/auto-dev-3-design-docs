# JediTerm Integration for Live Shell Output

## Overview

This document describes the integration of JediTerm for live shell output display in the JVM environment. This feature allows real-time terminal output viewing when executing shell commands through the Agent.

## Architecture

### Components

1. **LiveShellSession** (`mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/shell/LiveShellSession.kt`)
   - Common data class representing a live shell session
   - Contains `sessionId`, `command`, `workingDirectory`, and platform-specific `ptyHandle`
   - Tracks completion status via StateFlow

2. **LiveShellExecutor** Interface (`mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/shell/LiveShellSession.kt`)
   - Interface for shell executors that support live streaming
   - `supportsLiveExecution()`: Check if live execution is supported
   - `startLiveExecution()`: Start a command with live output

3. **PtyShellExecutor** (`mpp-core/src/jvmMain/kotlin/cc/unitmesh/agent/tool/shell/PtyShellExecutor.kt`)
   - JVM implementation using Pty4J
   - Implements `LiveShellExecutor` interface
   - Creates PTY processes that can be connected to JediTerm

4. **ProcessTtyConnector** (`mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/terminal/TerminalWidget.kt`)
   - Bridges Pty4J Process to JediTerm TtyConnector
   - Handles I/O between the PTY process and JediTerm widget

5. **LiveTerminalItem** Timeline Component
   - `ComposeRenderer.TimelineItem.LiveTerminalItem`: Timeline item for live terminals
   - Platform-specific implementations:
     - JVM: Renders JediTerm widget connected to PTY
     - JS/Android: Shows "not supported" message

## Usage

### 1. Using Live Execution in Code

```kotlin
// In your agent or tool invocation code
val shellExecutor = DefaultShellExecutor() // Will use PtyShellExecutor on JVM if available

if (shellExecutor is LiveShellExecutor && shellExecutor.supportsLiveExecution()) {
    // Start live execution
    val session = shellExecutor.startLiveExecution(
        command = "npm run build",
        config = ShellExecutionConfig(
            workingDirectory = "/path/to/project",
            timeoutMs = 300000
        )
    )
    
    // Add to renderer timeline
    renderer.addLiveTerminal(
        sessionId = session.sessionId,
        command = session.command,
        workingDirectory = session.workingDirectory,
        ptyHandle = session.ptyHandle
    )
} else {
    // Fallback to normal execution
    val result = shellExecutor.execute(command, config)
    // Handle result normally...
}
```

### 2. Rendering in Compose UI

The `LiveTerminalItem` is automatically rendered when added to the timeline:

```kotlin
@Composable
fun MyAgentUI(renderer: ComposeRenderer) {
    AgentMessageList(
        renderer = renderer,
        onOpenFileViewer = { path -> /* handle file viewer */ }
    )
}
```

## Platform Support

| Platform | Live Terminal | Fallback |
|----------|--------------|----------|
| JVM (Desktop) | ✅ JediTerm with PTY | Text output |
| JS (Web) | ❌ | Text output |
| Android | ❌ | Text output |

## Technical Details

### PTY Process Lifecycle

1. **Creation**: `PtyShellExecutor.startLiveExecution()` creates a PTY process
2. **Connection**: `ProcessTtyConnector` connects the process to JediTerm
3. **Rendering**: JediTerm widget displays real-time output
4. **Completion**: Process exit is monitored, status updates via StateFlow
5. **Cleanup**: DisposableEffect ensures proper cleanup when component unmounts

### Thread Safety

- PTY I/O operations run on `Dispatchers.IO`
- Compose state updates are thread-safe via `mutableStateOf` and `StateFlow`
- Process monitoring runs in background coroutine

## Limitations

1. **JVM Only**: Live terminal is only available on JVM with PTY support
2. **Read-Only**: Current implementation doesn't support interactive input
3. **No Resize**: Terminal resize is not yet implemented
4. **Fixed Size**: Terminal widget has a fixed size (800x400, can be adjusted)

## Future Enhancements

1. **Interactive Mode**: Support user input to terminal
2. **Terminal Resize**: Implement proper terminal resizing
3. **ANSI Color Support**: Ensure proper ANSI escape sequence handling
4. **Tab Support**: Multiple terminal tabs for concurrent commands
5. **Output Recording**: Save terminal session for replay/debugging

## Example: Full Integration

```kotlin
class MyAgent(
    private val renderer: ComposeRenderer
) {
    
    suspend fun runBuildCommand() {
        val shellExecutor = DefaultShellExecutor()
        
        if (shellExecutor is LiveShellExecutor && shellExecutor.supportsLiveExecution()) {
            // Use live terminal for long-running build
            val session = shellExecutor.startLiveExecution(
                command = "./gradlew build",
                config = ShellExecutionConfig(
                    workingDirectory = "/project",
                    timeoutMs = 600000
                )
            )
            
            renderer.addLiveTerminal(
                sessionId = session.sessionId,
                command = session.command,
                workingDirectory = session.workingDirectory,
                ptyHandle = session.ptyHandle
            )
            
            // Monitor completion
            session.exitCode.collect { exitCode ->
                if (exitCode != null) {
                    println("Build completed with exit code: $exitCode")
                }
            }
        } else {
            // Fallback to normal execution
            val result = shellExecutor.execute("./gradlew build", config)
            println("Build output: ${result.stdout}")
        }
    }
}
```

## Testing

To test the live terminal integration:

1. Build the project:
   ```bash
   cd /Volumes/source/ai/autocrud
   ./gradlew :mpp-core:build
   ./gradlew :mpp-ui:build
   ```

2. Run the agent with a long-running command to see live output

3. Verify on different platforms (JVM vs JS)

## Troubleshooting

### Terminal Not Showing Output

- Check that PTY is available: `PtyShellExecutor.isAvailable()`
- Verify TERM environment variable is set: `TERM=xterm-256color`
- Check process is alive: `process.isAlive`

### Process Hangs

- Ensure proper timeout configuration in `ShellExecutionConfig`
- Check for interactive prompts that block execution
- Verify working directory exists and is accessible

### Memory Leaks

- Ensure `DisposableEffect` properly cleans up terminal widgets
- Check that PTY processes are terminated on completion
- Verify TtyConnector.close() is called

## References

- [JediTerm Documentation](https://github.com/JetBrains/jediterm)
- [Pty4J Documentation](https://github.com/JetBrains/pty4j)
- [Compose for Desktop](https://www.jetbrains.com/lp/compose-desktop/)

