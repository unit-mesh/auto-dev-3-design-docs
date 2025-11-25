import cc.unitmesh.agent.tool.gitignore.GitIgnorePatternMatcher

/**
 * 测试 GitIgnore 模式匹配
 */
fun main() {
    println("=== 测试 GitIgnore 模式匹配 ===\n")
    
    // 测试用例
    val testCases = listOf(
        ".intellijPlatform" to listOf(
            ".intellijPlatform/file.xml",
            ".intellijPlatform/localPlatformArtifacts/bundledPlugin.xml",
            "path/.intellijPlatform/file.xml",
            "intellijPlatform/file.xml"  // 不应该匹配
        ),
        "docs" to listOf(
            "docs/README.md",
            "docs/guide.md",
            "path/docs/file.md",
            "mydocs/file.md"  // 不应该匹配
        ),
        "build/" to listOf(
            "build/output.txt",
            "build/reports/test.html",
            "mybuild/file.txt"  // 不应该匹配
        ),
        "*.log" to listOf(
            "app.log",
            "path/to/error.log",
            "log.txt"  // 不应该匹配
        )
    )
    
    testCases.forEach { (pattern, paths) ->
        println("模式: '$pattern'")
        val (regex, isNegated) = GitIgnorePatternMatcher.patternToRegex(pattern)
        println("正则: $regex")
        println("是否取反: $isNegated")
        println()
        
        paths.forEach { path ->
            val normalized = GitIgnorePatternMatcher.normalizePath(path)
            val matches = regex.matches(normalized)
            val symbol = if (matches) "✓" else "✗"
            println("  $symbol $path (normalized: $normalized)")
        }
        println()
    }
}

