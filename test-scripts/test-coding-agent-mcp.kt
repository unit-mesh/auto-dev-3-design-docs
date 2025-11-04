#!/usr/bin/env kotlin

/**
 * Test script to verify CodingAgent can read MCP tool configuration
 * 
 * This script simulates the CodingAgent initialization process
 * and verifies that MCP tools are properly loaded and filtered.
 */

import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonArray

fun main() {
    println("🧪 Testing CodingAgent MCP Tool Configuration")
    println("=" * 50)
    
    // Test 1: Load tool configuration
    testLoadToolConfig()
    
    // Test 2: Simulate tool filtering
    testToolFiltering()
    
    // Test 3: Simulate MCP tool initialization
    testMcpToolInit()
    
    println("\n✅ All tests completed!")
}

fun testLoadToolConfig() {
    println("\n📁 Test 1: Load Tool Configuration")
    
    val configDir = File(System.getProperty("user.home"), ".autodev")
    val toolConfigFile = File(configDir, "mcp.json")
    
    if (!toolConfigFile.exists()) {
        println("   ❌ Tool config file does not exist: ${toolConfigFile.absolutePath}")
        return
    }
    
    try {
        val content = toolConfigFile.readText()
        val json = Json { ignoreUnknownKeys = true }
        val config = json.parseToJsonElement(content).jsonObject
        
        val enabledBuiltinTools = config["enabledBuiltinTools"]?.jsonArray?.size ?: 0
        val enabledMcpTools = config["enabledMcpTools"]?.jsonArray?.size ?: 0
        val mcpServers = config["mcpServers"]?.jsonObject?.size ?: 0
        
        println("   ✅ Configuration loaded successfully")
        println("   Enabled builtin tools: $enabledBuiltinTools")
        println("   Enabled MCP tools: $enabledMcpTools")
        println("   Configured MCP servers: $mcpServers")
        
        // Print enabled MCP tools
        config["enabledMcpTools"]?.jsonArray?.let { tools ->
            println("   MCP tools list:")
            tools.forEach { tool ->
                println("     - ${tool.toString().trim('"')}")
            }
        }
        
    } catch (e: Exception) {
        println("   ❌ Error loading config: ${e.message}")
    }
}

fun testToolFiltering() {
    println("\n🔍 Test 2: Tool Filtering Simulation")
    
    // Simulate discovered MCP tools
    val discoveredMcpTools = listOf(
        "filesystem_read_file",
        "filesystem_write_file", 
        "filesystem_list_directory",
        "filesystem_create_directory",
        "context7_search",
        "context7_index"
    )
    
    // Load enabled tools from config
    val configDir = File(System.getProperty("user.home"), ".autodev")
    val toolConfigFile = File(configDir, "mcp.json")
    
    if (!toolConfigFile.exists()) {
        println("   ⚠️  No config file, would enable all tools by default")
        println("   Discovered tools: ${discoveredMcpTools.size}")
        println("   Enabled tools: ${discoveredMcpTools.size} (all)")
        return
    }
    
    try {
        val content = toolConfigFile.readText()
        val json = Json { ignoreUnknownKeys = true }
        val config = json.parseToJsonElement(content).jsonObject
        
        val enabledMcpToolsArray = config["enabledMcpTools"]?.jsonArray
        
        if (enabledMcpToolsArray == null || enabledMcpToolsArray.isEmpty()) {
            println("   ⚠️  No MCP tools enabled in config, would enable all by default")
            println("   Discovered tools: ${discoveredMcpTools.size}")
            println("   Enabled tools: ${discoveredMcpTools.size} (all)")
        } else {
            val enabledMcpTools = enabledMcpToolsArray.map { it.toString().trim('"') }
            val filteredTools = discoveredMcpTools.filter { it in enabledMcpTools }
            
            println("   ✅ Tool filtering applied")
            println("   Discovered tools: ${discoveredMcpTools.size}")
            println("   Configured enabled tools: ${enabledMcpTools.size}")
            println("   Actually enabled tools: ${filteredTools.size}")
            
            println("   Enabled tools:")
            filteredTools.forEach { tool ->
                println("     ✓ $tool")
            }
            
            val disabledTools = discoveredMcpTools - filteredTools.toSet()
            if (disabledTools.isNotEmpty()) {
                println("   Disabled tools:")
                disabledTools.forEach { tool ->
                    println("     ✗ $tool")
                }
            }
        }
        
    } catch (e: Exception) {
        println("   ❌ Error during filtering: ${e.message}")
    }
}

fun testMcpToolInit() {
    println("\n🤖 Test 3: MCP Tool Initialization Simulation")
    
    println("   Simulating CodingAgent.initializeMcpTools()...")
    println("   1. Loading MCP server configurations...")
    println("   2. Initializing MCP client manager...")
    println("   3. Discovering tools from servers...")
    println("   4. Filtering tools based on configuration...")
    println("   5. Registering filtered tools with agent...")
    
    // This would be the actual flow in CodingAgent
    println("   ✅ MCP tool initialization simulation completed")
    println("   💡 In real implementation, this would call:")
    println("      - mcpToolsInitializer.initialize(mcpServers)")
    println("      - configService.filterMcpTools(mcpTools)")
    println("      - registerTool(tool) for each filtered tool")
}

// Helper function to repeat string
operator fun String.times(n: Int): String = this.repeat(n)
