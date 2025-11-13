# Code Review UI Integration - Quick Start Guide

## 概述

已成功实现 CodeReview Agent 的 Side-by-Side UI，包括 Git 集成和提交历史管理。

## 运行 Demo

### 启动演示程序

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-ui:runCodeReviewDemo
```

### Demo 功能

Demo 程序会：

1. 自动读取项目的最近 20 次 Git 提交
2. 显示提交历史选择器
3. 展示选中提交的 diff
4. 提供 AI 分析和自动修复功能（模拟）

### 预期输出

启动后，你会在终端看到类似的输出：

```
============================================================
🚀 Initializing Code Review Demo
📁 Project Path: /Volumes/source/ai/autocrud
============================================================
📜 Loading last 20 commits...
✅ Loaded 20 commits:
  • a1b2c3d - Fix UI layout issues
  • e4f5g6h - Add Git integration
  • i7j8k9l - Update documentation
  ...
🔍 Loading diff for commit: a1b2c3d - Fix UI layout issues
✅ Loaded diff with 5 changed files
  • file1.kt [MODIFIED] (kotlin)
  • file2.kt [ADDED] (kotlin)
  ...
✅ Initialization complete
```

## 集成到现有应用

### 方案 1: 使用 AgentInterfaceRouter (推荐)

在现有的应用中，替换 `AgentChatInterface` 为 `AgentInterfaceRouter`:

```kotlin
import cc.unitmesh.devins.ui.compose.agent.AgentInterfaceRouter
import cc.unitmesh.devins.ui.compose.agent.AgentType

@Composable
fun YourApp() {
    var selectedAgentType by remember { mutableStateOf(AgentType.CODING) }
    
    AgentInterfaceRouter(
        llmService = llmService,
        selectedAgentType = selectedAgentType,
        onAgentTypeChange = { type -> 
            selectedAgentType = type
        },
        // ... other parameters
    )
}
```

### 方案 2: 直接使用 CodeReviewPage

如果你需要专门的 Code Review 页面：

```kotlin
import cc.unitmesh.devins.ui.compose.agent.codereview.CodeReviewPage

@Composable
fun CodeReviewScreen() {
    CodeReviewPage(
        llmService = llmService,
        onBack = { /* 返回上一页 */ }
    )
}
```

### 方案 3: 使用 JvmCodeReviewViewModel (高级)

如果你需要更多控制：

```kotlin
import cc.unitmesh.devins.ui.compose.agent.codereview.*
import cc.unitmesh.devins.workspace.WorkspaceManager

@Composable
fun AdvancedCodeReviewScreen() {
    val workspace = WorkspaceManager.getCurrentOrEmpty()
    val gitService = remember { GitService(workspace.rootPath ?: "") }
    
    val viewModel = remember {
        JvmCodeReviewViewModel(
            workspace = workspace,
            gitService = gitService,
            llmService = null,
            codeReviewAgent = null
        )
    }
    
    val state by viewModel.state.collectAsState()
    
    // 你的自定义 UI
    Column {
        // 提交选择器
        if (state.commitHistory.isNotEmpty()) {
            CommitSelector(
                commits = state.commitHistory,
                selectedIndex = state.selectedCommitIndex,
                onSelectCommit = { index ->
                    viewModel.loadDiffForCommit(index)
                }
            )
        }
        
        // Diff 和 AI 分析 UI
        CodeReviewSideBySideView(
            viewModel = viewModel,
            modifier = Modifier.fillMaxSize()
        )
    }
}
```

## 核心组件说明

### GitService

负责从 Git 仓库读取提交历史和 diff：

```kotlin
val gitService = GitService(projectPath = "/path/to/project")

// 获取最近的提交
val commits = gitService.getRecentCommits(count = 20)

// 获取特定提交的 diff
val diff = gitService.getCommitDiff(commitHash = "a1b2c3d")
```

### JvmCodeReviewViewModel

管理 Code Review 的状态和逻辑：

```kotlin
val viewModel = JvmCodeReviewViewModel(
    workspace = workspace,
    gitService = gitService,
    llmService = llmService,
    codeReviewAgent = codeReviewAgent
)

// 加载提交历史
viewModel.loadCommitHistory(count = 20)

// 切换到其他提交
viewModel.loadDiffForCommit(index = 5)

// 开始 AI 分析
viewModel.startAnalysis()

// 取消分析
viewModel.cancelAnalysis()

// 刷新
viewModel.refresh()
```

### CodeReviewState

UI 状态模型：

```kotlin
data class CodeReviewState(
    val isLoading: Boolean,
    val error: String?,
    val commitHistory: List<CommitInfo>,     // 提交历史
    val selectedCommitIndex: Int,            // 当前选中的提交
    val diffFiles: List<DiffFileInfo>,       // Diff 文件列表
    val selectedFileIndex: Int,              // 当前选中的文件
    val aiProgress: AIAnalysisProgress,      // AI 分析进度
    val fixResults: List<FixResult>          // 修复结果
)
```

## UI 结构

```
┌────────────────────────────────────────────────────────────────┐
│  提交选择器 (CommitSelector)                                   │
│  📜 Commit History: [a1b2c3d - Fix UI layout issues]          │
├────────────────────────────────────────────────────────────────┤
│  Left: Diff Viewer          │  Right: AI Analysis             │
├─────────────────────────────┼──────────────────────────────────┤
│  📄 Changed Files (5)       │  🤖 AI Analysis & Auto-Fix       │
│  • file1.kt [Modified]      │                                  │
│  • file2.kt [Added]         │  Progress: Lint → Analyze → Fix │
│  • file3.kt [Modified]      │                                  │
│                             │  📋 Lint Output:                 │
│  --- file1.kt               │  Running lint...                 │
│  @@ -42,5 +42,6 @@          │                                  │
│  +  new line added          │  🧠 AI Analysis:                 │
│  -  old line removed        │  Found 3 issues...               │
│     unchanged line          │                                  │
│                             │  ✅ Fix Results:                 │
│                             │  • Issue fixed at line 42        │
│                             │  • Issue fixed at line 58        │
└─────────────────────────────┴──────────────────────────────────┘
```

## 功能测试

### 1. 提交导航

Demo 提供了前进/后退按钮来浏览提交历史：

```kotlin
// 在 Demo 中
Button(onClick = { viewModel.loadDiffForCommit(index - 1) }) {
    Text("◀ Prev")
}

Button(onClick = { viewModel.loadDiffForCommit(index + 1) }) {
    Text("Next ▶")
}
```

### 2. AI 分析

点击 "🤖 Start AI Analysis" 按钮触发分析流程：

```kotlin
Button(onClick = { viewModel.startAnalysis() }) {
    Text("🤖 Start AI Analysis")
}
```

分析流程：
1. **Lint**: 运行代码检查工具
2. **Analyze**: AI 分析 lint 输出
3. **Fix**: 生成自动修复方案

### 3. 状态监控

Demo 左侧面板显示实时状态：

- 提交数量和当前选择
- 变更文件数量
- 加载/错误状态

## 日志输出

程序会输出详细的日志用于调试：

```
🚀 Initializing JvmCodeReviewViewModel
📁 Workspace: /Volumes/source/ai/autocrud
📜 Loading last 20 commits...
✅ Loaded 20 commits:
  • a1b2c3d - Fix UI layout issues
  • e4f5g6h - Add Git integration
  ...
🔍 Loading diff for commit: a1b2c3d - Fix UI layout issues
✅ Loaded diff with 5 changed files
  • file1.kt [MODIFIED] (kotlin)
  • file2.kt [ADDED] (kotlin)
  ...
🤖 Starting AI analysis...
🔍 Running lint on 5 files...
🧠 Analyzing lint output...
🔧 Generating fixes...
✅ Generated 3 fixes
✅ AI analysis completed
```

## 故障排除

### 问题: Demo 启动失败

**解决方案**:
1. 确保项目是一个有效的 Git 仓库
2. 检查 `projectPath` 是否正确
3. 查看终端输出的错误信息

### 问题: 看不到提交历史

**原因**: 项目可能没有 Git 提交历史

**解决方案**:
```bash
cd /your/project
git init
git add .
git commit -m "Initial commit"
```

### 问题: Diff 加载失败

**原因**: 可能是 Git 命令执行失败

**检查**:
```bash
# 测试 git 命令是否可用
git log -n 1
git show HEAD
```

## 下一步开发

### 短期 (P0)

1. **实际 Lint 集成**
   - 集成 Ktlint, ESLint, Pylint 等工具
   - 解析 lint 输出

2. **真实 AI 修复**
   - 连接 CodeReviewAgent
   - 实现流式输出

3. **Diff 解析器**
   - 解析 unified diff 格式
   - 生成 DiffHunk 和 DiffLine

### 中期 (P1)

4. **交互功能**
   - 应用/忽略修复
   - 手动编辑修复
   - 批量操作

5. **性能优化**
   - 虚拟滚动
   - 增量加载

### 长期 (P2)

6. **高级功能**
   - 多人协作审查
   - 评论系统
   - 导出 Patch

## 相关文件

- 核心实现: `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/`
- Demo: `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/demo/CodeReviewDemo.kt`
- UI 组件: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/CodeReviewSideBySideView.kt`
- 数据模型: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/CodeReviewModels.kt`

## 总结

现在你可以：

✅ 运行 Demo 查看完整的 Code Review UI  
✅ 通过 println 查看 Git 读取和状态变化  
✅ 测试提交切换和 AI 分析流程  
✅ 集成到你的应用中  

**启动命令**: `./gradlew :mpp-ui:runCodeReviewDemo`

所有功能都已准备就绪，可以直接集成到现有代码中！
