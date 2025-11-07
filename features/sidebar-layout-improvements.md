# Sidebar 布局改进

## 概述

根据用户反馈，对 TreeView 功能进行了重大布局和 UI 改进，使其更符合现代 IDE 的侧边栏设计模式。

## 主要改进

### 1. **图标更改：Folder → Sidebar Menu**
- **旧图标**: `Folder` / `FolderOpen` 
- **新图标**: `Menu` / `MenuOpen` ☰
- **原因**: 更符合侧边栏切换的通用 UX 模式

### 2. **按钮位置调整**
- **旧位置**: 工具栏中间
- **新位置**: 工具栏最右边
- **好处**: 符合 VS Code、IntelliJ 等 IDE 的设计习惯

### 3. **布局重新设计**

#### 旧布局（不佳）
```
┌────────────────┬───────────────┐
│ Chat + Tree    │  FileViewer   │
│  (分割面板)    │   (optional)  │
└────────────────┴───────────────┘
```

#### 新布局（优化后）
```
┌────────┬─────────────┬─────────────┐
│Project │ Conversation│ File Viewer │
│Explorer│    Area     │  (optional) │
│ (280px)│             │             │
│ (left) │   (center)  │   (right)   │
└────────┴─────────────┴─────────────┘
```

**优势**:
- ✅ **Project Explorer** 固定在左侧（IDE 标准）
- ✅ **Conversation Area** 在中间（主工作区）
- ✅ **File Viewer** 在右侧（辅助查看）
- ✅ 三列布局清晰，符合直觉

### 4. **命名改进**
- ~~TreeView~~ → **Project Explorer**
- ~~ChatView~~ → **Conversation Area**
- ~~File Explorer~~ → **Project Explorer**
- 标题显示: `PROJECT` (简洁的标签风格)

### 5. **Header 优化**
- 移除关闭按钮（从 TopBar 控制更合理）
- 简化标题为小标签 `PROJECT`
- 图标 + 标签组合，更专业

### 6. **FileViewer 集成修复**
修复了点击文件时 FileViewer 不显示的 bug：
- 使用 `FileViewerPanelWrapper` 正确打开代码文件
- Conversation Area 和 FileViewer 可调整大小的分割面板
- 关闭 FileViewer 后 Conversation Area 自动扩展占满

## 布局模式详解

### 仅 Conversation（默认）
```
┌─────────────────────────────────┐
│      Conversation Area          │
│         (100% width)            │
└─────────────────────────────────┘
```

### Sidebar + Conversation
```
┌────────┬────────────────────────┐
│Project │   Conversation Area    │
│ (280px)│     (remaining)        │
└────────┴────────────────────────┘
```

### Sidebar + Conversation + FileViewer
```
┌────────┬─────────────┬──────────┐
│Project │ Conversation│  File    │
│ (280px)│   (50%)     │  (50%)   │
│        │             │          │
└────────┴─────────────┴──────────┘
```

### 仅 Conversation + FileViewer
```
┌──────────────┬────────────────┐
│ Conversation │  File Viewer   │
│    (50%)     │      (50%)     │
│              │                │
└──────────────┴────────────────┘
```

## UI 控制

### 桌面端 (Desktop)
```
TopBar: [Logo] ... [Settings] [Tools] [Agent] [Mode] [Theme] [Folder] [New] [☰ Sidebar]
                                                                              ↑
                                                                         最右边位置
```

### 移动端 (Android)
```
Menu (⋮)
  ├─ Model Configuration
  ├─ Tool Configuration
  ├─ Agent
  ├─ Mode
  ├─ Theme
  ├─ Language
  ├─ [☰] Project Explorer  ← 显示 "Show/Hide Sidebar"
  ├─ Open Project
  └─ New Chat
```

## 技术实现

### FileSystemTreeView
- 固定宽度 280dp
- 去除关闭按钮
- 简化 header 为标签风格
- 文件点击调用 `viewModel.renderer.openFileViewer()`

### AgentChatInterface
```kotlin
Row {
    // 1. Project Explorer (左侧)
    if (viewModel.isTreeViewVisible) {
        FileSystemTreeView(width = 280.dp)
    }
    
    // 2. Conversation + FileViewer (右侧)
    if (viewModel.renderer.currentViewingFile != null) {
        ResizableSplitPane {
            first = AgentMessageList
            second = FileViewerPanelWrapper
        }
    } else {
        AgentMessageList(weight = 1f)
    }
}
```

### 图标状态
```kotlin
// 未激活
Icon(Menu, tint = onSurface)

// 已激活
Icon(MenuOpen, tint = primary)
```

## 用户体验提升

### Before (旧设计)
❌ Folder 图标不够语义化  
❌ 按钮位置不统一  
❌ Tree 和 Chat 混在一起难以区分  
❌ 点击文件不打开 FileViewer  

### After (新设计)
✅ Sidebar Menu 图标清晰  
✅ 按钮在最右边，符合习惯  
✅ 三列布局清晰独立  
✅ 文件点击正确打开 FileViewer  
✅ 固定宽度的侧边栏，更稳定  

## 测试结果

```bash
./gradlew :mpp-ui:jvmJar
# ✅ BUILD SUCCESSFUL

./gradlew :mpp-ui:jvmTest  
# ✅ BUILD SUCCESSFUL
```

## 文件变更

```
✅ mpp-ui/.../icons/AutoDevComposeIcons.kt          (添加 Menu/MenuOpen)
✅ mpp-ui/.../chat/TopBarMenuDesktop.kt             (按钮移到最右边)
✅ mpp-ui/.../chat/TopBarMenuMobile.kt              (文案和图标更新)
✅ mpp-ui/.../agent/AgentChatInterface.kt           (三列布局)
✅ mpp-ui/.../agent/FileSystemTreeView.kt           (简化 header)
✅ docs/features/sidebar-layout-improvements.md     (本文档)
```

## 对比总结

| 特性 | 旧设计 | 新设计 |
|------|--------|--------|
| 图标 | Folder | Menu/MenuOpen ☰ |
| 位置 | 中间 | 最右边 |
| 布局 | 混合 | 三列独立 |
| 侧边栏 | 可变宽度 | 固定 280dp |
| 文件查看 | ❌ 不工作 | ✅ 正确打开 |
| 语义性 | 文件夹 | 侧边栏切换 |
| IDE 一致性 | 弱 | ✅ 强 |

