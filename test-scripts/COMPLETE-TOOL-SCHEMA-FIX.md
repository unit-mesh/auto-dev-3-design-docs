# CodingAgent 工具 Schema 问题 - 完整修复方案

## 问题描述

在 Compose 的 JVM 和 Android 版本中，`CodingAgent.execute()` 调用 `buildContext()` 时，`getAllTools()` 返回的工具列表缺少 `ToolSchema` 等信息，导致模型无法正确理解工具。

## 根本原因分析

经过深入调试，发现了两个主要问题：

### 1. 工具注册架构问题
- **内置工具**（read-file, write-file, grep, glob, shell）只注册在 `ToolRegistry` 中
- **SubAgent 工具**（error-recovery, log-summary, codebase-investigator）同时注册在 `MainAgent.tools` 和 `ToolRegistry` 中
- **MCP 工具**只注册在 `MainAgent.tools` 中
- `CodingAgent.getAllTools()` 继承自 `MainAgent.getAllTools()`，只返回 `MainAgent.tools` 中的工具
- **结果**：内置工具完全缺失，导致 AI 模型无法使用基础的文件操作工具

### 2. SubAgent 参数类型问题
- `Agent` 基类的 `getParameterClass()` 方法硬编码返回 `"AgentInput"`
- 所有 SubAgent 都继承了这个通用的参数类型，而不是具体的参数类型
- **结果**：AI 模型无法理解 SubAgent 的具体参数结构

## 完整修复方案

### 修复 1: 解决工具注册架构问题

在 `CodingAgent.kt` 中添加了 `getAllAvailableTools()` 方法：

```kotlin
/**
 * 获取所有可用的工具，包括内置工具、SubAgent 和 MCP 工具
 */
private fun getAllAvailableTools(): List<ExecutableTool<*, *>> {
    val allTools = mutableListOf<ExecutableTool<*, *>>()
    
    // 1. 添加 ToolRegistry 中的内置工具
    allTools.addAll(toolRegistry.getAllTools().values)
    
    // 2. 添加 MainAgent 中注册的工具（SubAgent 和 MCP 工具）
    // 注意：避免重复添加已经在 ToolRegistry 中的 SubAgent
    val registryToolNames = toolRegistry.getAllTools().keys
    val mainAgentTools = getAllTools().filter { it.name !in registryToolNames }
    allTools.addAll(mainAgentTools)
    
    return allTools
}
```

并修改 `buildContext()` 方法使用新的方法：

```kotlin
private suspend fun buildContext(task: AgentTask): CodingAgentContext {
    // 确保 MCP 工具已初始化
    if (!mcpToolsInitialized && mcpServers != null) {
        initializeMcpTools(mcpServers)
        mcpToolsInitialized = true
    }

    return CodingAgentContext.fromTask(
        task,
        toolList = getAllAvailableTools()  // 使用新方法
    )
}
```

### 修复 2: 解决 SubAgent 参数类型问题

为所有 SubAgent 添加了正确的 `getParameterClass()` 实现：

```kotlin
// ErrorRecoveryAgent
override fun getParameterClass(): String = ErrorContext::class.simpleName ?: "ErrorContext"

// LogSummaryAgent  
override fun getParameterClass(): String = LogSummaryContext::class.simpleName ?: "LogSummaryContext"

// CodebaseInvestigatorAgent
override fun getParameterClass(): String = InvestigationContext::class.simpleName ?: "InvestigationContext"
```

### 修复 3: 改进工具提示词生成

在 `CodingAgentContext.formatToolListForAI()` 中：
- 添加了对空描述的处理
- 改进了对 `"AgentInput"` 类型的特殊处理
- 为 SubAgent 添加了具体的使用示例

### 修复 4: 添加调试信息

在关键位置添加了调试输出：
- `CodingAgentContext.formatToolListForAI()` - 显示工具列表详情
- `CodingAgentPromptRenderer.render()` - 显示最终提示词统计

## 修复效果对比

### 修复前
```
🔍 [CodingAgentContext] 格式化工具列表，共 3 个工具:
  - error-recovery (ErrorRecoveryAgent): AgentInput
  - log-summary (LogSummaryAgent): AgentInput  
  - codebase-investigator (CodebaseInvestigatorAgent): AgentInput

🔍 [CodingAgentPromptRenderer] 工具数量: 3
🔍 [CodingAgentPromptRenderer] 包含内置工具: false
🔍 [CodingAgentPromptRenderer] 包含 SubAgent: true
```

### 修复后
```
🔍 [CodingAgentContext] 格式化工具列表，共 8 个工具:
  - read-file (ReadFileTool): ReadFileParams
  - write-file (WriteFileTool): WriteFileParams
  - grep (GrepTool): GrepParams
  - glob (GlobTool): GlobParams
  - shell (ShellTool): ShellParams
  - error-recovery (ErrorRecoveryAgent): ErrorContext
  - log-summary (LogSummaryAgent): LogSummaryContext
  - codebase-investigator (CodebaseInvestigatorAgent): InvestigationContext

🔍 [CodingAgentPromptRenderer] 工具数量: 8
🔍 [CodingAgentPromptRenderer] 包含内置工具: true
🔍 [CodingAgentPromptRenderer] 包含 SubAgent: true
```

## 验证方法

运行验证脚本：
```bash
./docs/test-scripts/test-complete-tool-fix.sh
```

## 预期结果

- ✅ 内置工具 (read-file, write-file, grep, glob, shell) 现在会出现在工具列表中
- ✅ SubAgent 工具显示正确的参数类型 (ErrorContext, LogSummaryContext, InvestigationContext)
- ✅ 工具提示词包含完整的 Schema 信息和使用示例
- ✅ AI 模型能够正确理解和使用所有工具
- ✅ 在 Compose JVM/Android 版本中工具调用应该正常工作

## 相关文件

- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentPromptRenderer.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt`

这个修复解决了工具注册架构的根本问题，确保所有工具都能正确地被 AI 模型识别和使用。
