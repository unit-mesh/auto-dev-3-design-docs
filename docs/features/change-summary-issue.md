# Feature Request: File Change Summary for mpp-idea Module

## 📋 Summary

Implement a **File Change Summary** component for the `mpp-idea` module using Jewel Compose, providing users with a visual overview of all file changes made by the AI Agent with the ability to review, accept, or discard changes.

## 🎯 Motivation

Currently, the AutoDev project has two different implementations of change summary functionality:

1. **Core Module** (`PlannerResultSummary`): Swing-based UI for IntelliJ IDEA plugin
2. **MPP-UI Module** (`FileChangeSummary`): Compose-based UI for cross-platform applications

The `mpp-idea` module needs a modern, Jewel-styled change summary component that:
- Integrates seamlessly with IntelliJ Platform's VCS APIs
- Provides a consistent UI experience with other mpp-idea components (like `IdeaPlanSummaryBar`)
- Leverages the power of Compose while maintaining native IntelliJ look and feel

## 🔍 Current State Analysis

### Core Module (Swing Implementation)

**Strengths**:
- ✅ Deep integration with IntelliJ VCS API (`Change`, `RollbackWorker`)
- ✅ Native IntelliJ Diff Viewer integration
- ✅ Robust file operations with `FileDocumentManager`
- ✅ Support for all change types (NEW, DELETED, MOVED, MODIFICATION)

**Limitations**:
- ❌ Swing-based UI (not modern)
- ❌ Manual UI updates (revalidate/repaint)
- ❌ Not reusable across platforms

### MPP-UI Module (Compose Implementation)

**Strengths**:
- ✅ Modern Compose UI with reactive data flow (`StateFlow`)
- ✅ Cross-platform compatible
- ✅ Automatic change merging for the same file
- ✅ Accurate diff statistics using LCS algorithm
- ✅ Clean, compact UI design

**Limitations**:
- ❌ Custom `FileChange` model (not using IntelliJ's `Change`)
- ❌ Manual file system operations (no VCS integration)
- ❌ Limited to workspace file system

## 💡 Proposed Solution

Create a **hybrid approach** that combines the best of both worlds:

### Architecture

```
mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/toolwindow/changes/
├── IdeaFileChangeSummary.kt       # Main component (Jewel Compose)
├── IdeaFileChangeItem.kt          # Individual change item
├── IdeaFileChangeDiffDialog.kt    # Diff dialog wrapper
└── IdeaFileChangeTracker.kt       # Bridge between VCS and FileChangeTracker
```

### Key Features

1. **Jewel-Styled UI**
   - Consistent with `IdeaPlanSummaryBar` design
   - Collapsible header with change count
   - Compact change items with hover effects
   - Smooth animations

2. **IntelliJ VCS Integration**
   - Use `ChangeListManager` to track changes
   - Support `RollbackWorker` for discarding changes
   - Native `SimpleDiffViewer` for diff display
   - Proper file operation handling

3. **Reactive Data Flow**
   - `StateFlow` for automatic UI updates
   - Efficient change tracking and merging
   - Real-time synchronization with VCS

4. **User Actions**
   - **View**: Show diff in dialog
   - **Accept**: Apply change to file system
   - **Discard**: Rollback change using VCS
   - **Accept All / Discard All**: Batch operations

### UI Design

```
┌─────────────────────────────────────────────────────────────┐
│ ▼ 3 files changed                    [Undo All] [Keep All] │
├─────────────────────────────────────────────────────────────┤
│ ✚ UserService.kt · src/main/kotlin/...    +15 -3  [✓] [✗] │
│ ✎ UserRepository.kt · src/main/kotlin/... +8 -2   [✓] [✗] │
│ ✚ UserTest.kt · src/test/kotlin/...       +42 -0  [✓] [✗] │
└─────────────────────────────────────────────────────────────┘
```

**Legend**:
- ✚ = New file (Green)
- ✎ = Modified file (Blue)
- ✗ = Deleted file (Red)
- ↔ = Renamed file (Purple)
- [✓] = Accept button
- [✗] = Discard button

### Integration Point

The component will be placed in `IdeaDevInInputArea`:

```kotlin
Column {
    IdeaPlanSummaryBar(...)      // Existing
    IdeaFileChangeSummary(...)   // NEW
    IdeaTopToolbar(...)          // Existing
    SwingPanel(...)              // Editor
}
```

## 📐 Technical Design

### 1. Data Flow

```
ChangeListManager (IntelliJ VCS)
        ↓
IdeaFileChangeTracker (Bridge)
        ↓
FileChangeTracker (Cross-platform)
        ↓
IdeaFileChangeSummary (UI)
```

### 2. Component Hierarchy

```kotlin
@Composable
fun IdeaFileChangeSummary(
    project: Project,
    modifier: Modifier = Modifier
) {
    val changes by remember {
        derivedStateOf {
            ChangeListManager.getInstance(project)
                .defaultChangeList.changes.toList()
        }
    }
    
    if (changes.isEmpty()) return
    
    Column(modifier) {
        // Header with stats and actions
        IdeaChangeSummaryHeader(
            changeCount = changes.size,
            isExpanded = isExpanded,
            onToggle = { isExpanded = !isExpanded },
            onAcceptAll = { acceptAllChanges(changes) },
            onDiscardAll = { discardAllChanges(changes) }
        )
        
        // Expandable change list
        AnimatedVisibility(visible = isExpanded) {
            LazyColumn(modifier = Modifier.heightIn(max = 300.dp)) {
                items(changes, key = { it.virtualFile?.path ?: it.hashCode() }) { change ->
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

### 3. Diff Dialog Integration

```kotlin
class IdeaFileChangeDiffDialog(
    private val project: Project,
    private val change: Change
) : DialogWrapper(project) {
    
    override fun createCenterPanel(): JComponent {
        val diffRequest = when (change.type) {
            Change.Type.NEW -> createOneSideDiffRequest(change)
            else -> createTwoSideDiffRequest(change)
        }
        
        val diffViewer = SimpleDiffViewer(
            createDiffContext(project),
            diffRequest
        )
        diffViewer.init()
        return diffViewer.component
    }
    
    override fun doOKAction() {
        applyChange(change, project)
        super.doOKAction()
    }
}
```

## 🎨 Design Specifications

### Colors (Jewel Theme)

```kotlin
// Change type colors
CREATE  -> AutoDevColors.Green.c400
EDIT    -> AutoDevColors.Blue.c400
DELETE  -> AutoDevColors.Red.c400
RENAME  -> AutoDevColors.Purple.c400

// Background
Panel   -> JewelTheme.globalColors.panelBackground
Hover   -> JewelTheme.globalColors.panelBackground.copy(alpha = 0.8f)
Border  -> JewelTheme.globalColors.borders.normal
```

### Icons (Jewel)

```kotlin
CREATE  -> AllIconsKeys.Vcs.Add
EDIT    -> AllIconsKeys.Actions.Edit
DELETE  -> AllIconsKeys.Vcs.Remove
RENAME  -> AllIconsKeys.Actions.MoveTo
```

### Layout

- **Header Height**: 32dp
- **Item Height**: 28dp (compact)
- **Icon Size**: 16dp
- **Spacing**: 4dp (compact), 8dp (standard)
- **Border Radius**: 4dp
- **Max List Height**: 300dp (scrollable)

## 📋 Implementation Tasks

### Phase 1: MVP (Core Functionality)

- [ ] Create `IdeaFileChangeSummary.kt` with basic UI structure
- [ ] Create `IdeaFileChangeItem.kt` for individual change display
- [ ] Integrate with `IdeaDevInInputArea`
- [ ] Implement basic View, Accept, Discard actions
- [ ] Add unit tests for core functionality

### Phase 2: VCS Integration

- [ ] Create `IdeaFileChangeTracker.kt` for VCS bridge
- [ ] Implement `IdeaFileChangeDiffDialog.kt` with IntelliJ Diff Viewer
- [ ] Add batch operations (Accept All, Discard All)
- [ ] Sync with `FileChangeTracker` for cross-platform compatibility

### Phase 3: Polish & Optimization

- [ ] Performance optimization for large change sets
- [ ] Keyboard shortcuts support
- [ ] Context menu integration
- [ ] Git tool window synchronization
- [ ] Accessibility improvements

## 🔗 Related Files

### Reference Implementations
- `core/src/main/kotlin/cc/unitmesh/devti/gui/planner/PlannerResultSummary.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/changes/FileChangeSummary.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/changes/FileChangeItem.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/changes/DiffViewDialog.kt`

### Similar Components
- `mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/toolwindow/plan/IdeaPlanSummaryBar.kt`

### Core Dependencies
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/diff/FileChangeTracker.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/diff/FileChange.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/diff/DiffUtils.kt`

## 🏷️ Labels

- `enhancement`
- `mpp-idea`
- `ui`
- `compose`
- `vcs`

## 📊 Priority

**Medium-High** - This feature enhances the user experience by providing visibility into AI-made changes and control over accepting/rejecting them.

## 🤔 Open Questions

1. Should we support partial file changes (hunks) or only full file changes?
2. How should we handle conflicts when the file has been modified externally?
3. Should the change summary persist across IDE restarts?
4. Should we integrate with IntelliJ's Local History feature?


