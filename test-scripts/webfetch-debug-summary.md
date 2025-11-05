# WebFetch Tool Debug Summary

## 问题描述

用户在调试 Kotlin 版本的 WebFetch 工具时遇到以下问题：

**原始输入**：`读取 https://raw.githubusercontent.com/unit-mesh/auto-dev/master/README.md 并总结`

**错误信息**：
```
[Tool Call]: web-fetch
Description: tool execution
Parameters: prompt="https://raw.githubusercontent.com/unit-mesh/auto-dev/master/README.md"

[Tool Result]: web-fetch - FAILED
Summary: Failed
Output: Error: Tool execution failed: Error(s) in prompt URLs:
- Unsupported protocol in URL: "README文件的内容：https://raw.githubusercontent.com/unit-mesh/auto-dev/master/README.md". Only http and https are supported.
Error Type: UNKNOWN
```

## 根本原因分析

通过代码分析发现了两个主要问题：

### 1. 参数名错误 (ToolCallParser)

**位置**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/parser/ToolCallParser.kt:253-257`

**问题**: `parseSimpleParameter` 方法中，WebFetch 工具被归类为"其他工具"，使用了默认参数名 `"content"`，但 WebFetch 工具实际需要的参数名是 `"prompt"`。

**原代码**:
```kotlin
val defaultParamName = when (toolName) {
    ToolType.ReadFile.name -> "path"
    ToolType.Glob.name, ToolType.Grep.name -> "pattern"
    else -> "content"  // ❌ WebFetch 被错误地使用了 "content"
}
```

### 2. URL解析问题 (UrlParser)

**位置**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/impl/WebFetchTool.kt:77-104`

**问题**: `parsePrompt` 方法使用空格分割文本，当 LLM 生成包含中文描述和 URL 混合的文本时（如"README文件的内容：https://..."），整个字符串被当作一个 token，导致 URL 解析失败。

## 解决方案

### 修复 1: 参数名修复

**文件**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/parser/ToolCallParser.kt`

```kotlin
val defaultParamName = when (toolName) {
    ToolType.ReadFile.name -> "path"
    ToolType.Glob.name, ToolType.Grep.name -> "pattern"
    ToolType.WebFetch.name -> "prompt"  // ✅ 添加 WebFetch 专用参数名
    else -> "content"
}
```

### 修复 2: URL解析改进

**文件**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/impl/WebFetchTool.kt`

**改进点**:
1. 使用正则表达式 `https?://[^\s\u4e00-\u9fff]+` 直接从文本中提取 URL
2. 支持从中文混合文本中提取 URL
3. 自动清理 URL 末尾的标点符号
4. 保留原有的 token 分割作为后备方案

```kotlin
fun parsePrompt(text: String): ParsedUrls {
    val validUrls = mutableListOf<String>()
    val errors = mutableListOf<String>()

    // 使用正则表达式查找 URL，即使它们嵌入在其他文本中
    val urlPattern = Regex("""https?://[^\s\u4e00-\u9fff]+""")
    val matches = urlPattern.findAll(text)
    
    for (match in matches) {
        val potentialUrl = match.value
        try {
            // 清理 URL（移除可能不属于 URL 的尾随标点符号）
            val cleanUrl = potentialUrl.trimEnd('.', ',', ')', ']', '}', '!', '?', ';', ':')
            val url = normalizeUrl(cleanUrl)
            
            if (url.startsWith("http://") || url.startsWith("https://")) {
                validUrls.add(url)
            } else {
                errors.add("Unsupported protocol in URL: \"$cleanUrl\". Only http and https are supported.")
            }
        } catch (e: Exception) {
            errors.add("Malformed URL detected: \"$potentialUrl\".")
        }
    }
    
    // 后备方案：如果正则表达式没有找到 URL，尝试原有的 token 分割方法
    // ... (保留原有逻辑)
}
```

## 测试验证

运行测试脚本 `docs/test-scripts/test-webfetch-fixes.sh` 验证修复效果：

**测试结果**:
- ✅ 参数名修复成功：工具调用使用正确的 `prompt` 参数
- ✅ URL 解析成功：从中文混合文本中正确提取 URL
- ✅ 工具执行正常：没有出现之前的解析错误

**测试输出示例**:
```
● web-fetch - tool
  ⎿ prompt="Please fetch and summarize the content from https://httpbin.org/json..."
```

## 影响范围

这些修复解决了：
1. WebFetch 工具参数名不匹配的问题
2. 从包含中文描述的文本中提取 URL 的问题
3. 更好地处理嵌入在描述性文本中的 URL

修复后，WebFetch 工具可以正确处理各种格式的输入，包括中英文混合的提示文本。
