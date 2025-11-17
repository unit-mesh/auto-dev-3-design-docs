# FileViewerPanel Refactoring: RSyntaxTextArea → Monaco Editor + WebView

## Summary

This document describes the refactoring of `FileViewerPanel` from using RSyntaxTextArea to an offline Monaco Editor + WebView solution.

## Architecture

### Module Structure

```
mpp-viewer/                    # Core viewer API
├── ViewerType.kt             # Enum of supported content types (CODE, MARKDOWN, IMAGE, etc.)
├── ViewerRequest.kt          # Data class for content display requests
├── ViewerHost.kt             # Interface for viewer implementations
└── LanguageDetector.kt       # Utility for detecting programming languages

mpp-viewer-web/               # WebView-based implementation
├── WebViewerHost.kt          # WebView implementation of ViewerHost
├── ViewerWebView.kt          # Composable WebView component
└── resources/
    └── viewer.html           # Monaco Editor integration HTML
```

### Design Principles

1. **Separation of Concerns**: 
   - `mpp-viewer`: Platform-agnostic API
   - `mpp-viewer-web`: WebView-specific implementation

2. **Platform Support**:
   - JVM: Full WebView + Monaco Editor support
   - Android: WebView support (needs testing)
   - iOS: Placeholder implementation
   - JS/WASM: Placeholder implementation

3. **Dependency Management**:
   - `mpp-viewer`: Minimal dependencies (only kotlinx-serialization)
   - `mpp-viewer-web`: Depends on compose-webview-multiplatform
   - `mpp-ui`: Only JVM platform depends on `mpp-viewer-web`

## Implementation Status

### Completed

- ✅ Created `mpp-viewer` module with core API
- ✅ Created `mpp-viewer-web` module with WebView implementation
- ✅ Implemented `ViewerType`, `ViewerRequest`, `ViewerHost` interfaces
- ✅ Created `LanguageDetector` utility with 30+ languages support
- ✅ Implemented `WebViewerHost` for WebView communication
- ✅ Created `viewer.html` with Monaco Editor integration (CDN-based)
- ✅ Refactored `FileViewerPanel` on JVM to use WebView
- ✅ Updated all platform-specific implementations of `FileViewerPanelWrapper`
- ✅ Added modules to `settings.gradle.kts`
- ✅ Excluded new modules from root project's Kotlin plugin auto-application
- ✅ Updated package lock files

### Known Issues

1. **compose-webview-multiplatform Dependency Resolution**:
   - Missing dependency: `org.jogamp.gluegen:gluegen-rt:2.5.0`
   - Missing dependency: `org.jogamp.jogl:jogl-all:2.5.0`
   - **Solution**: Add JOGL repository to `mpp-viewer-web/build.gradle.kts`
   
   ```kotlin
   repositories {
       maven("https://jogamp.org/deployment/maven")
   }
   ```

2. **Build Configuration**:
   - Configuration cache compatibility issues with WebView dependencies
   - **Workaround**: Use `--no-configuration-cache` for builds involving mpp-viewer-web

## Next Steps

### 1. Fix Dependency Resolution

Add the JOGL Maven repository to resolve missing dependencies:

```bash
cd mpp-viewer-web
# Edit build.gradle.kts to add maven("https://jogamp.org/deployment/maven")
```

### 2. Offline Monaco Editor Setup

For offline usage, download Monaco Editor locally:

```bash
cd mpp-viewer-web
chmod +x scripts/download-monaco.sh
./scripts/download-monaco.sh
```

Then update `viewer.html` to use local paths instead of CDN.

### 3. Platform-Specific Testing

- **JVM/Desktop**: Test FileViewerPanel with WebView
- **Android**: Test on actual Android device
- **iOS**: Implement native WebView integration
- **JS/WASM**: Consider alternative Monaco Editor integration

### 4. Feature Enhancements

- Implement markdown rendering in viewer.html
- Add image viewer support
- Add PDF viewer support
- Implement theme switching (light/dark mode)
- Add line number navigation
- Implement search/replace functionality

## Usage Example

```kotlin
// Create a viewer request
val request = ViewerRequest(
    type = ViewerType.CODE,
    content = fileContent,
    language = LanguageDetector.detectLanguage(filePath),
    fileName = fileName,
    filePath = filePath,
    readOnly = true,
    lineNumber = 42  // Optional: scroll to specific line
)

// Display in WebView
val webViewState = rememberWebViewState(url = "")
val viewerHost = remember { WebViewerHost(webViewState) }

ViewerWebView(
    viewerHost = viewerHost,
    onReady = {
        scope.launch {
            viewerHost.showContent(request)
        }
    }
)
```

## Migration Guide

### Before (RSyntaxTextArea)

```kotlin
SwingPanel(
    factory = {
        val area = RSyntaxTextArea().apply {
            text = fileContent
            isEditable = false
            syntaxEditingStyle = getSyntaxStyleForFile(file)
        }
        RTextScrollPane(area)
    }
)
```

### After (Monaco Editor + WebView)

```kotlin
val webViewState = rememberWebViewState(url = "")
val viewerHost = remember { WebViewerHost(webViewState) }

ViewerWebView(
    viewerHost = viewerHost,
    onReady = {
        val request = ViewerRequest(
            type = ViewerType.CODE,
            content = fileContent,
            language = LanguageDetector.detectLanguage(filePath)
        )
        viewerHost.showContent(request)
    }
)
```

## Benefits

1. **Better Syntax Highlighting**: Monaco Editor provides superior syntax highlighting
2. **Cross-Platform**: Unified viewer across JVM, Android, and potentially iOS
3. **Modern Features**: Monaco Editor includes modern IDE features (minimap, bracket matching, etc.)
4. **Extensible**: Easy to add new content types (markdown, PDF, images)
5. **Offline Capable**: Can work without internet connection once Monaco Editor is downloaded

## Performance Considerations

- Monaco Editor adds ~15-20 MB when downloaded locally
- WebView initialization has slight startup cost (~100-200ms)
- File size limit remains at 10MB for viewer

## References

- [compose-webview-multiplatform](https://github.com/KevinnZou/compose-webview-multiplatform)
- [Monaco Editor](https://microsoft.github.io/monaco-editor/)
- [Monaco Editor API](https://microsoft.github.io/monaco-editor/api/index.html)

