# Change Summary 功能分析与设计

## 📋 概述

本文档详细分析了 `@core` 模块的 `PlannerResultSummary` 和 `@mpp-ui` 模块的 `FileChangeSummary` 的实现，并为 `@mpp-idea` 模块设计新的 Change Summary 功能。

---

## 🔍 现有实现分析

### 1. Core 模块：PlannerResultSummary (Swing 实现)

**文件位置**: `core/src/main/kotlin/cc/unitmesh/devti/gui/planner/PlannerResultSummary.kt`

#### 核心特性

1. **数据源**: 使用 IntelliJ Platform 的 `Change` 对象
   - 来自 VCS (Version Control System) API
   - 包含 `beforeRevision` 和 `afterRevision`
   - 支持 `Change.Type`: NEW, DELETED, MOVED, MODIFICATION

2. **UI 组件** (Swing)
   - `JPanel` with `BorderLayout`
   - 标题栏显示统计信息
   - 可滚动的变更列表 (`JBScrollPane` + `GridLayout`)
   - 每个变更项显示：文件名、路径、变更类型图标、操作按钮

3. **操作功能**
   - **View**: 显示 Diff 对话框 (使用 `SimpleDiffViewer` / `SimpleOnesideDiffViewer`)
   - **Accept**: 应用变更到文件系统
     - 使用 `runWriteAction` 确保线程安全
     - 通过 `FileDocumentManager` 更新文档
     - 支持创建新文件
   - **Discard**: 使用 `RollbackWorker` 回滚变更
   - **Accept All / Discard All**: 批量操作

4. **Diff 显示**
   - 使用 IntelliJ 的 `DiffContentFactoryEx` 创建 diff 内容
   - `SimpleDiffRequest` 用于双栏对比
   - `DialogWrapper` 包装 diff viewer
   - 支持 Apply 按钮直接应用变更

#### 关键代码模式

```kotlin
// 变更监听器模式
interface ChangeActionListener {
    fun onView(change: Change)
    fun onDiscard(change: Change)
    fun onAccept(change: Change)
}

// 更新变更列表
fun updateChanges(changes: MutableList<Change>) {
    this.changes = changes
    changesPanel.removeAll()
    
    if (changes.isEmpty()) {
        // 显示空状态
    } else {
        changes.forEach { change ->
            val changePanel = createChangeItemPanel(change, fileName, filePath)
            changesPanel.add(changePanel)
        }
    }
    
    changesPanel.revalidate()
    changesPanel.repaint()
}

// Rollback 操作
rollbackWorker.doRollback(listOf(change), false)
```

---

### 2. MPP-UI 模块：FileChangeSummary (Compose 实现)

**文件位置**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/changes/FileChangeSummary.kt`

#### 核心特性

1. **数据源**: 使用 `FileChangeTracker` (跨平台单例)
   - `StateFlow<List<FileChange>>` 响应式数据流
   - 自动合并同一文件的多次变更
   - 保留原始内容用于 undo

2. **UI 组件** (Compose Multiplatform)
   - `Surface` with rounded corners
   - 可折叠的标题栏 (`AnimatedVisibility`)
   - `LazyColumn` 显示变更列表
   - 每个变更项显示：图标、文件名、路径、diff 统计 (+/-行数)

3. **操作功能**
   - **Click**: 显示 Diff 对话框 (`DiffViewDialog`)
   - **Undo**: 恢复文件到原始内容
     - 使用 `WorkspaceManager.fileSystem.writeFile()`
     - 从 `FileChangeTracker` 移除变更
   - **Keep**: 仅从跟踪列表移除，保留文件变更
   - **Undo All / Keep All**: 批量操作

4. **Diff 显示**
   - 使用 `DiffUtils.generateUnifiedDiff()` 生成统一 diff 格式
   - `DiffSketchRenderer.RenderDiff()` 渲染 diff 内容
   - 支持滚动查看大文件
   - 显示准确的 +/- 行数统计 (基于 LCS 算法)

#### 关键代码模式

```kotlin
// 响应式数据流
val changes by FileChangeTracker.changes.collectAsState()

// 文件系统操作
scope.launch {
    fileSystem?.let { fs ->
        val original = change.originalContent
        when {
            change.changeType == ChangeType.CREATE -> {
                if (fs.exists(change.filePath)) {
                    fs.writeFile(change.filePath, "")
                }
            }
            original != null -> {
                fs.writeFile(change.filePath, original)
            }
        }
        FileChangeTracker.removeChange(change)
    }
}

// Diff 统计
val diffStats = change.getDiffStats()
Text(text = "+${diffStats.addedLines}")
Text(text = "-${diffStats.deletedLines}")
```

---

## 📊 对比分析

| 特性 | Core (Swing) | MPP-UI (Compose) |
|------|-------------|------------------|
| **数据模型** | IntelliJ `Change` | `FileChange` (自定义) |
| **数据源** | VCS API | `FileChangeTracker` |
| **UI 框架** | Swing | Compose Multiplatform |
| **响应式** | 手动 revalidate/repaint | StateFlow 自动更新 |
| **Diff 算法** | IntelliJ DiffContentFactory | DiffUtils (LCS) |
| **文件操作** | FileDocumentManager | WorkspaceManager.fileSystem |
| **Rollback** | RollbackWorker (VCS) | 手动写入原始内容 |
| **跨平台** | ❌ (仅 JVM) | ✅ (KMP) |
| **变更合并** | ❌ | ✅ (自动合并同文件) |

---

## 🎯 MPP-IDEA 模块设计建议

### 设计目标

为 `mpp-idea` 模块创建一个 **Jewel 风格** 的 Change Summary 组件，结合两种实现的优点：

1. 使用 IntelliJ Platform 的原生 API (如 `Change`, `RollbackWorker`)
2. 采用 Compose + Jewel 的现代 UI
3. 保持与 `IdeaPlanSummaryBar` 一致的设计语言
4. 支持 IntelliJ 的 Diff 工具集成

### 架构设计

```
mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/toolwindow/changes/
├── IdeaFileChangeSummary.kt       # 主组件 (Jewel Compose)
├── IdeaFileChangeItem.kt          # 单个变更项
├── IdeaFileChangeDiffDialog.kt    # Diff 对话框
└── IdeaFileChangeTracker.kt       # IDEA 特定的变更跟踪器
```

### 核心组件设计

#### 1. IdeaFileChangeSummary.kt

**功能**: 主容器组件，显示所有文件变更的摘要

**设计要点**:
- 使用 Jewel 主题 (`JewelTheme.globalColors`)
- 可折叠设计 (类似 `IdeaPlanSummaryBar`)
- 响应式数据流 (`StateFlow<List<Change>>`)
- 集成 IntelliJ 的 `ChangeListManager`

**UI 结构**:
```kotlin
@Composable
fun IdeaFileChangeSummary(
    project: Project,
    modifier: Modifier = Modifier
) {
    // 从 ChangeListManager 获取变更
    val changes by remember {
        derivedStateOf {
            ChangeListManager.getInstance(project)
                .defaultChangeList.changes.toList()
        }
    }

    Column(modifier) {
        // 折叠标题栏
        IdeaChangeSummaryHeader(
            changeCount = changes.size,
            isExpanded = isExpanded,
            onToggle = { isExpanded = !isExpanded },
            onAcceptAll = { /* ... */ },
            onDiscardAll = { /* ... */ }
        )

        // 展开的变更列表
        AnimatedVisibility(visible = isExpanded) {
            LazyColumn {
                items(changes) { change ->
                    IdeaFileChangeItem(
                        change = change,
                        project = project,
                        onView = { showDiffDialog(change) },
                        onAccept = { acceptChange(change) },
                        onDiscard = { discardChange(change) }
                    )
                }
            }
        }
    }
}
```

#### 2. IdeaFileChangeItem.kt

**功能**: 单个文件变更的显示项

**设计要点**:
- 显示变更类型图标 (使用 Jewel Icons)
- 文件名 + 路径 (紧凑布局)
- Diff 统计 (+/- 行数)
- 操作按钮 (View, Accept, Discard)

**UI 特性**:
- Hover 效果 (Jewel 风格)
- 点击整行查看 diff
- 图标颜色根据变更类型变化

#### 3. IdeaFileChangeDiffDialog.kt

**功能**: 显示文件变更的 Diff 对话框

**设计要点**:
- 使用 IntelliJ 的 `DialogWrapper`
- 集成 `SimpleDiffViewer` 或 `SimpleOnesideDiffViewer`
- 支持 Apply / Cancel 操作
- 使用 Jewel Compose 包装 Swing Diff Viewer

**实现方式**:
```kotlin
class IdeaFileChangeDiffDialog(
    private val project: Project,
    private val change: Change
) : DialogWrapper(project) {

    init {
        init()
        title = "Diff: ${change.virtualFile?.name}"
        setOKButtonText("Apply")
    }

    override fun createCenterPanel(): JComponent {
        // 使用 IntelliJ 的 Diff API
        val diffRequest = createDiffRequest(change)
        val diffViewer = SimpleDiffViewer(
            object : DiffContext() {
                override fun getProject() = this@IdeaFileChangeDiffDialog.project
                // ...
            },
            diffRequest
        )
        diffViewer.init()
        return diffViewer.component
    }

    override fun doOKAction() {
        // 应用变更
        applyChange(change)
        super.doOKAction()
    }
}
```

#### 4. IdeaFileChangeTracker.kt

**功能**: 桥接 IntelliJ VCS 和 FileChangeTracker

**设计要点**:
- 监听 `ChangeListManager` 的变更
- 将 IntelliJ `Change` 转换为 `FileChange`
- 同步到 `FileChangeTracker` (用于跨平台组件)
- 支持双向同步

**实现方式**:
```kotlin
class IdeaFileChangeTracker(private val project: Project) {

    private val changeListManager = ChangeListManager.getInstance(project)

    init {
        // 监听 VCS 变更
        project.messageBus.connect().subscribe(
            ChangeListListener.TOPIC,
            object : ChangeListListener {
                override fun changeListsChanged() {
                    syncChangesToTracker()
                }
            }
        )
    }

    private fun syncChangesToTracker() {
        val changes = changeListManager.defaultChangeList.changes
        changes.forEach { change ->
            val fileChange = convertToFileChange(change)
            FileChangeTracker.recordChange(fileChange)
        }
    }

    private fun convertToFileChange(change: Change): FileChange {
        return FileChange(
            filePath = change.virtualFile?.path ?: "",
            changeType = when (change.type) {
                Change.Type.NEW -> ChangeType.CREATE
                Change.Type.DELETED -> ChangeType.DELETE
                Change.Type.MOVED -> ChangeType.RENAME
                else -> ChangeType.EDIT
            },
            originalContent = change.beforeRevision?.content,
            newContent = change.afterRevision?.content
        )
    }
}
```

---

## 🎨 UI 设计规范

### 颜色方案 (Jewel)

```kotlin
// 变更类型颜色
val changeTypeColor = when (changeType) {
    ChangeType.CREATE -> AutoDevColors.Green.c400
    ChangeType.EDIT -> AutoDevColors.Blue.c400
    ChangeType.DELETE -> AutoDevColors.Red.c400
    ChangeType.RENAME -> AutoDevColors.Purple.c400
}

// 背景色
val backgroundColor = JewelTheme.globalColors.panelBackground
val hoverColor = JewelTheme.globalColors.panelBackground.copy(alpha = 0.8f)
```

### 图标映射

```kotlin
val changeIcon = when (changeType) {
    ChangeType.CREATE -> AllIconsKeys.Vcs.Add
    ChangeType.EDIT -> AllIconsKeys.Actions.Edit
    ChangeType.DELETE -> AllIconsKeys.Vcs.Remove
    ChangeType.RENAME -> AllIconsKeys.Actions.MoveTo
}
```

### 布局规范

- **标题栏高度**: 32dp
- **变更项高度**: 28dp (紧凑模式)
- **图标大小**: 16dp
- **间距**: 4dp (紧凑), 8dp (标准)
- **圆角**: 4dp (与 IdeaPlanSummaryBar 一致)

---

## 🔄 集成方案

### 在 IdeaDevInInputArea 中集成

```kotlin
@Composable
fun IdeaDevInInputArea(
    project: Project,
    viewModel: IdeaAgentViewModel,
    // ...
) {
    Column {
        // Plan Summary Bar
        IdeaPlanSummaryBar(
            plan = viewModel.renderer.currentPlan,
            project = project
        )

        // File Change Summary (新增)
        IdeaFileChangeSummary(
            project = project,
            modifier = Modifier.fillMaxWidth()
        )

        // Top Toolbar
        IdeaTopToolbar(...)

        // Editor
        SwingPanel(...)
    }
}
```

### 显示逻辑

1. **自动显示**: 当有文件变更时自动显示
2. **位置**: 在 PlanSummaryBar 下方，TopToolbar 上方
3. **折叠状态**: 默认折叠，显示变更数量
4. **展开状态**: 显示所有变更项，最大高度 300dp，超出滚动

---

## 📝 实现优先级

### Phase 1: 基础功能 (MVP)
- [ ] `IdeaFileChangeSummary.kt` - 基础 UI 框架
- [ ] `IdeaFileChangeItem.kt` - 变更项显示
- [ ] 集成到 `IdeaDevInInputArea`
- [ ] 基础操作: View, Accept, Discard

### Phase 2: 高级功能
- [ ] `IdeaFileChangeDiffDialog.kt` - Diff 对话框
- [ ] `IdeaFileChangeTracker.kt` - VCS 集成
- [ ] 批量操作: Accept All, Discard All
- [ ] 变更统计和过滤

### Phase 3: 优化和增强
- [ ] 性能优化 (大量变更时)
- [ ] 快捷键支持
- [ ] 右键菜单
- [ ] 与 Git 工具窗口联动

---

## 🚀 技术挑战与解决方案

### 挑战 1: Swing Diff Viewer 在 Compose 中的集成

**问题**: IntelliJ 的 Diff Viewer 是 Swing 组件，需要在 Compose 中显示

**解决方案**:
- 使用 `DialogWrapper` 包装 Diff Viewer (保持原生体验)
- 或使用 `SwingPanel` 在 Compose 中嵌入 Swing 组件
- 参考 `IdeaPlanSummaryBar` 的实现模式

### 挑战 2: VCS Change 对象的生命周期

**问题**: `Change` 对象可能在 VCS 操作后失效

**解决方案**:
- 缓存必要的信息 (文件路径、内容)
- 使用 `VirtualFile` 的弱引用
- 监听 `ChangeListListener` 更新状态

### 挑战 3: 跨平台数据同步

**问题**: 需要同步 IntelliJ `Change` 和 `FileChangeTracker`

**解决方案**:
- `IdeaFileChangeTracker` 作为桥接层
- 单向同步: VCS → FileChangeTracker
- 避免循环依赖

---

## 📚 参考资料

### 相关文件
- `core/src/main/kotlin/cc/unitmesh/devti/gui/planner/PlannerResultSummary.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/changes/FileChangeSummary.kt`
- `mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/toolwindow/plan/IdeaPlanSummaryBar.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/diff/FileChangeTracker.kt`

### IntelliJ Platform API
- `com.intellij.openapi.vcs.changes.Change`
- `com.intellij.openapi.vcs.changes.ChangeListManager`
- `com.intellij.openapi.vcs.changes.ui.RollbackWorker`
- `com.intellij.diff.DiffContentFactoryEx`
- `com.intellij.diff.tools.simple.SimpleDiffViewer`

### Jewel 组件
- `org.jetbrains.jewel.foundation.theme.JewelTheme`
- `org.jetbrains.jewel.ui.component.*`
- `cc.unitmesh.devins.ui.compose.theme.AutoDevColors`


