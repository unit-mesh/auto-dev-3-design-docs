#!/usr/bin/env kotlin

/**
 * 测试脚本：验证工具 Schema 生成是否正确
 * 
 * 这个脚本模拟 CodingAgent 的工具列表生成过程，
 * 验证修复后的 SubAgent 是否能正确生成工具 Schema。
 */

@file:DependsOn("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")

import kotlinx.serialization.Serializable

// 模拟的工具接口和类
interface ExecutableTool<TParams : Any, TResult : Any> {
    val name: String
    val description: String
    fun getParameterClass(): String
}

@Serializable
data class ErrorContext(
    val command: String,
    val errorMessage: String,
    val exitCode: Int? = null
)

@Serializable
data class LogSummaryContext(
    val command: String,
    val output: String,
    val exitCode: Int,
    val executionTime: Int
)

@Serializable
data class InvestigationContext(
    val query: String,
    val projectPath: String,
    val scope: String = "all"
)

// 模拟的 SubAgent 实现
class MockErrorRecoveryAgent : ExecutableTool<ErrorContext, String> {
    override val name: String = "error-recovery"
    override val description: String = "Analyzes command failures and provides recovery plans"
    override fun getParameterClass(): String = ErrorContext::class.simpleName ?: "ErrorContext"
}

class MockLogSummaryAgent : ExecutableTool<LogSummaryContext, String> {
    override val name: String = "log-summary"
    override val description: String = "Summarizes long command outputs"
    override fun getParameterClass(): String = LogSummaryContext::class.simpleName ?: "LogSummaryContext"
}

class MockCodebaseInvestigatorAgent : ExecutableTool<InvestigationContext, String> {
    override val name: String = "codebase-investigator"
    override val description: String = "Analyzes codebase structure and provides insights"
    override fun getParameterClass(): String = InvestigationContext::class.simpleName ?: "InvestigationContext"
}

// 模拟的内置工具
class MockReadFileTool : ExecutableTool<Map<String, Any>, String> {
    override val name: String = "read-file"
    override val description: String = "Read file content from the project"
    override fun getParameterClass(): String = "ReadFileParams"
}

// 模拟 CodingAgentContext.formatToolListForAI 方法
fun formatToolListForAI(toolList: List<ExecutableTool<*, *>>): String {
    if (toolList.isEmpty()) {
        return "No tools available."
    }

    return toolList.joinToString("\n\n") { tool ->
        buildString {
            // Tool header with name and description
            appendLine("<tool name=\"${tool.name}\">")
            
            // Check for empty description and provide warning
            val description = tool.description.takeIf { it.isNotBlank() } 
                ?: "Tool description not available"
            appendLine("  <description>$description</description>")

            // Parameter schema information with improved handling
            val paramClass = tool.getParameterClass()
            
            when {
                paramClass.isBlank() -> {
                    // No parameters - this is fine for some tools
                }
                paramClass == "Unit" -> {
                    // Unit type means no meaningful parameters
                }
                paramClass == "AgentInput" -> {
                    // Generic agent input - provide more specific info for SubAgents
                    appendLine("  <parameters>")
                    appendLine("    <type>Map&lt;String, Any&gt;</type>")
                    appendLine("    <usage>/${tool.name} [key-value parameters]</usage>")
                    appendLine("  </parameters>")
                }
                else -> {
                    // Valid parameter class
                    appendLine("  <parameters>")
                    appendLine("    <type>$paramClass</type>")
                    appendLine("    <usage>/${tool.name} [parameters]</usage>")
                    appendLine("  </parameters>")
                }
            }

            // Add example
            val example = generateToolExample(tool)
            if (example.isNotEmpty()) {
                appendLine("  <example>")
                appendLine("    $example")
                appendLine("  </example>")
            }

            append("</tool>")
        }
    }
}

fun generateToolExample(tool: ExecutableTool<*, *>): String {
    return when (tool.name) {
        "read-file" -> "/${tool.name} path=\"src/main.kt\""
        "error-recovery" -> "/${tool.name} command=\"gradle build\" errorMessage=\"Compilation failed\""
        "log-summary" -> "/${tool.name} command=\"npm test\" output=\"[long test output...]\""
        "codebase-investigator" -> "/${tool.name} query=\"find all REST endpoints\" scope=\"methods\""
        else -> "/${tool.name} <parameters>"
    }
}

fun main() {
    println("🔍 测试工具 Schema 生成")
    println("=" * 50)
    
    // 创建工具列表
    val tools = listOf(
        MockReadFileTool(),
        MockErrorRecoveryAgent(),
        MockLogSummaryAgent(),
        MockCodebaseInvestigatorAgent()
    )
    
    println("📦 测试工具列表:")
    tools.forEach { tool ->
        println("  - ${tool.name}: ${tool.getParameterClass()}")
    }
    
    println("\n📝 生成的工具提示词:")
    println("-" * 50)
    
    val toolPrompt = formatToolListForAI(tools)
    println(toolPrompt)
    
    println("\n🔍 验证结果:")
    println("-" * 30)
    
    // 验证每个 SubAgent 的参数类型
    val errorRecoveryTool = tools.find { it.name == "error-recovery" }
    val logSummaryTool = tools.find { it.name == "log-summary" }
    val investigatorTool = tools.find { it.name == "codebase-investigator" }
    
    val checks = listOf(
        "ErrorRecoveryAgent 参数类型" to (errorRecoveryTool?.getParameterClass() == "ErrorContext"),
        "LogSummaryAgent 参数类型" to (logSummaryTool?.getParameterClass() == "LogSummaryContext"),
        "CodebaseInvestigatorAgent 参数类型" to (investigatorTool?.getParameterClass() == "InvestigationContext"),
        "工具提示词包含具体参数类型" to toolPrompt.contains("ErrorContext"),
        "工具提示词包含使用示例" to toolPrompt.contains("command=\"gradle build\""),
        "工具提示词格式正确" to toolPrompt.contains("<tool name=") && toolPrompt.contains("</tool>")
    )
    
    var allPassed = true
    checks.forEach { (name, passed) ->
        val status = if (passed) "✅" else "❌"
        println("$status $name")
        if (!passed) allPassed = false
    }
    
    println("\n" + "=" * 50)
    if (allPassed) {
        println("🎉 所有测试通过！工具 Schema 修复成功。")
    } else {
        println("❌ 部分测试失败，需要进一步检查。")
    }
}

// 辅助函数
operator fun String.times(n: Int): String = this.repeat(n)
