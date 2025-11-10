# TreeView TopBarMenu 集成

## 概述

TreeView 切换功能已集成到 TopBarMenu 中，提供统一的用户体验。

## UI 位置

### 桌面端 (Desktop)
- 位置：顶部工具栏
- 显示方式：文件夹图标按钮
- 交互：单击切换 TreeView 显示/隐藏
- 状态反馈：激活时图标高亮显示

### 移动端 (Android)
- 位置：顶部菜单（"⋮" 按钮）
- 显示方式：下拉菜单项 "File Explorer"
- 交互：选择菜单项切换 TreeView
- 状态反馈：显示当前状态 "Show Explorer" / "Hide Explorer"

## 状态管理

### 架构
```
AutoDevApp (状态持有者)
    ↓
TopBarMenu (控制器)
    ↓
AgentChatInterface (状态同步)
    ↓
CodingAgentViewModel (内部状态)
```

### 状态流
1. 用户在 TopBarMenu 中点击 TreeView 切换按钮
2. `onToggleTreeView()` 回调触发，更新 AutoDevApp 中的 `isTreeViewVisible` 状态
3. AutoDevApp 将状态传递给 AgentChatInterface
4. AgentChatInterface 通过 LaunchedEffect 同步到 CodingAgentViewModel
5. UI 根据 ViewModel 状态重新渲染

## 代码变更

### 1. TopBarMenu
```kotlin
fun TopBarMenu(
    // ... 其他参数
    isTreeViewVisible: Boolean = false,  // 新增
    onToggleTreeView: () -> Unit = {},   // 新增
)
```

### 2. TopBarMenuDesktop
```kotlin
// TreeView Toggle (只在 Agent 模式下显示)
if (useAgentMode) {
    IconButton(
        onClick = onToggleTreeView,
        // 高亮显示激活状态
        tint = if (isTreeViewVisible) primary else onSurface
    ) {
        Icon(imageVector = AutoDevComposeIcons.Folder)
    }
}
```

### 3. TopBarMenuMobile
```kotlin
// TreeView 菜单项 (只在 Agent 模式下显示)
if (useAgentMode) {
    DropdownMenuItem(
        text = { 
            Text(if (isTreeViewVisible) "Hide Explorer" else "Show Explorer")
        },
        onClick = { onToggleTreeView() },
        leadingIcon = { Icon(AutoDevComposeIcons.Folder) }
    )
}
```

### 4. AgentChatInterface
```kotlin
fun AgentChatInterface(
    // ... 其他参数
    isTreeViewVisible: Boolean = false,      // 新增
    onToggleTreeView: (Boolean) -> Unit = {}, // 新增
) {
    // 状态同步逻辑
    LaunchedEffect(isTreeViewVisible) {
        viewModel?.isTreeViewVisible = isTreeViewVisible
    }
}
```

### 5. CodingAgentViewModel
```kotlin
// TreeView state（公开可写）
var isTreeViewVisible by mutableStateOf(false)
```

## 集成点

### 已移除
- ❌ AgentStatusBar 中的 TreeView 切换按钮（避免重复）

### 新增
- ✅ TopBarMenu 中的 TreeView 切换功能
- ✅ 桌面端 IconButton 样式
- ✅ 移动端 DropdownMenuItem 样式
- ✅ 状态同步机制

## 使用场景

### Agent 模式
- TreeView 切换按钮**可见**
- 用户可以切换文件浏览器
- 支持分屏查看代码和对话

### Chat 模式
- TreeView 切换按钮**隐藏**
- 专注于对话交互
- 不需要文件浏览功能

## 优势

1. **统一性**: 所有顶部功能集中在 TopBarMenu
2. **一致性**: 桌面端和移动端行为一致
3. **可发现性**: 用户容易找到 TreeView 功能
4. **状态清晰**: 图标/文本清楚显示当前状态
5. **响应式**: 图标高亮提供即时反馈

## 测试

```bash
# 编译
./gradlew :mpp-ui:jvmJar

# 测试
./gradlew :mpp-ui:jvmTest
```

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenu.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenuDesktop.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenuMobile.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/AgentChatInterface.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/CodingAgentViewModel.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`




