package cc.unitmesh.agent.tool.examples

import cc.unitmesh.agent.tool.*

/**
 * Example showing how to migrate from string-based tool names to ToolType sealed class
 */
class ToolTypeMigrationExample {
    
    /**
     * OLD WAY - Using string constants (deprecated)
     */
    @Deprecated("Use ToolType sealed class instead")
    fun oldWayExample(toolName: String) {
        when (toolName) {
            ToolNames.READ_FILE -> println("📄 Reading file")
            ToolNames.WRITE_FILE -> println("✏️ Writing file")
            ToolNames.SHELL -> println("💻 Executing shell command")
            ToolNames.GLOB -> println("🌐 Finding files")
            ToolNames.GREP -> println("🔍 Searching content")
            else -> println("🔧 Unknown tool")
        }
    }
    
    /**
     * NEW WAY - Using ToolType sealed class (recommended)
     */
    fun newWayExample(toolType: ToolType) {
        when (toolType) {
            ToolType.ReadFile -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.WriteFile -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.Shell -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.Glob -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.Grep -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.ErrorRecovery -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.LogSummary -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            ToolType.CodebaseInvestigator -> println("${toolType.tuiEmoji} ${toolType.displayName}")
            else -> println("${toolType.tuiEmoji} ${toolType.displayName}")
        }
    }
    
    /**
     * MIGRATION HELPER - Convert string to ToolType
     */
    fun migrationHelper(toolName: String) {
        val toolType = toolName.toToolType()
        if (toolType != null) {
            newWayExample(toolType)
        } else {
            println("⚠️ Unknown tool: $toolName")
        }
    }
    
    /**
     * CATEGORY-BASED OPERATIONS
     */
    fun categoryExample() {
        // Get all file system tools
        val fileSystemTools = ToolType.byCategory(ToolCategory.FileSystem)
        println("📁 File System Tools:")
        fileSystemTools.forEach { tool ->
            println("  ${tool.tuiEmoji} ${tool.displayName} (${tool.name})")
        }
        
        // Get all execution tools
        val executionTools = ToolType.byCategory(ToolCategory.Execution)
        println("\n⚡ Execution Tools:")
        executionTools.forEach { tool ->
            println("  ${tool.tuiEmoji} ${tool.displayName} (${tool.name})")
        }
        
        // Get all sub-agent tools
        val subAgentTools = ToolType.byCategory(ToolCategory.SubAgent)
        println("\n🤖 Sub-Agent Tools:")
        subAgentTools.forEach { tool ->
            println("  ${tool.tuiEmoji} ${tool.displayName} (${tool.name})")
        }
    }
    
    /**
     * UI RENDERING EXAMPLE
     */
    fun renderingExample(toolType: ToolType, isCompose: Boolean = false) {
        if (isCompose) {
            // For Compose UI
            println("Compose Icon: ${toolType.composeIcon}")
            println("Display Name: ${toolType.displayName}")
        } else {
            // For Terminal UI
            println("${toolType.tuiEmoji} ${toolType.displayName}")
        }
        
        println("Category: ${toolType.category.displayName} ${toolType.category.tuiEmoji}")
        println("Internal Name: ${toolType.name}")
    }
    
    /**
     * VALIDATION EXAMPLE
     */
    fun validationExample(toolName: String): Boolean {
        // New way - type-safe
        val toolType = toolName.toToolType()
        if (toolType != null) {
            println("✅ Valid tool: ${toolType.displayName}")
            
            // Check capabilities
            when (toolType.category) {
                ToolCategory.FileSystem -> println("  📁 Requires file system access")
                ToolCategory.Execution -> println("  ⚡ Executes external commands")
                ToolCategory.SubAgent -> println("  🤖 Specialized sub-agent")
                else -> println("  ℹ️ General tool")
            }
            
            return true
        } else {
            println("❌ Invalid tool: $toolName")
            return false
        }
    }
    
    /**
     * BACKWARD COMPATIBILITY EXAMPLE
     */
    fun backwardCompatibilityExample() {
        // Old constants still work but are deprecated
        @Suppress("DEPRECATION")
        val oldTools = ToolNames.ALL_TOOLS
        
        println("🔄 Migrating ${oldTools.size} tools...")
        
        oldTools.forEach { toolName ->
            val toolType = toolName.toToolType()
            if (toolType != null) {
                println("  ✅ $toolName → ${toolType.displayName}")
            } else {
                println("  ❌ $toolName → NOT FOUND")
            }
        }
    }
}

/**
 * Usage examples
 */
fun main() {
    val example = ToolTypeMigrationExample()
    
    println("=== ToolType Migration Example ===\n")
    
    // Show category-based operations
    example.categoryExample()
    
    println("\n=== Rendering Examples ===")
    example.renderingExample(ToolType.ReadFile, isCompose = false)
    println()
    example.renderingExample(ToolType.Shell, isCompose = true)
    
    println("\n=== Validation Examples ===")
    example.validationExample("read-file")
    example.validationExample("invalid-tool")
    
    println("\n=== Migration Helper ===")
    example.migrationHelper("write-file")
    example.migrationHelper("unknown-tool")
    
    println("\n=== Backward Compatibility ===")
    example.backwardCompatibilityExample()
}
