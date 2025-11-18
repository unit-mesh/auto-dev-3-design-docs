# AutoDev Desktop 桌面特性

本文档介绍 AutoDev Desktop (Compose Multiplatform JVM 版本) 的桌面特性。

## 功能概览

AutoDev Desktop 提供了以下桌面特性：

1. **MenuBar (菜单栏)** - 标准的应用菜单，包含快捷键支持
2. **System Tray (系统托盘)** - 最小化到托盘，支持快速唤醒
3. **Context Menus (右键菜单)** - 文本选择和复制功能

## 1. MenuBar (菜单栏)

### 功能说明

应用窗口顶部的菜单栏，提供常用操作的快捷访问。

### 菜单结构

#### File 菜单
- **Open File... (Ctrl+O)** - 打开文件选择器
- **Exit (Ctrl+Q)** - 退出应用

#### Edit 菜单
- **Copy (Ctrl+C)** - 复制选中内容
- **Paste (Ctrl+V)** - 粘贴内容

#### Help 菜单
- **Documentation** - 打开文档
- **About AutoDev** - 显示关于对话框

### 快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 打开文件 | `Ctrl+O` | 打开文件选择器 |
| 退出应用 | `Ctrl+Q` | 退出应用程序 |
| 复制 | `Ctrl+C` | 复制选中的文本 |
| 粘贴 | `Ctrl+V` | 粘贴剪贴板内容 |

### 实现位置

- 文件：`mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/desktop/AutoDevMenuBar.kt`
- 使用：在 `Main.kt` 的 `Window` 组件中调用

### 代码示例

```kotlin
Window(
    onCloseRequest = { isWindowVisible = false },
    title = "AutoDev Desktop",
    state = windowState
) {
    // 添加菜单栏
    AutoDevMenuBar(
        onOpenFile = {
            // 处理打开文件
        },
        onExit = ::exitApplication
    )
    
    // 应用内容
    AutoDevApp()
}
```

## 2. System Tray (系统托盘)

### 功能说明

应用可以最小化到系统托盘，而不是完全关闭。用户可以通过托盘图标快速唤醒应用。

### 特性

- **托盘图标** - 显示 AutoDev 图标在系统托盘
- **双击唤醒** - 双击托盘图标显示主窗口
- **右键菜单** - 提供显示/隐藏窗口、退出应用等选项
- **关闭行为** - 点击窗口关闭按钮时，窗口隐藏到托盘而不是退出

### 托盘菜单

- **Show Window / Hide Window** - 显示或隐藏主窗口
- **Exit** - 完全退出应用

### 图标加载

托盘图标加载优先级：

1. 尝试加载 `resources/icon-64.png`
2. 如果失败，创建默认图标（蓝色圆形，带 "AD" 字样）

### 实现位置

- 文件：`mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/desktop/AutoDevTray.kt`
- 使用：在 `Main.kt` 的 `application` 块中调用

### 代码示例

```kotlin
application {
    var isWindowVisible by remember { mutableStateOf(true) }
    
    // 添加系统托盘
    AutoDevTray(
        isWindowVisible = isWindowVisible,
        onShowWindow = { isWindowVisible = true },
        onExit = ::exitApplication
    )
    
    if (isWindowVisible) {
        Window(
            onCloseRequest = { isWindowVisible = false }, // 隐藏到托盘
            title = "AutoDev Desktop",
            state = windowState
        ) {
            AutoDevApp()
        }
    }
}
```

## 3. Context Menus (右键菜单)

### 功能说明

为文本内容提供右键菜单支持，方便用户复制文本。

### 特性

- **文本选择** - 使用 `SelectionContainer` 支持文本选择
- **右键菜单** - 提供复制、全选等操作
- **系统剪贴板** - 使用 AWT Toolkit 确保跨应用复制粘贴

### 实现位置

- 文件：`mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/desktop/TextContextMenu.kt`

### 使用方式

#### 方式 1: 使用 `TextWithContextMenu`

```kotlin
TextWithContextMenu {
    Text("可以右键复制的文本")
}
```

#### 方式 2: 使用 `CopyableTextContainer`

```kotlin
CopyableTextContainer {
    Column {
        Text("第一行文本")
        Text("第二行文本")
    }
}
```

#### 方式 3: 直接使用 `SelectionContainer`

```kotlin
SelectionContainer {
    Text("可以选择和复制的文本")
}
```

### 工具函数

#### `copyToSystemClipboard(text: String)`

直接复制文本到系统剪贴板：

```kotlin
Button(onClick = {
    copyToSystemClipboard("要复制的文本")
}) {
    Text("复制")
}
```

## 技术实现

### 依赖

所有功能都基于 Compose Multiplatform Desktop API：

- `androidx.compose.ui.window.MenuBar` - 菜单栏
- `androidx.compose.ui.window.Tray` - 系统托盘
- `androidx.compose.foundation.ContextMenuDataProvider` - 右键菜单
- `androidx.compose.foundation.text.selection.SelectionContainer` - 文本选择

### 平台兼容性

这些功能仅在 JVM (Desktop) 平台可用：

- ✅ **JVM (Desktop)** - 完整支持
- ❌ **Android** - 不支持（Android 有自己的菜单系统）
- ❌ **iOS** - 不支持
- ❌ **JS/Wasm** - 不支持

## 未来扩展

### 计划中的功能

1. **全局快捷键** - 支持全局快捷键唤醒应用
2. **通知** - 系统通知支持
3. **最近文件** - File 菜单中显示最近打开的文件
4. **主题切换** - 在菜单栏中添加主题切换选项
5. **窗口管理** - 记住窗口位置和大小

### 参考资料

- [Compose Multiplatform - Tray, Notifications, MenuBar](https://github.com/JetBrains/compose-multiplatform/tree/master/tutorials/Tray_Notifications_MenuBar_new)
- [Compose Desktop - Keyboard](https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-desktop-keyboard.html)

## 测试

### 运行应用

```bash
cd mpp-ui
./gradlew :mpp-ui:run
```

### 测试清单

- [ ] 菜单栏显示正常
- [ ] Ctrl+O 快捷键打开文件选择器
- [ ] Ctrl+Q 快捷键退出应用
- [ ] 关闭窗口时隐藏到托盘
- [ ] 双击托盘图标显示窗口
- [ ] 托盘右键菜单正常工作
- [ ] 文本可以选择和复制
- [ ] 复制的文本可以粘贴到其他应用

## 故障排除

### 托盘图标不显示

- 检查系统托盘是否启用
- 确认 `resources/icon-64.png` 存在
- 查看控制台是否有错误信息

### 快捷键不工作

- 确认快捷键没有被系统或其他应用占用
- 检查菜单栏是否正确初始化

### 文本无法复制

- 确认使用了 `SelectionContainer`
- 检查是否有其他组件拦截了点击事件

