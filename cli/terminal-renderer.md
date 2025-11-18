# ANSI Terminal Renderer

A cross-platform terminal renderer for Kotlin Multiplatform that properly handles ANSI escape sequences, including colors, text styles, and cursor movements.

## Overview

The Terminal Renderer is designed to replace JediTermWidget with a pure Compose implementation that works across JVM, Android, and potentially JS/WASM platforms. It correctly parses and renders ANSI escape sequences commonly found in terminal output.

## Features

- ✅ **ANSI Color Support**: 16 standard colors + bright variants
- ✅ **256 Color Mode**: Extended color palette (38;5;n and 48;5;n)
- ✅ **Text Styles**: Bold, italic, underline, dim, inverse video
- ✅ **Cursor Movement**: Up, down, forward, back, position
- ✅ **Screen Manipulation**: Clear screen, clear line, erase display
- ✅ **Cursor Save/Restore**: Save and restore cursor position
- ✅ **Real-time Streaming**: Support for live terminal output
- ✅ **Compose Integration**: Pure Compose UI, works on all platforms

## Architecture

### Components

1. **AnsiParser** (`AnsiParser.kt`)
   - Parses ANSI escape sequences
   - Handles CSI (Control Sequence Introducer) commands
   - Supports SGR (Select Graphic Rendition) for colors and styles

2. **TerminalState** (`TerminalState.kt`)
   - Maintains screen buffer as a 2D grid of cells
   - Tracks cursor position and current text style
   - Handles line wrapping and scrollback buffer

3. **TerminalRenderer** (`TerminalRenderer.kt`)
   - Renders terminal state as Compose UI
   - Supports both static and live rendering
   - Auto-scrolls to show latest output

4. **PtyTerminalIntegration** (`PtyTerminalIntegration.kt`, JVM only)
   - Integrates with PtyShellExecutor
   - Provides UI for executing shell commands
   - Displays output with proper ANSI formatting

## Usage

### Basic Usage - Static Output

```kotlin
@Composable
fun MyTerminal() {
    val ansiText = """
        ${'\u001B'}[32mSuccess!${'\u001B'}[0m Build completed
        ${'\u001B'}[31mError:${'\u001B'}[0m Test failed
    """.trimIndent()
    
    AnsiTerminalRenderer(
        ansiText = ansiText,
        maxHeight = 400
    )
}
```

### Live Terminal - Streaming Output

```kotlin
@Composable
fun LiveTerminal() {
    LiveTerminalRenderer(
        maxHeight = 600,
        showCursor = true
    ) { appendText, clear ->
        // Use these callbacks to update terminal
        appendText("$ ls -la\n")
        appendText("total 48\n")
        // ... more output
    }
}
```

### Integration with PtyShellExecutor

```kotlin
@Composable
fun ShellExecutor() {
    PtyTerminalIntegration(
        initialCommand = "./gradlew build",
        workingDirectory = File("/path/to/project")
    )
}
```

### Manual Control

```kotlin
@Composable
fun ManualTerminal() {
    val terminalState = remember { TerminalState() }
    val parser = remember { AnsiParser() }
    
    // Parse some ANSI text
    LaunchedEffect(Unit) {
        parser.parse("Hello, \u001B[32mWorld\u001B[0m!\n", terminalState)
    }
    
    TerminalRenderer(
        terminalState = terminalState,
        showCursor = false
    )
}
```

## ANSI Escape Sequences Supported

### Colors

| Code | Color | Code | Bright Color |
|------|-------|------|--------------|
| 30 | Black | 90 | Bright Black (Gray) |
| 31 | Red | 91 | Bright Red |
| 32 | Green | 92 | Bright Green |
| 33 | Yellow | 93 | Bright Yellow |
| 34 | Blue | 94 | Bright Blue |
| 35 | Magenta | 95 | Bright Magenta |
| 36 | Cyan | 96 | Bright Cyan |
| 37 | White | 97 | Bright White |

Background colors: Add 10 to foreground codes (40-47, 100-107)

### Text Styles

| Code | Style |
|------|-------|
| 0 | Reset all |
| 1 | Bold |
| 2 | Dim |
| 3 | Italic |
| 4 | Underline |
| 7 | Inverse video |
| 22 | Normal intensity |
| 23 | Not italic |
| 24 | Not underlined |
| 27 | Not inverse |

### Cursor Movement

| Sequence | Action |
|----------|--------|
| ESC[nA | Cursor up n lines |
| ESC[nB | Cursor down n lines |
| ESC[nC | Cursor forward n columns |
| ESC[nD | Cursor back n columns |
| ESC[n;mH | Cursor position (row n, col m) |
| ESC[s | Save cursor position |
| ESC[u | Restore cursor position |

### Screen Manipulation

| Sequence | Action |
|----------|--------|
| ESC[0J | Clear from cursor to end of screen |
| ESC[1J | Clear from cursor to beginning of screen |
| ESC[2J | Clear entire screen |
| ESC[0K | Clear from cursor to end of line |
| ESC[1K | Clear from cursor to beginning of line |
| ESC[2K | Clear entire line |

## Examples

### Gradle Build Output

The renderer correctly handles complex Gradle output with progress bars, colors, and cursor movements:

```kotlin
@Preview
@Composable
fun GradleBuildExample() {
    val gradleOutput = """
        [2A[1B[1m> Starting Daemon[m[17D
        [1m<[0;32;1m=============[0;39;1m> 100% CONFIGURING [3s][m
        [31;1m> Task :test[0;39m[31m FAILED[39m
        DemoApplicationTests > contextLoads() [31mFAILED[39m
    """.trimIndent()
    
    AnsiTerminalRenderer(ansiText = gradleOutput)
}
```

### Colored Log Output

```kotlin
val logs = """
    ${'\u001B'}[1;32m✓${'\u001B'}[0m Build successful
    ${'\u001B'}[1;33m⚠${'\u001B'}[0m Warning: Deprecated API
    ${'\u001B'}[1;31m✗${'\u001B'}[0m Error: Test failed
""".trimIndent()

AnsiTerminalRenderer(ansiText = logs)
```

## Testing

Run the test script to verify functionality:

```bash
kotlin docs/test-scripts/terminal-renderer-test.kt
```

Or use the Compose previews:

```kotlin
// In Android Studio or IntelliJ IDEA
// Open TerminalPreview.kt and view the @Preview functions
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| JVM Desktop | ✅ Full support | Includes PtyShellExecutor integration |
| Android | ✅ Full support | Pure Compose, no JediTerm dependency |
| JS/WASM | 🚧 Planned | Core renderer works, needs platform-specific shell executor |

## Performance Considerations

- **Scrollback Buffer**: Default max 1000 lines, configurable via `TerminalState(maxLines = ...)`
- **Auto-scroll**: Automatically scrolls to bottom when new content is added
- **Lazy Rendering**: Only visible lines are rendered
- **State Management**: Uses Compose's snapshot state for efficient updates

## Comparison with JediTermWidget

| Feature | JediTermWidget | ANSI Terminal Renderer |
|---------|----------------|------------------------|
| Platform | JVM only | KMP (JVM, Android, JS/WASM) |
| UI Framework | Swing | Compose Multiplatform |
| ANSI Support | Full | Core features (expandable) |
| Customization | Limited | Full Compose theming |
| Modern Look | ❌ | ✅ Material Design |
| Android Support | ❌ | ✅ |

## Future Enhancements

- [ ] RGB color support (ESC[38;2;r;g;b)
- [ ] Scrolling regions
- [ ] Alternate screen buffer
- [ ] Mouse tracking
- [ ] Hyperlinks (OSC 8)
- [ ] Sixel graphics
- [ ] Blinking cursor animation
- [ ] Selection and copy support

## Contributing

When adding new ANSI sequences:

1. Add parsing logic to `AnsiParser.kt`
2. Update state management in `TerminalState.kt` if needed
3. Add rendering logic to `TerminalRenderer.kt` if needed
4. Add test cases to `TerminalPreview.kt`
5. Update this documentation

## References

- [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
- [Terminal Guide](https://terminalguide.namepad.de/)

