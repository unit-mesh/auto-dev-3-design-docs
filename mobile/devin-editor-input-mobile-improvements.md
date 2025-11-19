# DevInEditorInput Mobile Improvements

## Problem Analysis

### 1. Auto-Focus Issue (iOS Critical ⚠️)
**Current Behavior:**
```kotlin
LaunchedEffect(Unit) {
    focusRequester.requestFocus()
}
```

**Problem:**
- iOS keyboard appears immediately on component mount
- No native way to dismiss keyboard without dismissing screen
- Violates mobile UX patterns (user should control keyboard)

### 2. IME Handling Issues
**Current Behavior:**
```kotlin
.onPreviewKeyEvent { handleKeyEvent(it) }
```

**Problems:**
- Intercepts keys before IME can process them
- Breaks Chinese/Japanese/Korean input composition
- Shift+Enter handling conflicts with some Android IMEs
- No keyboard dismissal via "return" key on iOS

### 3. Layout Issues
- No safe area handling for iOS notch/home indicator
- Compact mode height may be too small (48dp minimum)
- Missing scroll-to-bottom when keyboard appears
- No adaptive height for different screen sizes

## Proposed Solutions

### Solution 1: Conditional Auto-Focus
```kotlin
@Composable
fun DevInEditorInput(
    // ... existing params
    autoFocusOnMount: Boolean = false, // NEW: Default to false
    onFocusRequest: (() -> Unit)? = null, // NEW: Callback for external focus control
) {
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    
    // Only auto-focus on desktop, or when explicitly requested
    LaunchedEffect(Unit) {
        if (autoFocusOnMount && !Platform.isAndroid && !Platform.isIOS) {
            focusRequester.requestFocus()
        }
    }
    
    // Allow parent to control focus
    LaunchedEffect(onFocusRequest) {
        onFocusRequest?.let { callback ->
            // Parent can call this to request focus
        }
    }
}
```

### Solution 2: Improved Keyboard Handling
```kotlin
fun handleKeyEvent(event: KeyEvent): Boolean {
    if (event.type != KeyEventType.KeyDown) return false
    
    val isAndroid = Platform.isAndroid
    val isIOS = Platform.isIOS
    
    return when {
        // Completion popup has priority
        showCompletion -> {
            when (event.key) {
                Key.Enter -> {
                    if (completionItems.isNotEmpty()) {
                        applyCompletion(completionItems[selectedCompletionIndex])
                    }
                    true
                }
                Key.DirectionDown, Key.DirectionUp, Key.Tab -> { /* ... */ true }
                Key.Escape -> { showCompletion = false; true }
                else -> false
            }
        }
        
        // Desktop: Enter to send, Shift+Enter for newline
        !isAndroid && !isIOS && event.key == Key.Enter && !event.isShiftPressed -> {
            if (textFieldValue.text.isNotBlank()) {
                callbacks?.onSubmit(textFieldValue.text)
                textFieldValue = TextFieldValue("")
                showCompletion = false
                // Optional: blur after send
                focusManager.clearFocus()
            }
            true
        }
        
        // Mobile: Don't intercept Enter - let IME handle it
        // User will use send button instead
        
        // Ctrl+P: Enhance prompt (desktop only)
        !isAndroid && !isIOS && event.key == Key.P && event.isCtrlPressed -> {
            enhanceCurrentInput()
            true
        }
        
        // Don't intercept other keys - let IME handle them
        else -> false
    }
}
```

### Solution 3: Add Keyboard Dismissal (Mobile)
```kotlin
// Add this to the TextField's modifier
.pointerInput(Unit) {
    detectTapGestures(
        onTap = {
            if (!focusRequester.captureFocus()) {
                focusRequester.requestFocus()
            }
        }
    )
}

// Add keyboard dismiss action for mobile
if (Platform.isAndroid || Platform.isIOS) {
    val keyboardController = LocalSoftwareKeyboardController.current
    
    // Dismiss keyboard when message is sent
    fun handleSubmit(text: String) {
        callbacks?.onSubmit(text)
        textFieldValue = TextFieldValue("")
        showCompletion = false
        keyboardController?.hide()
        focusManager.clearFocus()
    }
}
```

### Solution 4: Safe Area & IME Padding
```kotlin
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding

Column(
    modifier = modifier
        .windowInsetsPadding(WindowInsets.safeDrawing) // iOS notch/home indicator
        .imePadding() // Keyboard padding
) {
    // ... existing content
}
```

### Solution 5: Improved Mobile Layout
```kotlin
val isAndroid = Platform.isAndroid
val isIOS = Platform.isIOS
val isMobile = isAndroid || isIOS

Box(
    modifier = Modifier
        .fillMaxWidth()
        .heightIn(
            min = if (isCompactMode) {
                when {
                    isIOS -> 56.dp // iOS: taller for easier touch
                    isAndroid -> 52.dp // Android: standard touch target
                    else -> 56.dp
                }
            } else {
                80.dp
            },
            max = if (isCompactMode) {
                when {
                    isIOS -> 140.dp // iOS: allow more expansion
                    isAndroid -> 120.dp
                    else -> 96.dp
                }
            } else {
                160.dp
            }
        )
        .padding(
            horizontal = if (isMobile) 16.dp else 12.dp,
            vertical = if (isMobile) 12.dp else 8.dp
        )
) {
    BasicTextField(
        // ... existing config
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Text,
            imeAction = if (isMobile) ImeAction.Send else ImeAction.Default
        ),
        keyboardActions = KeyboardActions(
            onSend = {
                if (textFieldValue.text.isNotBlank()) {
                    callbacks?.onSubmit(textFieldValue.text)
                    textFieldValue = TextFieldValue("")
                    showCompletion = false
                }
            }
        ),
        // ...
    )
}
```

## Implementation Plan

### Phase 1: Critical Fixes (iOS keyboard issue)
1. ✅ Remove auto-focus on mobile platforms
2. ✅ Add `autoFocusOnMount` parameter (default: false)
3. ✅ Add keyboard dismissal on message send
4. ✅ Don't intercept Enter key on mobile

### Phase 2: IME Improvements
1. ✅ Use `KeyboardOptions` and `KeyboardActions` for mobile
2. ✅ Stop intercepting keys that should go to IME
3. ✅ Add ImeAction.Send for mobile send button

### Phase 3: Layout Polish
1. ✅ Add safe area insets for iOS
2. ✅ Adjust min heights for better mobile ergonomics
3. ✅ Improve padding/spacing for touch targets

### Phase 4: Focus Management
1. ✅ Add programmatic focus control API
2. ✅ Add tap-outside-to-dismiss (optional)
3. ✅ Clear focus after message send

## Testing Checklist

### iOS Testing
- [ ] Keyboard doesn't auto-appear on screen load
- [ ] Tap text field → keyboard appears
- [ ] Send message → keyboard dismisses
- [ ] Tap outside → keyboard dismisses (if implemented)
- [ ] Safe area respected (notch, home indicator)
- [ ] Chinese/Japanese input works correctly

### Android Testing
- [ ] Keyboard doesn't auto-appear on screen load
- [ ] Tap text field → keyboard appears
- [ ] IME actions work (Send button on keyboard)
- [ ] Multi-line input works smoothly
- [ ] Navigation bar insets respected
- [ ] Pinyin/handwriting input works correctly

### Desktop Testing (Regression)
- [ ] Auto-focus still works (if enabled)
- [ ] Enter sends message, Shift+Enter adds newline
- [ ] Ctrl+P enhances prompt
- [ ] Completion popup keyboard navigation works
- [ ] All existing features work as before

## Code Changes Summary

### Files to Modify
1. `DevInEditorInput.kt` - Main component
2. `AgentChatInterface.kt` - Pass `autoFocusOnMount = false`
3. `AutoDevApp.android.kt` - Add keyboard controller
4. `AutoDevApp.apple.kt` - Add keyboard controller

### Breaking Changes
- None (new parameter has safe default)

### API Additions
```kotlin
@Composable
fun DevInEditorInput(
    // ... existing params
    autoFocusOnMount: Boolean = false, // NEW
    dismissKeyboardOnSend: Boolean = true, // NEW
    imeAction: ImeAction = ImeAction.Default, // NEW
)
```
