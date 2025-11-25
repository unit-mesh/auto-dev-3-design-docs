import cc.unitmesh.devins.filesystem.DefaultFileSystem
import cc.unitmesh.devins.document.DocumentParserFactory

fun main() {
    val projectPath = "/Volumes/source/ai/autocrud"
    val fileSystem = DefaultFileSystem(projectPath)
    
    println("=== 测试文档搜索和过滤 ===")
    println("项目路径: $projectPath")
    println()
    
    // 使用与 DocumentReaderViewModel 相同的搜索模式
    val pattern = DocumentParserFactory.getSearchPattern()
    println("搜索模式: $pattern")
    println()
    
    println("开始搜索文档...")
    val documents = fileSystem.searchFiles(pattern, maxDepth = 20, maxResults = 1000)
    
    println("找到文档总数: ${documents.size}")
    println()
    
    // 分析结果
    val shouldBeIgnored = documents.filter { path ->
        path.contains(".intellijPlatform") ||
        path.contains("node_modules") ||
        path.contains("build/") ||
        path.contains(".gradle") ||
        path.contains(".idea") ||
        path.contains("bin/") ||
        path.contains("out/")
    }
    
    if (shouldBeIgnored.isNotEmpty()) {
        println("❌ 发现不应该被索引的文件 (${shouldBeIgnored.size} 个):")
        shouldBeIgnored.take(10).forEach { path ->
            println("  - $path")
        }
        if (shouldBeIgnored.size > 10) {
            println("  ... 还有 ${shouldBeIgnored.size - 10} 个")
        }
    } else {
        println("✓ 所有文件都是合法的文档文件")
    }
    println()
    
    // 按目录分组统计
    val byDirectory = documents.groupBy { path ->
        val parts = path.split("/")
        if (parts.size > 1) parts[0] else "root"
    }
    
    println("按顶层目录分组:")
    byDirectory.entries.sortedByDescending { it.value.size }.take(20).forEach { (dir, files) ->
        println("  $dir: ${files.size} 个文件")
    }
    println()
    
    // 按文件类型统计
    val byExtension = documents.groupBy { path ->
        path.substringAfterLast(".", "unknown")
    }
    
    println("按文件类型统计:")
    byExtension.entries.sortedByDescending { it.value.size }.forEach { (ext, files) ->
        println("  .$ext: ${files.size} 个文件")
    }
}

