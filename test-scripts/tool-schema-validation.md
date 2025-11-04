# CodingAgent 工具 Schema 问题调试指南

## 问题描述

在 Compose 的 JVM 和 Android 版本中，`CodingAgent.execute()` 调用 `buildContext()` 时，`getAllTools()` 返回的工具列表缺少 `ToolSchema` 等信息，导致模型无法正确理解工具。

## 问题根因分析

### 1. 工具注册问题
- `CodingAgent` 继承自 `MainAgent`，使用 `tools: MutableList<ExecutableTool<*, *>>` 存储工具
- 内置工具通过 `ToolRegistry.registerBuiltinTools()` 注册
- SubAgent 需要同时注册到 `MainAgent.tools` 和 `ToolRegistry`
- MCP 工具通过 `McpToolsInitializer` 动态注册

### 2. Schema 生成问题
- `CodingAgentContext.formatToolListForAI()` 依赖 `ExecutableTool.getParameterClass()`
- 某些工具可能返回 `"Unit"` 或空字符串作为参数类型
- MCP 工具的 Schema 转换可能不完整

### 3. 提示词格式问题
- 生成的 XML 格式可能缺少关键信息
- 工具描述可能为空
- 示例可能缺失或不正确

## 调试步骤

### 步骤 1: 验证工具注册

```kotlin
// 在 CodingAgent 中添加调试代码
private suspend fun buildContext(task: AgentTask): CodingAgentContext {
    // 确保 MCP 工具已初始化
    if (!mcpToolsInitialized && mcpServers != null) {
        initializeMcpTools(mcpServers)
        mcpToolsInitialized = true
    }

    val allTools = getAllTools()
    
    // 🔍 调试：打印工具注册状态
    println("🔍 调试：发现 ${allTools.size} 个工具")
    allTools.forEach { tool ->
        println("  - 名称: ${tool.name}")
        println("    描述: '${tool.description}'")
        println("    参数类: '${tool.getParameterClass()}'")
        println("    类型: ${tool::class.simpleName}")
        println()
    }

    return CodingAgentContext.fromTask(task, toolList = allTools)
}
```

### 步骤 2: 检查 Schema 生成

```kotlin
// 在 CodingAgentContext.formatToolListForAI() 中添加调试
private fun formatToolListForAI(toolList: List<ExecutableTool<*, *>>): String {
    println("🔍 调试：格式化 ${toolList.size} 个工具为 AI 提示词")
    
    return toolList.joinToString("\n\n") { tool ->
        val result = buildString {
            // Tool header with name and description
            appendLine("<tool name=\"${tool.name}\">")
            
            // 🔍 调试：检查描述是否为空
            if (tool.description.isBlank()) {
                println("⚠️  警告：工具 '${tool.name}' 的描述为空")
            }
            appendLine("  <description>${tool.description}</description>")

            // Parameter schema information
            val paramClass = tool.getParameterClass()
            
            // 🔍 调试：检查参数类型
            if (paramClass.isBlank() || paramClass == "Unit") {
                println("⚠️  警告：工具 '${tool.name}' 的参数类型为 '$paramClass'")
            }
            
            if (paramClass.isNotEmpty() && paramClass != "Unit") {
                appendLine("  <parameters>")
                appendLine("    <type>$paramClass</type>")
                appendLine("    <usage>/${tool.name} [parameters]</usage>")
                appendLine("  </parameters>")
            }

            // Add example if available (for built-in tools)
            val example = generateToolExample(tool)
            if (example.isNotEmpty()) {
                appendLine("  <example>")
                appendLine("    $example")
                appendLine("  </example>")
            } else {
                println("⚠️  警告：工具 '${tool.name}' 缺少使用示例")
            }

            append("</tool>")
        }
        
        println("✅ 生成工具 '${tool.name}' 的提示词")
        result
    }
}
```

### 步骤 3: 验证最终提示词

```kotlin
// 在 CodingAgentPromptRenderer.render() 中添加调试
fun render(context: CodingAgentContext, language: String = "EN"): String {
    val template = if (language == "ZH") CodingAgentTemplate.ZH else CodingAgentTemplate.EN
    val variableTable = context.toVariableTable()
    
    // 🔍 调试：检查工具列表变量
    val toolListVar = variableTable.getVariable("toolList")
    println("🔍 调试：工具列表变量长度: ${toolListVar?.value?.toString()?.length ?: 0}")
    
    if (toolListVar?.value?.toString()?.contains("<tool name=") != true) {
        println("❌ 错误：工具列表变量不包含有效的工具定义")
    }
    
    val result = TemplateCompiler.compile(template, variableTable)
    
    // 🔍 调试：检查最终提示词
    val toolSectionStart = result.indexOf("## Available Tools")
    val toolSectionEnd = result.indexOf("## Task Execution Guidelines")
    
    if (toolSectionStart > 0 && toolSectionEnd > toolSectionStart) {
        val toolSection = result.substring(toolSectionStart, toolSectionEnd)
        val toolCount = toolSection.split("<tool name=").size - 1
        println("🔍 调试：最终提示词包含 $toolCount 个工具定义")
        
        if (toolCount == 0) {
            println("❌ 错误：最终提示词不包含任何工具定义")
        }
    }
    
    return result
}
```

## 预期的正确输出

### 正确的工具注册输出
```
🔍 调试：发现 8 个工具
  - 名称: read-file
    描述: 'Read file content from the project'
    参数类: 'ReadFileParams'
    类型: ReadFileTool

  - 名称: write-file
    描述: 'Write content to a file in the project'
    参数类: 'WriteFileParams'
    类型: WriteFileTool

  - 名称: error-recovery
    描述: 'Recover from errors and suggest solutions'
    参数类: 'ErrorRecoveryParams'
    类型: ErrorRecoveryAgent
```

### 正确的提示词格式
```xml
<tool name="read-file">
  <description>Read file content from the project</description>
  <parameters>
    <type>ReadFileParams</type>
    <usage>/read-file [parameters]</usage>
  </parameters>
  <example>
    /read-file path="src/main.kt"
  </example>
</tool>
```

## 常见问题和解决方案

### 问题 1: 工具描述为空
**症状**: `<description></description>`
**原因**: `ExecutableTool.description` 返回空字符串
**解决**: 确保所有工具实现都提供有意义的描述

### 问题 2: 参数类型为 Unit
**症状**: `<type>Unit</type>`
**原因**: `getParameterClass()` 返回 "Unit"
**解决**: 为工具定义正确的参数类型

### 问题 3: 缺少使用示例
**症状**: 没有 `<example>` 标签
**原因**: `generateToolExample()` 没有为该工具生成示例
**解决**: 在 `generateToolExample()` 中添加该工具的示例

### 问题 4: MCP 工具 Schema 不完整
**症状**: MCP 工具的参数信息缺失
**原因**: `McpToolAdapter` 的 Schema 转换不完整
**解决**: 改进 MCP 工具的 Schema 映射逻辑
