# Git Graph Feature - Usage Guide

## Overview

A Git Graph visualization feature has been added to the CommitListView component, providing a visual representation of commit history similar to SourceTree. This feature displays branches, merges, and commit relationships in an intuitive graphical format.

## Components Created

### 1. GitGraphModel.kt
- **GitGraphNode**: Represents a commit node with position and styling information
- **GitGraphLine**: Represents connections between commits (branches, merges)
- **GitGraphStructure**: Complete graph data structure
- **GitGraphBuilder**: Algorithm to build graph structure from commit messages

### 2. GitGraphColumn.kt
- **GitGraphColumn**: Main composable that renders the graph visualization
- **drawGraphLine**: Draws branch lines with smooth curves for merges
- **drawCommitNode**: Renders different node styles (commit, merge, branch start/end)
- **SimpleGitGraphColumn**: Simplified version for linear history

### 3. CommitListView.kt (Modified)
- Added `showGraph` parameter to enable/disable graph (default: true)
- Integrated GitGraphColumn into CommitListItem
- Graph renders alongside commit information in a Row layout

### 4. CommitListViewPreview.kt
- **CommitListViewPreview**: Full preview with realistic sample data
- **CommitListViewWithSampleData**: Interactive preview with selection
- **GitGraphPreview**: Shows different graph patterns (linear, branching, merging)

## Usage

### Basic Usage

```kotlin
@Composable
fun MyCommitView() {
    val commits = remember { loadCommits() }
    var selectedIndex by remember { mutableStateOf(0) }
    
    CommitListView(
        commits = commits,
        selectedIndex = selectedIndex,
        onCommitSelected = { selectedIndex = it },
        showGraph = true  // Enable graph visualization
    )
}
```

### Disable Graph

```kotlin
CommitListView(
    commits = commits,
    selectedIndex = selectedIndex,
    onCommitSelected = { selectedIndex = it },
    showGraph = false  // Disable graph for simpler view
)
```

## Graph Detection Algorithm

The graph builder uses heuristic analysis of commit messages to determine structure:

### Detected Patterns

1. **Merge Commits**: Messages containing "Merge" (case-insensitive)
   - Renders as double-circle nodes
   - Creates curved merge lines back to main branch

2. **Branch Start**: Messages containing:
   - "feat:" or "feature:"
   - "branch"
   - Renders as filled circle with center dot
   - Creates angled branch lines

3. **Regular Commits**: All other commits
   - Renders as simple filled circles
   - Continues current branch with straight lines

### Color Scheme

The graph uses 8 distinct colors for different branches:
- Indigo (main branch)
- Green
- Deep Orange
- Blue
- Purple
- Cyan
- Amber
- Pink

Colors cycle when more than 8 branches exist.

## Customization

### Adjust Visual Parameters

```kotlin
GitGraphColumn(
    node = graphNode,
    graphStructure = graphStructure,
    rowHeight = 72.dp,      // Height of each commit row
    columnWidth = 16.dp,    // Width of each graph column
    modifier = Modifier.padding(start = 4.dp)
)
```

### Node Types

Four node types are available:

1. **COMMIT**: Regular filled circle
2. **MERGE**: Double circle (outline + filled center)
3. **BRANCH_START**: Filled circle with white center dot
4. **BRANCH_END**: Square shape (currently unused)

## Testing

### Run Preview Components

Use the preview components to test the graph visualization:

```kotlin
// Full preview with sample data
CommitListViewPreview()

// Graph-specific examples
GitGraphPreview()
```

### Sample Data

The preview includes 11 realistic commits demonstrating:
- Linear history
- Feature branches
- Merge commits
- Different time intervals
- PR/Issue number extraction (#453, etc.)

## Implementation Details

### Graph Building Process

1. **Parse commit messages** for patterns
2. **Maintain column stack** to track active branches
3. **Assign nodes** to appropriate columns
4. **Generate lines** connecting commits
5. **Calculate max columns** needed for layout

### Canvas Drawing

The graph uses Compose Canvas API with:
- **Lines**: Straight (vertical) or curved (merge/branch)
- **Nodes**: Circles and shapes for commits
- **Colors**: Branch-specific colors from palette
- **Strokes**: 2dp width for visibility

### Performance Considerations

- Graph structure is built once and reused
- Canvas drawing is efficient for scrolling lists
- Heuristic algorithm runs in O(n) time

## Future Enhancements

Potential improvements for more accurate graph visualization:

1. **Parse parent commits** from git log (requires GitOperations extension)
2. **Support complex merge scenarios** (octopus merges)
3. **Add branch labels** alongside nodes
4. **Interactive graph** (click nodes, hover for details)
5. **Customize detection patterns** via configuration

## Architecture

```
CommitListView
  ├─ GitGraphBuilder.buildGraph()  // Build structure
  │   └─ Analyze commit messages
  │
  └─ LazyColumn
      └─ CommitListItem (for each commit)
          ├─ GitGraphColumn  // Render graph
          │   └─ Canvas
          │       ├─ drawGraphLine()
          │       └─ drawCommitNode()
          │
          └─ Column  // Commit info
              ├─ Message
              ├─ Author
              └─ Timestamp
```

## Design System Compliance

The implementation follows the project's design system guidelines:

- Uses `AutoDevColors.Indigo.c600` for primary branch color
- Uses `MaterialTheme.colorScheme` for surface colors
- No hardcoded colors (except in predefined palette)
- Consistent spacing and sizing with existing components

## Build & Test

```bash
# Build the module
./gradlew :mpp-ui:compileKotlinJvm

# Run with other platforms
./gradlew :mpp-ui:compileKotlinJs
./gradlew :mpp-ui:compileKotlinWasm
```

All platforms compile successfully with the new graph feature.

## Known Limitations

1. **Heuristic-based detection**: Graph structure inferred from messages, not actual git parent relationships
2. **Simple branching model**: Works well for common workflows, may not capture complex histories
3. **No branch labels**: Currently shows only visual connections, not branch names
4. **Static visualization**: No interactive features (zoom, pan, etc.)

These limitations can be addressed in future iterations by extending the GitOperations interface to provide parent commit information.

---

**Created**: 2025-11-22  
**Author**: AI Assistant  
**Status**: ✅ Implemented and Tested

