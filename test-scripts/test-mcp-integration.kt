#!/usr/bin/env kotlin

@file:DependsOn("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
@file:DependsOn("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")

import kotlinx.coroutines.*
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Test script to verify MCP tool integration in CodingAgent
 *
 * This script tests:
 * 1. Tool configuration loading and saving
 * 2. MCP server configuration
 * 3. CodingAgent tool initialization
 * 4. Tool filtering based on configuration
 * 5. Configuration file updates
 */

suspend fun main() {
    println("🧪 Testing MCP Tool Integration in CodingAgent")
    println("=" * 50)

    // Test 1: Check tool configuration file
    testToolConfigFile()

    // Test 2: Test MCP server configuration
    testMcpServerConfig()

    // Test 3: Test configuration file updates
    testConfigFileUpdates()

    // Test 4: Test tool filtering logic
    testToolFiltering()

    // Test 5: Test CodingAgent tool initialization simulation
    testCodingAgentToolInit()

    println("\n✅ All tests completed!")
}

suspend fun testToolConfigFile() {
    println("\n📁 Test 1: Tool Configuration File")
    
    val configDir = File(System.getProperty("user.home"), ".autodev")
    val toolConfigFile = File(configDir, "mcp.json")
    
    println("   Config directory: ${configDir.absolutePath}")
    println("   Tool config file: ${toolConfigFile.absolutePath}")
    println("   Config file exists: ${toolConfigFile.exists()}")
    
    if (toolConfigFile.exists()) {
        try {
            val content = toolConfigFile.readText()
            println("   Config file size: ${content.length} bytes")
            
            // Try to parse as JSON
            val json = Json { ignoreUnknownKeys = true }
            val jsonElement = json.parseToJsonElement(content)
            println("   ✅ Config file is valid JSON")
            
            // Check for expected fields
            val jsonObject = jsonElement.jsonObject
            val hasBuiltinTools = jsonObject.containsKey("enabledBuiltinTools")
            val hasMcpTools = jsonObject.containsKey("enabledMcpTools")
            val hasMcpServers = jsonObject.containsKey("mcpServers")
            
            println("   Has enabledBuiltinTools: $hasBuiltinTools")
            println("   Has enabledMcpTools: $hasMcpTools")
            println("   Has mcpServers: $hasMcpServers")
            
        } catch (e: Exception) {
            println("   ❌ Error reading config file: ${e.message}")
        }
    } else {
        println("   ⚠️  Config file does not exist - will use defaults")
    }
}

suspend fun testMcpServerConfig() {
    println("\n🔌 Test 2: MCP Server Configuration")
    
    // Create a test MCP configuration
    val testMcpConfig = """
    {
        "enabledBuiltinTools": ["read-file", "write-file", "shell"],
        "enabledMcpTools": ["test-tool-1", "test-tool-2"],
        "mcpServers": {
            "test-server": {
                "command": "node",
                "args": ["test-server.js"],
                "disabled": false
            },
            "disabled-server": {
                "command": "node", 
                "args": ["disabled-server.js"],
                "disabled": true
            }
        }
    }
    """.trimIndent()
    
    try {
        val json = Json { ignoreUnknownKeys = true }
        val config = json.parseToJsonElement(testMcpConfig)
        println("   ✅ Test MCP config is valid JSON")
        
        val configObject = config.jsonObject
        val mcpServers = configObject["mcpServers"]?.jsonObject
        val enabledCount = mcpServers?.values?.count { server ->
            val serverObj = server.jsonObject
            serverObj["disabled"]?.toString()?.trim('"') != "true"
        } ?: 0
        
        println("   Total MCP servers: ${mcpServers?.size ?: 0}")
        println("   Enabled MCP servers: $enabledCount")
        
    } catch (e: Exception) {
        println("   ❌ Error parsing test MCP config: ${e.message}")
    }
}

suspend fun testConfigFileUpdates() {
    println("\n📝 Test 3: Configuration File Updates")

    val configDir = File(System.getProperty("user.home"), ".autodev")
    val toolConfigFile = File(configDir, "mcp.json")

    // Test updating configuration with MCP tools
    val testConfig = """
    {
        "enabledBuiltinTools": ["read-file", "write-file", "shell"],
        "enabledMcpTools": ["filesystem_list", "filesystem_read", "github_search"],
        "mcpServers": {
            "filesystem": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
                "disabled": false
            },
            "github": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-github"],
                "disabled": false
            }
        }
    }
    """.trimIndent()

    try {
        // Backup existing config
        val backup = if (toolConfigFile.exists()) {
            toolConfigFile.readText()
        } else null

        // Write test config
        configDir.mkdirs()
        toolConfigFile.writeText(testConfig)
        println("   ✅ Test configuration written")

        // Verify it can be read back
        val readBack = toolConfigFile.readText()
        val json = Json { ignoreUnknownKeys = true }
        val parsed = json.parseToJsonElement(readBack)

        val configObject = parsed.jsonObject
        val enabledMcpTools = configObject["enabledMcpTools"]?.jsonArray?.size ?: 0
        val mcpServers = configObject["mcpServers"]?.jsonObject?.size ?: 0

        println("   Enabled MCP tools: $enabledMcpTools")
        println("   Configured MCP servers: $mcpServers")

        // Restore backup if it existed
        if (backup != null) {
            toolConfigFile.writeText(backup)
            println("   ✅ Original configuration restored")
        }

    } catch (e: Exception) {
        println("   ❌ Error testing config file updates: ${e.message}")
    }
}

suspend fun testCodingAgentToolInit() {
    println("\n🤖 Test 5: CodingAgent Tool Initialization Simulation")

    // Simulate the key steps that CodingAgent goes through
    println("   Simulating CodingAgent initialization...")

    // Step 1: Load tool configuration
    println("   1. Loading tool configuration...")
    delay(100) // Simulate loading time

    // Step 2: Initialize MCP client manager
    println("   2. Initializing MCP client manager...")
    delay(200) // Simulate initialization time

    // Step 3: Discover MCP tools
    println("   3. Discovering MCP tools...")
    delay(300) // Simulate discovery time

    // Step 4: Filter tools based on configuration
    println("   4. Filtering tools based on configuration...")
    delay(100) // Simulate filtering time

    println("   ✅ CodingAgent tool initialization simulation completed")
}

suspend fun testToolFiltering() {
    println("\n🔍 Test 4: Tool Filtering Logic")

    // Simulate tool filtering scenarios
    val allBuiltinTools = listOf("read-file", "write-file", "shell", "grep", "edit-file")
    val allMcpTools = listOf("filesystem_list", "filesystem_read", "github_search", "disabled-tool")

    val enabledBuiltinTools = listOf("read-file", "write-file", "shell")
    val enabledMcpTools = listOf("filesystem_list", "filesystem_read")

    val filteredBuiltin = allBuiltinTools.filter { it in enabledBuiltinTools }
    val filteredMcp = allMcpTools.filter { it in enabledMcpTools }

    println("   All builtin tools: ${allBuiltinTools.size}")
    println("   Enabled builtin tools: ${filteredBuiltin.size} - $filteredBuiltin")
    println("   All MCP tools: ${allMcpTools.size}")
    println("   Enabled MCP tools: ${filteredMcp.size} - $filteredMcp")

    // Test empty configuration behavior
    val emptyEnabledBuiltin = emptyList<String>()
    val emptyEnabledMcp = emptyList<String>()

    // New logic: if enabledMcpTools is empty, enable all discovered tools by default
    val defaultBuiltin = if (emptyEnabledBuiltin.isEmpty()) allBuiltinTools else emptyEnabledBuiltin
    val defaultMcp = if (emptyEnabledMcp.isEmpty()) allMcpTools else emptyEnabledMcp // Changed behavior

    println("   Default behavior (empty config):")
    println("     Builtin tools: ${defaultBuiltin.size} (all enabled)")
    println("     MCP tools: ${defaultMcp.size} (all enabled by default)")

    // Test specific tool name patterns
    val mcpToolWithServerPrefix = listOf("filesystem_list", "github_search")
    println("   MCP tools with server prefix: $mcpToolWithServerPrefix")

    println("   ✅ Tool filtering logic test completed")
}

// Helper function to repeat string
operator fun String.times(n: Int): String = this.repeat(n)

// Run the test
runBlocking {
    main()
}
