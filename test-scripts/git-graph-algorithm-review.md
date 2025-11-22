# Git Graph Algorithm - Design Review

## 🔄 Algorithm Redesign (v2)

### Issues with Original Implementation

1. **Column Management**: 使用 Stack 管理列，但合并时逻辑混乱
2. **Line Drawing**: 垂直线重复绘制，导致"歪斜"问题  
3. **State Tracking**: 分支状态跟踪不清晰

### Improved Algorithm

#### Core Abstraction: Lane (通道)

```kotlin
private data class Lane(
    val column: Int,
    val color: Color,
    val branchName: String = "",
    var isActive: Boolean = true
)
```

**Lane** 代表一个视觉列，commits 在其中流动。

#### Algorithm Flow

```
1. Initialize
   └─ Main lane at column 0
   
2. For each commit:
   ├─ Is Merge?
   │  ├─ Draw merge line: current lane → target lane  
   │  ├─ Draw vertical line on target lane
   │  ├─ Remove current lane (if not main)
   │  └─ Switch to target lane
   │
   ├─ Is Branch Start?
   │  ├─ Create new lane with next available column
   │  ├─ Draw branch line: parent lane → new lane
   │  ├─ Draw vertical line on parent lane (continue)
   │  └─ Switch to new lane
   │
   └─ Regular Commit
      ├─ Place node in current lane
      └─ Draw vertical line to next commit
```

### Key Improvements

#### 1. 清晰的职责分离

- **Node Placement**: 决定 commit 放在哪一列
- **Line Drawing**: 连接 commits 的线条
- **Lane Management**: 追踪活跃的分支

#### 2. 正确的线条绘制

**Before:**
```
问题：重复绘制垂直线，导致重叠和位置错误
```

**After:**
```kotlin
// 分支开始时：同时绘制父分支和新分支的线
if (index > 0) {
    // Branch line
    lines.add(GitGraphLine(
        fromColumn = currentLane.column,
        toColumn = newLane.column,
        ...
    ))
    
    // Continue parent lane
    lines.add(GitGraphLine(
        fromColumn = currentLane.column,
        toColumn = currentLane.column,
        ...
    ))
}
```

#### 3. 合并处理

```kotlin
// Merge: 两条线都要画
if (currentLane.column != targetLane.column && index > 0) {
    // Merge line from branch
    lines.add(...)
    
    // Vertical line on main branch
    lines.add(...)
}
```

### Test Results

#### Linear History
```
*  Initial commit
|
*  Add feature A
|
*  Fix bug
|
*  Update docs
```
✅ Single column (expected)

#### Branch and Merge
```
*      Initial commit
| /
B      feat: Start new feature
|
*      Work on feature
M      Merge into main
|
*      Continue on main
```
✅ Proper branching and merging

#### Multiple Branches
```
*      Initial
| /
B      feat: Auth
|
*      Work on auth
M      Merge auth
| /
B      feat: Profile
|
*      Work on profile
M      Merge profile
|
*      Final
```
✅ Multiple sequential branches

## 🎯 Implementation Details

### Node Types

| Type | Symbol | Usage |
|------|--------|-------|
| COMMIT | `*` | Regular commits |
| BRANCH_START | `B` | Start of new branch |
| MERGE | `M` | Merge commit |
| BRANCH_END | `E` | (Reserved for future) |

### Line Types

| Type | Visual | Usage |
|------|--------|-------|
| Vertical | `\|` | Continue in same column |
| Branch | `/` | Branch off to new column |
| Merge | `---` | Merge back to target |

### Color Palette

8 distinct colors for up to 8 concurrent branches:
1. Indigo (main)
2. Green
3. Deep Orange
4. Blue
5. Purple
6. Cyan
7. Amber
8. Pink

Colors cycle for branch > 8.

## 📊 Complexity Analysis

- **Time**: O(n) where n = number of commits
- **Space**: O(n) for nodes + O(m) for lines, m ≈ n
- **Columns**: O(k) where k = max concurrent branches

## 🧪 Testing

### Unit Tests

```kotlin
@Test
fun testLinearHistory() { ... }

@Test
fun testSimpleBranchAndMerge() { ... }

@Test
fun testMultipleFeatureBranches() { ... }

@Test
fun testComplexScenario() { ... }

@Test
fun testGraphStructureIntegrity() { ... }
```

All tests pass ✅

### ASCII Visualization

```kotlin
val ascii = GitGraphBuilder.buildAsciiGraph(commits)
println(ascii)
```

Provides visual debugging output.

## 🔧 Usage in Compose

### Integration

```kotlin
@Composable
fun CommitListView(...) {
    val graphStructure = GitGraphBuilder.buildGraph(
        commits.map { it.message }
    )
    
    LazyColumn {
        items(commits.size) { index ->
            CommitListItem(
                commit = commits[index],
                graphNode = graphStructure.nodes[index],
                graphStructure = graphStructure
            )
        }
    }
}
```

### Rendering

```kotlin
@Composable
fun GitGraphColumn(
    node: GitGraphNode?,
    graphStructure: GitGraphStructure,
    rowHeight: Dp = 60.dp,
    columnWidth: Dp = 16.dp
) {
    Canvas(...) {
        // Draw lines
        graphStructure.lines.forEach { line ->
            drawGraphLine(line, ...)
        }
        
        // Draw node
        if (node != null) {
            drawCommitNode(node, ...)
        }
    }
}
```

## 🎨 Design Decisions

### Why Lane Abstraction?

- **清晰**: 明确表示"分支占据的视觉列"
- **可扩展**: 未来可以加入更多属性（branch name, author等）
- **状态管理**: `isActive` 标志便于跟踪

### Why Heuristic Detection?

当前实现使用消息模式匹配：
- ✅ 简单、快速
- ✅ 无需修改 GitOperations 接口
- ✅ 适用于大多数常见场景

**Future**: 可以扩展为使用真实的 parent commit 信息。

### Why Not Git-Flow?

完整的 git-flow 支持需要：
- Parent commit parsing
- Multiple parent handling (octopus merges)
- Complex branch topology

当前实现专注于：
- 清晰的视觉呈现
- 常见工作流支持
- 性能优化

## 📝 Known Limitations

1. **Heuristic-based**: 依赖消息模式，不解析真实 git 关系
2. **Simple merges**: 仅支持简单的双parent合并
3. **Sequential branches**: 假设分支顺序执行，不支持并行开发

这些限制是设计上的权衡，可以在未来版本中改进。

## 🚀 Future Enhancements

### Phase 1: Current ✅
- [x] Basic linear history
- [x] Simple branching
- [x] Merge commits
- [x] ASCII debugging
- [x] Compose rendering

### Phase 2: Enhanced
- [ ] Parse parent commits from GitOperations
- [ ] Handle octopus merges (3+ parents)
- [ ] Branch labels alongside nodes
- [ ] Interactive hover/click

### Phase 3: Advanced
- [ ] Parallel branch rendering
- [ ] Branch filtering
- [ ] Zoom/pan controls
- [ ] Performance optimization for 1000+ commits

## ✅ Verification

```bash
# Compile
./gradlew :mpp-ui:compileKotlinJvm

# Test
./gradlew :mpp-ui:jvmTest --tests "GitGraphBuilderTest"

# View ASCII output
./docs/test-scripts/print-git-graph.sh
```

All verifications pass ✅

## 📚 References

- [SourceTree UI](https://www.sourcetreeapp.com/) - Inspiration
- [Git Graph Visualization](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
- [Compose Canvas](https://developer.android.com/jetpack/compose/graphics/draw/overview)

---

**Version**: 2.0  
**Date**: 2025-11-22  
**Status**: ✅ Reviewed and Tested

