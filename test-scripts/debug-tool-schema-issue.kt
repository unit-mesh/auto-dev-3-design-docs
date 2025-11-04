#!/usr/bin/env kotlin

/**
 * 调试脚本：测试 CodingAgent 工具 Schema 问题
 * 
 * 问题描述：
 * 在 Compose 的 JVM 和 Android 版本中，CodingAgent.execute() 调用 buildContext() 时，
 * getAllTools() 返回的工具列表缺少 ToolSchema 等信息，导致模型无法正确理解工具。
 * 
 * 测试目标：
 * 1. 验证 getAllTools() 返回的工具是否包含完整的 schema 信息
 * 2. 检查 formatToolListForAI() 生成的提示词是否正确
 * 3. 对比不同平台（JVM/Android vs JS/Wasm）的工具注册差异
 */

@file:DependsOn("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")

import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString

// 模拟测试数据
data class TestToolInfo(
    val name: String,
    val description: String,
    val parameterClass: String,
    val hasSchema: Boolean,
    val schemaDetails: String?
)

fun main() {
    println("🔍 调试 CodingAgent 工具 Schema 问题")
    println("=" * 50)
    
    // 测试场景 1: 检查工具注册状态
    testToolRegistration()
    
    // 测试场景 2: 验证工具 Schema 生成
    testToolSchemaGeneration()
    
    // 测试场景 3: 检查提示词格式
    testPromptGeneration()
    
    // 测试场景 4: 对比平台差异
    testPlatformDifferences()
}

fun testToolRegistration() {
    println("\n📋 测试场景 1: 工具注册状态检查")
    println("-" * 30)
    
    // 模拟 CodingAgent 的工具注册过程
    val expectedBuiltinTools = listOf(
        "read-file", "write-file", "grep", "glob", "shell"
    )
    
    val expectedSubAgents = listOf(
        "error-recovery", "log-summary", "codebase-investigator"
    )
    
    println("✅ 预期的内置工具:")
    expectedBuiltinTools.forEach { println("   - $it") }
    
    println("✅ 预期的子代理:")
    expectedSubAgents.forEach { println("   - $it") }
    
    // 检查点：验证工具是否正确注册
    println("\n🔍 检查点:")
    println("1. 验证 ToolRegistry.registerBuiltinTools() 是否被调用")
    println("2. 验证 SubAgent 是否同时注册到 MainAgent.tools 和 ToolRegistry")
    println("3. 验证 MCP 工具是否正确初始化和注册")
}

fun testToolSchemaGeneration() {
    println("\n🛠️ 测试场景 2: 工具 Schema 生成验证")
    println("-" * 30)
    
    // 模拟不同类型的工具 Schema
    val testTools = listOf(
        TestToolInfo(
            name = "read-file",
            description = "Read file content",
            parameterClass = "ReadFileParams",
            hasSchema = true,
            schemaDetails = """{"path": "string", "encoding": "string?"}"""
        ),
        TestToolInfo(
            name = "broken-tool",
            description = "Tool with missing schema",
            parameterClass = "Unit",
            hasSchema = false,
            schemaDetails = null
        ),
        TestToolInfo(
            name = "mcp-tool",
            description = "MCP adapter tool",
            parameterClass = "McpToolAdapter.Params",
            hasSchema = true,
            schemaDetails = """{"arguments": "string"}"""
        )
    )
    
    println("🔍 工具 Schema 分析:")
    testTools.forEach { tool ->
        println("📦 工具: ${tool.name}")
        println("   描述: ${tool.description}")
        println("   参数类: ${tool.parameterClass}")
        println("   有 Schema: ${if (tool.hasSchema) "✅" else "❌"}")
        if (tool.schemaDetails != null) {
            println("   Schema: ${tool.schemaDetails}")
        }
        println()
    }
    
    // 检查点：Schema 完整性验证
    println("🔍 检查点:")
    println("1. 所有工具是否都有有效的 getParameterClass() 返回值")
    println("2. ExecutableTool.description 是否为空")
    println("3. MCP 工具的 Schema 是否正确转换")
}

fun testPromptGeneration() {
    println("\n📝 测试场景 3: 提示词格式检查")
    println("-" * 30)
    
    // 模拟 formatToolListForAI 的输出
    val correctToolFormat = """
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
    """.trimIndent()
    
    val brokenToolFormat = """
<tool name="broken-tool">
  <description></description>
  <parameters>
    <type>Unit</type>
    <usage>/broken-tool [parameters]</usage>
  </parameters>
</tool>
    """.trimIndent()
    
    println("✅ 正确的工具格式:")
    println(correctToolFormat)
    println()
    
    println("❌ 有问题的工具格式:")
    println(brokenToolFormat)
    println()
    
    // 检查点：提示词质量验证
    println("🔍 检查点:")
    println("1. 工具描述是否为空或无意义")
    println("2. 参数类型是否为 'Unit' 或空字符串")
    println("3. 示例是否缺失或不正确")
    println("4. XML 格式是否正确")
}

fun testPlatformDifferences() {
    println("\n🌐 测试场景 4: 平台差异对比")
    println("-" * 30)
    
    // 模拟不同平台的工具可用性
    val platformTools = mapOf(
        "JVM" to listOf("read-file", "write-file", "grep", "glob", "shell", "error-recovery"),
        "Android" to listOf("read-file", "write-file", "grep", "glob", "shell", "error-recovery"),
        "JS" to listOf("read-file", "write-file", "grep", "glob", "error-recovery"),
        "Wasm" to listOf("read-file", "write-file", "grep", "glob", "error-recovery")
    )
    
    println("🔍 各平台工具可用性:")
    platformTools.forEach { (platform, tools) ->
        println("$platform: ${tools.joinToString(", ")}")
    }
    println()
    
    // 检查点：平台兼容性验证
    println("🔍 检查点:")
    println("1. Shell 工具在 JS/Wasm 平台是否正确禁用")
    println("2. 文件系统工具在所有平台是否一致")
    println("3. MCP 工具在不同平台的兼容性")
    println("4. SubAgent 在所有平台是否正常工作")
}

// 辅助函数
operator fun String.times(n: Int): String = this.repeat(n)
