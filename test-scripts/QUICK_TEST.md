# Git Graph - Quick Test Guide

## 快速验证

### 1. 查看 ASCII 可视化

```bash
./docs/test-scripts/print-git-graph.sh
```

这会显示预期的图形模式。

### 2. 运行单元测试

```bash
./gradlew :mpp-ui:jvmTest --tests "GitGraphBuilderTest" --console=plain
```

所有测试应该通过 ✅

### 3. 编译验证

```bash
./gradlew :mpp-ui:compileKotlinJvm --console=plain
```

应该编译成功 ✅

## 核心改进

### ❌ 之前的问题

```
*  Commit 1
|
|  Commit 2  ← 位置歪斜
/
B  Branch start
|
M  Merge  ← 线条混乱
```

### ✅ 改进后

```
*      Initial commit
| /    ← 清晰的分支点
B      feat: New feature
|
*      Work on feature
M---   ← 清晰的合并线
|
*      Continue on main
```

## 算法改进要点

### 1. Lane (通道) 抽象
```kotlin
private data class Lane(
    val column: Int,      // 列位置
    val color: Color,     // 分支颜色
    val branchName: String,
    var isActive: Boolean
)
```

### 2. 正确的线条绘制

**分支开始时：**
- ✅ 画分支线：从父分支到新分支
- ✅ 画垂直线：父分支继续

**合并时：**
- ✅ 画合并线：从当前分支到目标
- ✅ 画垂直线：目标分支继续

### 3. 清晰的状态管理

```kotlin
val lanes = mutableListOf<Lane>()
var currentLane = lanes[0]
var nextAvailableColumn = 1
```

## 测试案例

### 测试 1: 线性历史
```
Input: ["Commit A", "Commit B", "Commit C"]
Output: 单列，3个节点，2条线
```

### 测试 2: 分支与合并
```
Input: ["Initial", "feat: Branch", "Work", "Merge", "Continue"]
Output: 2列，正确的分支/合并线
```

### 测试 3: 多分支
```
Input: 多个 feat + Merge 循环
Output: 顺序分支，每次正确合并回主线
```

## 如何在 UI 中使用

```kotlin
CommitListView(
    commits = yourCommits,
    selectedIndex = selectedIndex,
    onCommitSelected = { index -> ... },
    showGraph = true  // 启用 Git Graph
)
```

## Debug 工具

### ASCII 输出
```kotlin
val ascii = GitGraphBuilder.buildAsciiGraph(commits.map { it.message })
println(ascii)
```

### 检查图形结构
```kotlin
val graph = GitGraphBuilder.buildGraph(messages)
println("Columns: ${graph.maxColumns}")
println("Nodes: ${graph.nodes.size}")
println("Lines: ${graph.lines.size}")
```

## 预期输出示例

```
Git Graph ASCII Visualization
==================================================

*  Initial commit
|
| /B  feat: Add authentication
|
*  Implement OAuth
|
M  Merge branch 'auth' into main
|
*  Continue development

Legend: * = commit, M = merge, B = branch start
Columns: 2, Nodes: 5, Lines: 6
```

## ✅ 验证清单

- [x] 算法重新设计（Lane 抽象）
- [x] 单元测试通过
- [x] ASCII 可视化正确
- [x] JVM 编译成功
- [x] CommitListView 集成
- [x] 文档完善

## 🎯 结论

重新设计的算法解决了"歪斜"问题：
1. **清晰的抽象**: Lane 概念
2. **正确的线条**: 每个场景都正确绘制
3. **易于调试**: ASCII 输出
4. **经过测试**: 完整的单元测试

现在可以在实际 UI 中使用了！🚀

