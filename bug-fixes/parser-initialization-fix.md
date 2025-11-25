# Bug Fix: Document Parser Not Initialized

## 问题描述

用户报告即使存在 `TikaDocumentParser.kt`，应用仍无法解析 PDF、Word、PPT 等文档，错误信息如下：

```
ERROR: No parser available for: mpp-core/src/jvmTest/resources/word-sample.docx
ERROR: No parser available for: mpp-core/src/jvmTest/resources/sample2.pdf
ERROR: No parser available for: mpp-core/src/jvmTest/resources/sample.pptx
ERROR: No parser available for: mpp-core/src/jvmTest/resources/sample.ppt
ERROR: No parser available for: mpp-core/src/jvmTest/resources/word-sample.doc
```

## 根本原因

### 1. 缺少初始化调用

`DocumentReaderViewModel` 从未调用 `DocumentRegistry.initializePlatformParsers()`，导致平台特定的解析器未注册。

### 2. 解析器注册机制

Kotlin Multiplatform 项目使用 `expect`/`actual` 模式来支持平台特定的解析器：

```kotlin
// CommonMain: DocumentRegistry.kt
expect fun platformInitialize()

// JvmMain: DocumentRegistry.jvm.kt
actual fun platformInitialize() {
    // Register Tika parser for DOCX, PLAIN_TEXT
    // Register PdfDocumentParser for PDF
    // Register JsoupDocumentParser for HTML
}
```

如果不调用 `initializePlatformParsers()`，这些解析器永远不会被注册到 `DocumentParserFactory`。

### 3. 文件位置

- **Common 接口**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/document/DocumentRegistry.kt`
- **JVM 实现**: `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/DocumentRegistry.jvm.kt`
- **解析器**:
  - `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/TikaDocumentParser.kt`
  - `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/PdfDocumentParser.kt`
  - `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/JsoupDocumentParser.kt`

## 解决方案

### 修改文件

**`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderViewModel.kt`**

在 `init` 块的开始添加初始化调用：

```kotlin
init {
    // Initialize platform-specific parsers (Tika on JVM, etc.)
    DocumentRegistry.initializePlatformParsers()
    
    loadDocuments()
    initializeLLMService()
    // 不自动索引，等待用户手动触发
}
```

### 代码对比

**Before:**
```kotlin
init {
    loadDocuments()
    initializeLLMService()
    // 不自动索引，等待用户手动触发
}
```

**After:**
```kotlin
init {
    // Initialize platform-specific parsers (Tika on JVM, etc.)
    DocumentRegistry.initializePlatformParsers()
    
    loadDocuments()
    initializeLLMService()
    // 不自动索引，等待用户手动触发
}
```

## 技术细节

### 解析器注册流程

1. **ViewModel 初始化**
   ```kotlin
   DocumentRegistry.initializePlatformParsers()
   ```

2. **调用平台特定实现** (JVM)
   ```kotlin
   actual fun platformInitialize() {
       DocumentParserFactory.registerParser(DocumentFormatType.DOCX) { 
           TikaDocumentParser() 
       }
       DocumentParserFactory.registerParser(DocumentFormatType.PDF) { 
           PdfDocumentParser() 
       }
       DocumentParserFactory.registerParser(DocumentFormatType.HTML) { 
           JsoupDocumentParser() 
       }
   }
   ```

3. **解析器可用**
   ```kotlin
   val parser = DocumentParserFactory.createParserForFile("sample.docx")
   // Returns: TikaDocumentParser instance
   ```

### 为什么需要延迟初始化？

1. **平台差异**: 不同平台有不同的解析器实现
   - JVM: Tika, PDFBox, Jsoup
   - JS/WASM: 可能使用不同的库或纯 JS 实现

2. **依赖管理**: JVM 特定的库（如 Apache Tika）只在 JVM 平台可用

3. **性能优化**: 只在需要时初始化平台特定的解析器

## 验证

### 测试步骤

1. 启动应用
2. 打开 Document Reader
3. 尝试打开以下文件：
   - `.docx` 文件
   - `.pdf` 文件
   - `.pptx` 文件
   - `.html` 文件

### 预期结果

- 不再出现 "No parser available" 错误
- 文档内容正确解析并显示
- 解析后的内容显示在 DocumentViewerPane 中

### 日志输出

成功初始化后应该看到：

```
Initializing JVM document parsers (Tika)
Registered TikaDocumentParser for DOCX
Registered TikaDocumentParser for PLAIN_TEXT
Registered PdfDocumentParser for PDF
Registered JsoupDocumentParser for HTML
JVM parsers initialized: 3 formats supported (Tika + Jsoup)
```

## 相关问题

### Issue 1: 测试资源文件被索引

同时也修复了测试数据文件被错误索引的问题，通过在 `.gitignore` 中添加：

```
**/testData/
**/test-data/
**/__tests__/
```

这些目录中的测试文件（如 `mpp-core/src/jvmTest/resources/`）不会被索引为实际文档。

## 经验教训

1. **显式初始化**: 在 KMP 项目中，平台特定的初始化必须显式调用
2. **日志重要性**: 添加初始化日志有助于诊断问题
3. **文档完整性**: 应该在架构文档中说明初始化流程

## 提交信息

```
fix: Initialize document parsers in DocumentReaderViewModel

- Add DocumentRegistry.initializePlatformParsers() call in init block
- Fixes "No parser available" errors for PDF, Word, PPT files
- Ensures Tika, PDFBox, and Jsoup parsers are registered on JVM
```

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderViewModel.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/document/DocumentRegistry.kt`
- `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/DocumentRegistry.jvm.kt`
- `.gitignore`

## 日期

2025-11-25

