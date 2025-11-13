# Code Review Side-by-Side UI

## 概述

为 CodeReviewAgent 设计的全新 Side-by-Side UI，实现了自动化的代码审查和修复流程。

## 架构设计

### 目录结构

```
mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/
├── CodeReviewModels.kt           # 数据模型
├── CodeReviewViewModel.kt        # 状态管理和业务逻辑
├── CodeReviewSideBySideView.kt   # 主 UI 组件
└── CodeReviewPage.kt             # 页面入口
```

### 核心组件

#### 1. 数据模型 (CodeReviewModels.kt)

```kotlin
- CodeReviewState: 完整的 UI 状态
- DiffFileInfo: Git diff 文件信息
- DiffHunk/DiffLine: Diff 内容结构
- AIAnalysisProgress: AI 分析进度
- FixResult: 修复结果
```

#### 2. ViewModel (CodeReviewViewModel.kt)

负责：
- 从 Workspace 加载 Git diff
- 协调 Lint 分析流程
- 调用 AI 进行问题分析和修复
- 管理状态和异步操作

#### 3. UI 组件 (CodeReviewSideBySideView.kt)

**左侧视图 (DiffView)**:
- 文件树展示
- Diff 语法高亮
- 增删改标记
- 行号显示

**右侧视图 (AIAnalysisView)**:
- 流式 Lint 输出
- AI 分析过程
- 自动修复生成
- 修复结果展示

## 使用方式

### 1. 通过 AgentInterfaceRouter 切换

在 `AutoDevApp.kt` 或其他入口处，使用 `AgentInterfaceRouter` 替代直接的 `AgentChatInterface`:

```kotlin
AgentInterfaceRouter(
    llmService = llmService,
    selectedAgentType = AgentType.CODE_REVIEW, // 切换到 Code Review 模式
    onAgentTypeChange = { type -> /* handle agent type change */ },
    // ... other parameters
)
```

### 2. 直接使用 CodeReviewPage

```kotlin
CodeReviewPage(
    llmService = llmService,
    onBack = { /* return to previous screen */ }
)
```

## 功能流程

```
用户选择 CODE_REVIEW Agent
        ↓
[加载 Git Diff]
        ↓
显示 Side-by-Side 视图
        ↓
┌─────────────────┬─────────────────┐
│  左侧: Diff     │  右侧: AI 流程  │
│  - 文件列表     │  1. 运行 Lint   │
│  - 代码变更     │  2. AI 分析     │
│  - 高亮显示     │  3. 生成修复    │
│                 │  4. 显示结果    │
└─────────────────┴─────────────────┘
        ↓
用户查看修复建议
```

## 数据流

### 1. Workspace Git 集成

```kotlin
// Workspace.kt 预留接口
interface Workspace {
    suspend fun getLastCommit(): GitCommitInfo?
    suspend fun getGitDiff(base: String?, target: String?): GitDiffInfo?
}
```

**实现说明**:
- 接口已在 `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/workspace/Workspace.kt` 中定义
- 具体实现需要在各平台 (JVM/JS/Native) 中完成
- JVM: 使用 JGit 或执行 git 命令
- JS/WASM: 通过 MCP 或外部服务获取

### 2. Lint → AI → Fix 流程

```kotlin
// CodeReviewViewModel.kt
suspend fun startAnalysis() {
    // Step 1: Run lint
    runLint(filePaths)
    
    // Step 2: AI analyzes lint output
    analyzeLintOutput()
    
    // Step 3: Generate fixes
    generateFixes()
}
```

### 3. 结构化数据

```json
{
  "line": 42,
  "lint": "Unused variable",
  "lintValid": true,
  "risk": "medium",
  "aiFix": "Remove the unused variable",
  "status": "fixed"
}
```

## UI 特性

### 左侧 Diff 视图

- ✅ 文件列表展示 (可选择)
- ✅ 变更类型图标 (Added/Deleted/Modified/Renamed)
- ✅ 语言检测和标签
- ✅ Diff 语法高亮 (绿/红)
- ✅ 行号显示
- 🚧 折叠/展开功能 (未来)
- 🚧 跳转到行 (未来)

### 右侧 AI 分析视图

- ✅ 进度阶段指示器 (Lint → Analyze → Fix)
- ✅ 流式输出展示
- ✅ 结构化修复结果卡片
- ✅ 风险等级标记 (Critical/High/Medium/Low/Info)
- ✅ 状态展示 (Fixed/No Issue/Skipped/Failed)
- ✅ 开始/取消控制

## 待实现功能

### 短期 (P0)

1. **Git Diff 实现**
   - [ ] JVM 平台实现 (使用 JGit)
   - [ ] JS/WASM 平台实现 (通过 MCP 或 API)
   
2. **Lint 集成**
   - [ ] ESLint (JavaScript/TypeScript)
   - [ ] Pylint (Python)
   - [ ] Ktlint (Kotlin)
   - [ ] Checkstyle (Java)

3. **AI 修复集成**
   - [ ] 连接 CodeReviewAgent
   - [ ] 流式输出支持
   - [ ] 实际修复代码生成

### 中期 (P1)

4. **高级 Diff 功能**
   - [ ] 语法高亮增强
   - [ ] 折叠大块代码
   - [ ] 搜索/过滤
   - [ ] 并排对比模式

5. **交互功能**
   - [ ] 应用/忽略修复
   - [ ] 手动编辑修复
   - [ ] 批量操作
   - [ ] 导出 Patch

### 长期 (P2)

6. **性能优化**
   - [ ] 虚拟滚动 (大文件)
   - [ ] 增量加载
   - [ ] 缓存机制

7. **协作功能**
   - [ ] 多人审查
   - [ ] 评论系统
   - [ ] 版本历史

## 集成指南

### 在现有应用中使用

1. **替换 AgentChatInterface**:

```kotlin
// Before
AgentChatInterface(...)

// After
AgentInterfaceRouter(...)
```

2. **添加 Agent 类型切换**:

```kotlin
var selectedAgentType by remember { mutableStateOf(AgentType.CODING) }

// UI 中添加切换按钮
Button(onClick = { selectedAgentType = AgentType.CODE_REVIEW }) {
    Text("Code Review")
}
```

### 自定义样式

所有组件都支持 `Modifier` 参数，可以自定义样式：

```kotlin
CodeReviewSideBySideView(
    viewModel = viewModel,
    modifier = Modifier
        .fillMaxSize()
        .background(MaterialTheme.colors.background)
        .padding(16.dp)
)
```

## 开发者注意事项

### Kotlin Multiplatform 兼容性

- ✅ 使用 `expect`/`actual` 处理平台特定代码
- ✅ 避免在 `@JsExport` 中使用 `Flow`，使用 `Promise`
- ✅ 不在 WASM 中使用 emoji 和 UTF-8 字符 (仅在注释中)
- ✅ 使用具体类而非接口作为 JS 导出类型

### 性能考虑

- 使用 `LazyColumn` 渲染大量列表
- `remember` 缓存计算结果
- `derivedStateOf` 避免重复计算
- 异步加载大文件 diff

### 测试

```bash
# 构建 MPP Core
./gradlew :mpp-core:assembleJsPackage

# 构建和运行 MPP UI
cd mpp-ui
npm run build
npm run start
```

## 相关文档

- [AGENTS.md](../../../../../../../AGENTS.md) - 项目开发规范
- [Workspace.kt](../../../../../../mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/workspace/Workspace.kt) - 工作空间接口
- [CodeReviewAgent.kt](../../../../../../mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodeReviewAgent.kt) - Code Review Agent 实现

## 贡献

欢迎贡献！请遵循项目的代码规范和提交信息格式。

## License

与主项目相同
