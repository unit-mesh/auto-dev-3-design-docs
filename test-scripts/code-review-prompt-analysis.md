# Code Review Prompt Analysis & Optimization

## 问题分析

### 测试结果概览

执行命令：`node dist/jsMain/typescript/index.js review -p .`

#### 观察到的问题：

1. **Tool Call 效率低下**
   - Agent 多次尝试 `read-file` 失败（"File path cannot be empty"）
   - 不得不回退到使用 `shell cat` 命令
   - 总共进行了 **5-6 轮** tool call 才完成审查
   - 每轮消耗 1800+ tokens

2. **职责混杂**
   - 当前 prompt 既要求 Agent 自己收集数据（读文件、运行 linter）
   - 又要求它进行深度分析
   - 导致流程冗长、token 消耗大

3. **缺乏结构化输出要求**
   - 虽然最终输出还算结构化，但依赖 LLM 自己理解
   - 没有明确的 JSON 或 Markdown schema 约束

### Token 消耗统计（从日志）

```
Iteration 1: 1785 input + 53 output = 1838 tokens
Iteration 2: 1954 input + 70 output = 2024 tokens
Iteration 3: 2130 input + 72 output = 2202 tokens
Iteration 4: 2318 input + 76 output = 2394 tokens
Iteration 5: 2563 input + 72 output = 2635 tokens
Iteration 6: 3108 input + 917 output = 4025 tokens
Total: ~15,000 tokens
```

### 流程分析

**当前流程（Agent-Driven）：**
```
1. 系统 Prompt（CodeReviewAgentTemplate）
   ↓
2. User Message: "请审查这些文件：file1, file2, ..."
   ↓
3. LLM: "我需要读取文件"
   ↓
4. Tool Call: read-file (失败)
   ↓
5. LLM: "让我用 shell 命令"
   ↓
6. Tool Call: shell cat file
   ↓
7. LLM: "让我运行 linter"
   ↓
8. Tool Call: shell detekt ...
   ↓
9. LLM: "现在我可以提供审查了"
   ↓
10. 最终输出
```

**优化后流程（Data-Driven）：**
```
1. 代码中直接收集数据：
   - 读取文件内容
   - 运行 linters
   - 分析 diff 和修改范围
   ↓
2. 系统 Prompt（CodeReviewAnalysisTemplate）
   ↓
3. User Message: 包含所有数据（代码、lint 结果、diff）
   ↓
4. LLM: 直接输出结构化审查结果
   ↓
5. 完成（1轮，~2000 tokens）
```

## 优化方案

### 解决方案：拆分为两个 Prompt

#### 1. `CodeReviewAgentTemplate`（Tool-Driven）
**用途**：CLI 场景，Agent 需要自主决策  
**特点**：
- 提供工具列表和使用说明
- 指导 Agent 如何收集信息
- 适合探索性审查

**保留原因**：
- CLI 用户可能没有预先收集数据
- 需要 Agent 自主决定审查范围
- 更灵活，适应各种场景

#### 2. `CodeReviewAnalysisTemplate`（Data-Driven）✨ **新增**
**用途**：UI 场景（Desktop/Web），数据已预收集  
**特点**：
- 所有数据直接内联在 prompt 中
- 明确要求结构化输出
- **不允许** tool calls
- 一轮完成审查

**优势**：
- **效率提升 70%+**：从 6 轮降至 1 轮
- **Token 节省 ~85%**：从 15k 降至 ~2-3k
- **更可靠**：避免 tool 执行失败
- **结构化输出**：强制要求格式

### 新 Prompt 结构

```markdown
# Code Review Analysis

## 任务
Review Type: COMPREHENSIVE
Files to Review: 1 files
- mpp-ui/src/...TopBarMenuDesktop.kt

## 代码内容
### File: mpp-ui/src/.../TopBarMenuDesktop.kt
```kotlin
<actual code here>
```

## Linter 结果
### Lint Results for: TopBarMenuDesktop.kt
```
detekt: LongMethod, TooManyParameters, ...
```

## 你的任务
提供结构化的代码审查，格式如下：
1. Summary
2. Critical Issues (CRITICAL/HIGH)
3. Recommendations (MEDIUM)
4. Minor Issues (LOW/INFO)
5. Positive Aspects

**不要尝试使用任何工具。所有必要信息都已提供。**
```

### 使用场景对比

| 场景 | 推荐 Prompt | 原因 |
|------|------------|------|
| CLI (node review) | `CodeReviewAgentTemplate` | Agent 自主决策 |
| Desktop UI | `CodeReviewAnalysisTemplate` | 数据已准备好 |
| Web UI | `CodeReviewAnalysisTemplate` | 数据已准备好 |
| API Server | `CodeReviewAnalysisTemplate` | 高效、可预测 |

## 实现建议

### 修改 `CodeReviewViewModel.kt`

```kotlin
suspend fun analyzeLintOutput() {
    // 收集所有数据
    val codeContent = mutableMapOf<String, String>()
    val lintResults = mutableMapOf<String, String>()
    
    // 读取文件
    currentState.diffFiles.forEach { file ->
        val content = workspace.fileSystem.readFile(file.path)
        if (content != null) {
            codeContent[file.path] = content
        }
    }
    
    // 收集 lint 结果
    currentState.aiProgress.lintResults.forEach { result ->
        lintResults[result.filePath] = formatLintResult(result)
    }
    
    // 构建 diff context
    val diffContext = buildDiffContext(currentState.diffFiles)
    
    // 使用新的 analysis prompt
    val promptRenderer = CodeReviewAgentPromptRenderer()
    val analysisPrompt = promptRenderer.renderAnalysisPrompt(
        reviewType = "COMPREHENSIVE",
        filePaths = codeContent.keys.toList(),
        codeContent = codeContent,
        lintResults = lintResults,
        diffContext = diffContext,
        language = "EN"
    )
    
    // 直接调用 LLM，不使用 Agent
    val llmService = KoogLLMService.create(modelConfig)
    llmService.streamPrompt(analysisPrompt, compileDevIns = false).collect { chunk ->
        // 流式更新 UI
        updateState { 
            it.copy(aiProgress = it.aiProgress.copy(
                analysisOutput = it.aiProgress.analysisOutput + chunk
            ))
        }
    }
}
```

### 修改 `CodeReviewAgentExecutor.kt`（可选）

添加一个新的 `executeWithData` 方法：

```kotlin
suspend fun executeWithData(
    task: ReviewTask,
    codeContent: Map<String, String>,
    lintResults: Map<String, String>,
    onProgress: (String) -> Unit = {}
): CodeReviewResult {
    val promptRenderer = CodeReviewAgentPromptRenderer()
    val prompt = promptRenderer.renderAnalysisPrompt(
        reviewType = task.reviewType.name,
        filePaths = codeContent.keys.toList(),
        codeContent = codeContent,
        lintResults = lintResults,
        diffContext = "",
        language = "EN"
    )
    
    val response = llmService.sendPrompt(prompt)
    return CodeReviewResult(
        success = true,
        message = response,
        findings = parseFindings(response)
    )
}
```

## 测试计划

### 对比测试

1. **原 Prompt（Agent-Driven）**
   ```bash
   node dist/jsMain/typescript/index.js review -p .
   ```
   - 记录 token 消耗
   - 记录执行时间
   - 记录 tool call 次数

2. **新 Prompt（Data-Driven）** - 需要实现
   ```bash
   node dist/jsMain/typescript/index.js review -p . --use-analysis-prompt
   ```
   - 对比相同指标

### 预期结果

| 指标 | 原 Prompt | 新 Prompt | 改进 |
|------|----------|----------|------|
| Token 消耗 | ~15,000 | ~2,500 | -83% |
| 执行时间 | ~60s | ~10s | -83% |
| Tool Calls | 5-6 | 0 | -100% |
| 成功率 | 80% | 99% | +24% |

## 结论

### 问题根源
当前的 `CodeReviewAgentPromptRenderer` 是一个"大而全"的 prompt，试图让 Agent 同时完成数据收集和分析两个职责，导致：
1. 流程冗长
2. Token 浪费
3. 容易出错

### 推荐方案
✅ **拆分为两个专用 Prompt**
- `CodeReviewAgentTemplate`：保留原有功能，用于 CLI 和探索性场景
- `CodeReviewAnalysisTemplate`：**新增**，用于 UI 和 API 场景，数据预收集

### 下一步
1. ✅ 已实现：`CodeReviewAgentPromptRenderer` 添加 `renderAnalysisPrompt` 方法
2. ⏳ 待实现：修改 `CodeReviewViewModel.kt` 使用新 prompt
3. ⏳ 待实现：添加 CLI flag `--use-analysis-prompt` 用于测试
4. ⏳ 待测试：对比两种方案的效果

## 附录：完整测试日志

参见：`~/.autodev/logs/autodev-app.log`

关键片段：
```
16:21:00.668 - Executing tool: read-file (attempt 1) -> File path cannot be empty
16:21:04.603 - Executing tool: read-file (attempt 2) -> File path cannot be empty
16:21:09.491 - Executing tool: shell find -> Success
16:21:14.524 - Executing tool: shell cat -> Success
16:21:54.262 - No tool calls found, review complete
Total time: ~60 seconds
```

