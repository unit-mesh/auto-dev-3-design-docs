/**
 * RemoteAgentCli - Kotlin CLI for testing RemoteAgentClient
 *
 * This is the Kotlin/JVM equivalent of the TypeScript version in mpp-ui/src/jsMain/typescript/index.tsx
 * Used to compare and validate both implementations.
 *
 * Usage:
 *   kotlinc RemoteAgentCli.kt -include-runtime -d RemoteAgentCli.jar -cp ../../mpp-ui/build/libs/mpp-ui-jvm.jar
 *   kotlin -cp RemoteAgentCli.jar:../../mpp-ui/build/libs/mpp-ui-jvm.jar RemoteAgentCliKt \
 *     --task "编写 BlogService 测试" \
 *     --project-id https://github.com/unit-mesh/untitled \
 *     --server http://localhost:8080
 */

package cc.unitmesh.devins.cli.test

import cc.unitmesh.devins.ui.remote.*
import kotlinx.coroutines.runBlocking
import kotlin.system.exitProcess

/**
 * ANSI Color codes for terminal output
 */
object AnsiColors {
    const val RESET = "\u001B[0m"
    const val BLACK = "\u001B[30m"
    const val RED = "\u001B[31m"
    const val GREEN = "\u001B[32m"
    const val YELLOW = "\u001B[33m"
    const val BLUE = "\u001B[34m"
    const val PURPLE = "\u001B[35m"
    const val CYAN = "\u001B[36m"
    const val WHITE = "\u001B[37m"
    const val GRAY = "\u001B[90m"
    
    const val BOLD = "\u001B[1m"
    const val DIM = "\u001B[2m"
}

/**
 * Simple semantic color helpers matching TypeScript version
 */
object SemanticColors {
    fun success(text: String) = "${AnsiColors.GREEN}$text${AnsiColors.RESET}"
    fun error(text: String) = "${AnsiColors.RED}$text${AnsiColors.RESET}"
    fun warning(text: String) = "${AnsiColors.YELLOW}$text${AnsiColors.RESET}"
    fun info(text: String) = "${AnsiColors.CYAN}$text${AnsiColors.RESET}"
    fun accent(text: String) = "${AnsiColors.BLUE}$text${AnsiColors.RESET}"
    fun muted(text: String) = "${AnsiColors.GRAY}$text${AnsiColors.RESET}"
    fun bold(text: String) = "${AnsiColors.BOLD}$text${AnsiColors.RESET}"
}

/**
 * Renderer for remote agent events - matches ServerRenderer.ts functionality
 */
class RemoteAgentRenderer {
    private var isCloning = false
    private var lastCloneProgress = 0
    private var hasStartedLLMOutput = false
    private val llmBuffer = StringBuilder()
    
    fun renderEvent(event: RemoteAgentEvent) {
        when (event) {
            is RemoteAgentEvent.CloneProgress -> renderCloneProgress(event.stage, event.progress)
            is RemoteAgentEvent.CloneLog -> renderCloneLog(event.message, event.isError)
            is RemoteAgentEvent.Iteration -> renderIteration(event.current, event.max)
            is RemoteAgentEvent.LLMChunk -> renderLLMChunk(event.chunk)
            is RemoteAgentEvent.ToolCall -> renderToolCall(event.toolName, event.params)
            is RemoteAgentEvent.ToolResult -> renderToolResult(event.toolName, event.success, event.output)
            is RemoteAgentEvent.Error -> renderError(event.message)
            is RemoteAgentEvent.Complete -> renderComplete(event.success, event.message, event.iterations, event.steps, event.edits)
        }
    }
    
    private fun renderCloneProgress(stage: String, progress: Int?) {
        if (!isCloning) {
            println()
            println(SemanticColors.accent("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
            println(SemanticColors.info("📦 Cloning repository..."))
            println()
            isCloning = true
        }
        
        if (progress != null && progress != lastCloneProgress) {
            val barLength = 30
            val filledLength = (progress * barLength / 100).coerceIn(0, barLength)
            val bar = "█".repeat(filledLength) + "░".repeat(barLength - filledLength)
            
            print("\r${SemanticColors.accent("[$bar]")} $progress% - $stage")
            
            if (progress == 100) {
                println()
                println(SemanticColors.success("✓ Clone completed"))
                println(SemanticColors.accent("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
                println()
            }
            
            lastCloneProgress = progress
        }
    }
    
    private fun renderCloneLog(message: String, isError: Boolean) {
        // Filter out noisy messages
        val noisyPatterns = listOf(
            Regex("^Executing:"),
            Regex("^remote:"),
            Regex("^Receiving objects:"),
            Regex("^Resolving deltas:"),
            Regex("^Unpacking objects:")
        )
        
        if (noisyPatterns.any { it.containsMatchIn(message) }) {
            return
        }
        
        // Show important messages
        if (message.contains("✓") || message.contains("Repository ready") || isError) {
            if (isError) {
                println(SemanticColors.error("  ✗ $message"))
            } else {
                println(SemanticColors.muted("  $message"))
            }
        }
    }
    
    private fun renderIteration(current: Int, max: Int) {
        // Flush any buffered LLM output
        if (llmBuffer.isNotEmpty()) {
            println()
            llmBuffer.clear()
        }
        
        hasStartedLLMOutput = false
        
        // Don't show iteration headers - match TypeScript reference format
    }
    
    private fun renderLLMChunk(chunk: String) {
        // Show thinking emoji before first chunk
        if (!hasStartedLLMOutput) {
            print(SemanticColors.muted("💭 "))
            hasStartedLLMOutput = true
        }
        
        // Output chunk directly (simplified - no devin block filtering in this test version)
        print(chunk)
    }
    
    private fun renderToolCall(toolName: String, params: String) {
        // Flush any buffered LLM output
        if (llmBuffer.isNotEmpty()) {
            println()
            llmBuffer.clear()
        }
        
        if (hasStartedLLMOutput) {
            println()
            hasStartedLLMOutput = false
        }
        
        val toolInfo = formatToolCallDisplay(toolName, params)
        println("● ${toolInfo.name}" + SemanticColors.muted(" - ${toolInfo.description}"))
        
        if (toolInfo.details != null) {
            println("  ⎿ " + SemanticColors.muted(toolInfo.details))
        }
    }
    
    private data class ToolDisplayInfo(
        val name: String,
        val description: String,
        val details: String? = null
    )
    
    private fun formatToolCallDisplay(toolName: String, params: String): ToolDisplayInfo {
        return try {
            // Simple parsing - in real implementation would use kotlinx.serialization
            when (toolName) {
                "read-file", "read_file" -> {
                    val path = extractParam(params, "path") ?: "unknown"
                    ToolDisplayInfo(
                        name = "$path - read file",
                        description = "file reader",
                        details = "Reading file: $path"
                    )
                }
                "write-file", "write_file", "edit-file", "edit_file" -> {
                    val path = extractParam(params, "path") ?: "unknown"
                    val mode = extractParam(params, "mode") ?: "update"
                    ToolDisplayInfo(
                        name = "$path - edit file",
                        description = "file editor",
                        details = "${if (mode == "create") "Creating" else "Updating"} file: $path"
                    )
                }
                "shell" -> {
                    val command = extractParam(params, "command") ?: extractParam(params, "cmd") ?: "unknown"
                    ToolDisplayInfo(
                        name = "Shell command",
                        description = "command executor",
                        details = "Running: $command"
                    )
                }
                "glob" -> {
                    val pattern = extractParam(params, "pattern") ?: "unknown"
                    ToolDisplayInfo(
                        name = "File search",
                        description = "pattern matcher",
                        details = "Searching for files matching pattern: $pattern"
                    )
                }
                "grep" -> {
                    val pattern = extractParam(params, "pattern") ?: "unknown"
                    val path = extractParam(params, "path")
                    ToolDisplayInfo(
                        name = "Text search",
                        description = "content finder",
                        details = "Searching for pattern: $pattern${if (path != null) " in $path" else ""}"
                    )
                }
                else -> ToolDisplayInfo(
                    name = toolName,
                    description = "tool",
                    details = params
                )
            }
        } catch (e: Exception) {
            ToolDisplayInfo(
                name = toolName,
                description = "tool"
            )
        }
    }
    
    private fun extractParam(params: String, key: String): String? {
        // Simple JSON-like extraction (not production-ready)
        val regex = """"$key"\s*:\s*"([^"]*)"""".toRegex()
        return regex.find(params)?.groupValues?.get(1)
    }
    
    private fun renderToolResult(toolName: String, success: Boolean, output: String?) {
        if (success && output != null) {
            val summary = generateToolSummary(toolName, output)
            println("  ⎿ " + SemanticColors.success(summary))
            
            // For read-file, show formatted code content
            if (toolName == "read-file" || toolName == "read_file") {
                displayCodeContent(output)
            }
        } else if (!success && output != null) {
            println("  ⎿ " + SemanticColors.error("Error: ${output.take(200)}"))
        }
    }
    
    private fun generateToolSummary(toolName: String, output: String): String {
        return when (toolName) {
            "glob" -> {
                val fileMatches = Regex("Found (\\d+) files").find(output)
                if (fileMatches != null) {
                    "Found ${fileMatches.groupValues[1]} files"
                } else {
                    val files = output.split('\n').filter { it.trim().isNotEmpty() }
                    "Found ${files.size} files"
                }
            }
            "read-file", "read_file" -> {
                val lines = output.split('\n').size
                "Read $lines lines"
            }
            "write-file", "write_file", "edit-file", "edit_file" -> {
                when {
                    output.contains("created") -> "File created"
                    output.contains("updated") || output.contains("overwrote") || output.contains("Successfully") -> 
                        "File updated successfully"
                    else -> "File operation completed"
                }
            }
            "shell" -> "Command executed successfully"
            "grep" -> {
                val matches = output.split('\n').filter { it.trim().isNotEmpty() }.size
                "Found $matches matches"
            }
            else -> "Operation completed"
        }
    }
    
    private fun displayCodeContent(content: String) {
        val lines = content.split('\n')
        val maxLines = 15
        val displayLines = lines.take(maxLines)
        
        println("────────────────────────────────────────────────────────────")
        
        displayLines.forEachIndexed { index, line ->
            val lineNumber = (index + 1).toString().padStart(3, ' ')
            println(SemanticColors.muted("$lineNumber │ ") + line)
        }
        
        if (lines.size > maxLines) {
            println(SemanticColors.muted("... (${lines.size - maxLines} more lines)"))
        }
        
        println("────────────────────────────────────────────────────────────")
    }
    
    private fun renderError(message: String) {
        println()
        println(SemanticColors.error("❌ Error: $message"))
        println()
    }
    
    private fun renderComplete(
        success: Boolean,
        message: String,
        iterations: Int,
        steps: List<AgentStepInfo>,
        edits: List<AgentEditInfo>
    ) {
        // Flush any buffered LLM output
        if (llmBuffer.isNotEmpty()) {
            println()
            llmBuffer.clear()
        }
        
        println()
        
        if (success) {
            println(SemanticColors.success("✅ Task completed successfully"))
        } else {
            println(SemanticColors.error("❌ Task failed"))
        }
        
        if (message.trim().isNotEmpty()) {
            println(SemanticColors.muted(message))
        }
        
        println(SemanticColors.muted("Task completed after $iterations iterations"))
        
        if (edits.isNotEmpty()) {
            println()
            println(SemanticColors.accent("📝 File Changes:"))
            edits.forEach { edit ->
                val icon = when (edit.operation) {
                    "CREATE" -> "➕"
                    "DELETE" -> "➖"
                    else -> "✏️"
                }
                println(SemanticColors.info("  $icon ${edit.file}"))
            }
        }
        
        println()
    }
}

/**
 * Command line argument parser
 */
data class CliArgs(
    val serverUrl: String = "http://localhost:8080",
    val projectId: String,
    val task: String,
    val quiet: Boolean = false,
    val useServerConfig: Boolean = false,
    val provider: String? = null,
    val model: String? = null,
    val apiKey: String? = null,
    val baseUrl: String? = null
)

fun parseArgs(args: Array<String>): CliArgs? {
    var serverUrl = "http://localhost:8080"
    var projectId: String? = null
    var task: String? = null
    var quiet = false
    var useServerConfig = false
    var provider: String? = null
    var model: String? = null
    var apiKey: String? = null
    var baseUrl: String? = null
    
    var i = 0
    while (i < args.size) {
        when (args[i]) {
            "-s", "--server", "--server-url" -> {
                if (i + 1 < args.size) {
                    serverUrl = args[++i]
                }
            }
            "-p", "--project-id" -> {
                if (i + 1 < args.size) {
                    projectId = args[++i]
                }
            }
            "-t", "--task" -> {
                if (i + 1 < args.size) {
                    task = args[++i]
                }
            }
            "-q", "--quiet" -> quiet = true
            "--use-server-config" -> useServerConfig = true
            "--provider" -> {
                if (i + 1 < args.size) {
                    provider = args[++i]
                }
            }
            "--model" -> {
                if (i + 1 < args.size) {
                    model = args[++i]
                }
            }
            "--api-key" -> {
                if (i + 1 < args.size) {
                    apiKey = args[++i]
                }
            }
            "--base-url" -> {
                if (i + 1 < args.size) {
                    baseUrl = args[++i]
                }
            }
            "--help", "-h" -> {
                printHelp()
                return null
            }
        }
        i++
    }
    
    if (projectId == null || task == null) {
        System.err.println(SemanticColors.error("Error: --project-id and --task are required"))
        printHelp()
        return null
    }
    
    return CliArgs(
        serverUrl = serverUrl,
        projectId = projectId,
        task = task,
        quiet = quiet,
        useServerConfig = useServerConfig,
        provider = provider,
        model = model,
        apiKey = apiKey,
        baseUrl = baseUrl
    )
}

fun printHelp() {
    println("""
        ${SemanticColors.bold("RemoteAgentCli")} - Kotlin CLI for testing RemoteAgentClient
        
        ${SemanticColors.accent("USAGE:")}
          kotlin RemoteAgentCliKt [OPTIONS]
        
        ${SemanticColors.accent("OPTIONS:")}
          -s, --server-url <url>     Server URL (default: http://localhost:8080)
          -p, --project-id <id>      Project ID or Git URL (required)
          -t, --task <task>          Development task to execute (required)
          -q, --quiet                Quiet mode - minimal output
          --use-server-config        Use server's LLM config instead of client's
          --provider <provider>      LLM provider (e.g., deepseek, openai)
          --model <model>            Model name (e.g., deepseek-chat)
          --api-key <key>            API key for LLM provider
          --base-url <url>           Base URL for LLM provider
          -h, --help                 Show this help message
        
        ${SemanticColors.accent("EXAMPLES:")}
          # Connect to local server with Git URL
          kotlin RemoteAgentCliKt \\
            --task "编写 BlogService 测试" \\
            --project-id https://github.com/unit-mesh/untitled \\
            --server http://localhost:8080
          
          # Use custom LLM config
          kotlin RemoteAgentCliKt \\
            --task "Fix bug in UserController" \\
            --project-id my-project \\
            --provider deepseek \\
            --model deepseek-chat \\
            --api-key sk-xxx
    """.trimIndent())
}

/**
 * Main entry point
 */
fun main(args: Array<String>) = runBlocking {
    val cliArgs = parseArgs(args) ?: return@runBlocking
    
    try {
        val client = RemoteAgentClient(cliArgs.serverUrl)
        
        // Health check
        if (!cliArgs.quiet) {
            println("${SemanticColors.info("🔍")} Connecting to server: ${cliArgs.serverUrl}")
            println()
            
            try {
                val health = client.healthCheck()
                println(SemanticColors.success("✅ Server is ${health.status}"))
                println()
            } catch (e: Exception) {
                System.err.println(SemanticColors.error("❌ Server health check failed: ${e.message}"))
                System.err.println("Please make sure mpp-server is running.")
                exitProcess(1)
            }
        }
        
        // Prepare LLM config
        val llmConfig = if (!cliArgs.useServerConfig) {
            // Use client-provided config
            val provider = cliArgs.provider ?: System.getenv("AUTODEV_PROVIDER") ?: "deepseek"
            val model = cliArgs.model ?: System.getenv("AUTODEV_MODEL") ?: "deepseek-chat"
            val apiKey = cliArgs.apiKey ?: System.getenv("AUTODEV_API_KEY") ?: ""
            val baseUrl = cliArgs.baseUrl ?: System.getenv("AUTODEV_BASE_URL")
            
            if (apiKey.isEmpty() && !cliArgs.useServerConfig) {
                System.err.println(SemanticColors.warning("⚠️  Warning: No API key provided. Using server config."))
                null
            } else {
                LLMConfig(
                    provider = provider,
                    modelName = model,
                    apiKey = apiKey,
                    baseUrl = baseUrl
                )
            }
        } else {
            null
        }
        
        // Show configuration
        if (!cliArgs.quiet) {
            println(SemanticColors.bold("🚀 AutoDev Remote Coding Agent"))
            println()
            println("${SemanticColors.info("🌐")} Server: ${cliArgs.serverUrl}")
            println("${SemanticColors.info("📦")} Project: ${cliArgs.projectId}")
            
            if (llmConfig != null) {
                println("${SemanticColors.info("📦")} Provider: ${llmConfig.provider} (from client)")
                println("${SemanticColors.info("🤖")} Model: ${llmConfig.modelName}")
            } else {
                println("${SemanticColors.info("📦")} Using server's LLM configuration")
            }
            println()
        }
        
        // Create renderer
        val renderer = RemoteAgentRenderer()
        
        // Smart detection: if projectId looks like a URL, use it as gitUrl
        val isGitUrl = cliArgs.projectId.startsWith("http://") ||
                       cliArgs.projectId.startsWith("https://") ||
                       cliArgs.projectId.startsWith("git@")
        
        val request = if (isGitUrl) {
            RemoteAgentRequest(
                projectId = cliArgs.projectId.split("/").last(),
                task = cliArgs.task,
                llmConfig = llmConfig,
                gitUrl = cliArgs.projectId
            )
        } else {
            RemoteAgentRequest(
                projectId = cliArgs.projectId,
                task = cliArgs.task,
                llmConfig = llmConfig
            )
        }
        
        // Execute with streaming
        try {
            client.executeStream(request).collect { event ->
                renderer.renderEvent(event)
                
                // Exit on complete
                if (event is RemoteAgentEvent.Complete) {
                    client.close()
                    exitProcess(if (event.success) 0 else 1)
                }
            }
        } catch (e: Exception) {
            System.err.println(SemanticColors.error("❌ Streaming error: ${e.message}"))
            e.printStackTrace()
            client.close()
            exitProcess(1)
        }
        
    } catch (e: Exception) {
        System.err.println(SemanticColors.error("❌ Fatal error: ${e.message}"))
        e.printStackTrace()
        exitProcess(1)
    }
}

