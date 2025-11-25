# Document Viewer Optimization

## 优化概述

针对 DocumentReaderPage 的两个关键优化：

### 1. 修复测试数据被索引问题

**问题**: `testData` 目录中的测试文件（如 `IfExpression.txt`）被错误地索引到文档列表中

**解决方案**: 在 `.gitignore` 中添加测试数据目录的排除规则

```
# Test data directories
**/testData/
**/test-data/
**/__tests__/
```

**影响**: `GitIgnoreParser` 会正确过滤这些目录，不再将测试文件索引为文档

### 2. 支持解析后内容的显示

**问题**: 对于 PDF、Word、Excel 等二进制格式，原始内容无法直接显示，需要使用 Tika 解析后的纯文本内容

**解决方案**: 

#### 2.1 ViewModel 层优化

在 `DocumentReaderViewModel` 中添加 `parsedContent` 状态：

```kotlin
// 原始内容（用于 Markdown、纯文本）
var documentContent by mutableStateOf<String?>(null)
    private set

// 解析后的内容（用于 PDF、Word 等，由 Tika 提取）
var parsedContent by mutableStateOf<String?>(null)
    private set
```

在 `selectDocument` 方法中，解析文档后提取纯文本内容：

```kotlin
// Parse the document
val parsedDoc = parser.parse(doc, content)

// Get parsed content (for PDF, Word, etc. - Tika extracts text)
// For Markdown, this will be null (we use original content)
parsedContent = parser.getDocumentContent()
```

#### 2.2 View 层优化

**DocumentReaderPage** 传递两种内容：

```kotlin
DocumentViewerPane(
    document = viewModel.selectedDocument,
    rawContent = viewModel.documentContent,      // 原始内容
    parsedContent = viewModel.parsedContent,      // 解析后的内容
    // ...
)
```

**DocumentViewerPane** 智能选择显示内容：

```kotlin
// Determine which content to display based on document type
val displayContent = when {
    parsedContent != null -> parsedContent  // Use parsed content for PDF/Word/etc.
    rawContent != null -> rawContent        // Use raw content for Markdown/Text
    else -> null
}
```

#### 2.3 用户体验优化

添加 `DocumentFormatIndicator` 组件，当显示解析后的内容时，会显示一个提示条：

```
ℹ️ 已解析的文本内容
   从 PDF 文件提取的纯文本
```

这让用户明确知道他们看到的是提取的文本，而不是原始格式的预览。

## 技术细节

### 支持的文档格式

| 格式 | 解析器 | 内容来源 | 显示方式 |
|-----|--------|---------|---------|
| Markdown (.md) | MarkdownDocumentParser | 原始内容 | 直接显示 |
| 纯文本 (.txt) | PlainTextDocumentParser | 原始内容 | 直接显示 |
| PDF (.pdf) | TikaDocumentParser | Tika 提取的文本 | 显示解析后内容 + 提示条 |
| Word (.doc, .docx) | TikaDocumentParser | Tika 提取的文本 | 显示解析后内容 + 提示条 |
| Excel (.xls, .xlsx) | TikaDocumentParser | Tika 提取的文本 | 显示解析后内容 + 提示条 |
| HTML (.html) | TikaDocumentParser | Tika 提取的文本 | 显示解析后内容 + 提示条 |

### TikaDocumentParser 工作原理

1. **接收原始内容**: 以字节形式读取文件
2. **自动检测格式**: Apache Tika 自动识别文档格式
3. **提取纯文本**: 从结构化文档中提取可读文本
4. **构建文档块**: 将文本分段为 `DocumentChunk`
5. **提取 TOC**: 尝试识别标题和章节结构

示例代码：

```kotlin
val parser = AutoDetectParser()
val handler = BodyContentHandler(-1)
val metadata = Metadata()

// Parse document
parser.parse(inputStream, handler, metadata, context)

// Extract text
val extractedText = handler.toString().trim()
```

### 内容选择逻辑

```kotlin
// In DocumentViewerPane
val displayContent = when {
    parsedContent != null -> parsedContent  // Priority 1: Parsed content
    rawContent != null -> rawContent        // Priority 2: Raw content
    else -> null                            // No content available
}
```

**优先级规则**:
1. 如果有 `parsedContent`（PDF/Word 等），优先使用
2. 否则使用 `rawContent`（Markdown/纯文本）
3. 都没有则显示错误信息

## 文件变更清单

### Modified Files

1. **`.gitignore`**
   - 添加 `**/testData/`, `**/test-data/`, `**/__tests__/` 排除规则

2. **`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderViewModel.kt`**
   - 添加 `parsedContent` 状态
   - 修改 `selectDocument()` 方法，提取解析后的内容

3. **`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderPage.kt`**
   - 更新 `DocumentViewerPane` 调用，传递 `rawContent` 和 `parsedContent`

4. **`mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentViewerPane.kt`**
   - 修改参数签名：`rawContent` 和 `parsedContent` 替代 `content`
   - 添加内容选择逻辑
   - 新增 `DocumentFormatIndicator` 组件
   - 添加 `DocumentFormatType` 导入

## 测试建议

### 手动测试步骤

1. **测试 Markdown 文档**
   - 打开一个 `.md` 文件
   - 验证内容正常显示
   - 不应该显示"已解析的文本内容"提示条

2. **测试 PDF 文档**
   - 打开一个 `.pdf` 文件
   - 验证提取的文本内容正常显示
   - 应该显示"从 PDF 文件提取的纯文本"提示条

3. **测试 Word 文档**
   - 打开一个 `.docx` 文件
   - 验证提取的文本内容正常显示
   - 应该显示"从 Word 文档提取的纯文本"提示条

4. **测试文件过滤**
   - 索引文档后，检查文档列表
   - 确认 `testData` 目录下的文件未被索引

### 验证点

- [ ] 测试数据文件不再出现在文档列表中
- [ ] Markdown 文档正常显示原始内容
- [ ] PDF 文档显示解析后的文本内容
- [ ] Word 文档显示解析后的文本内容
- [ ] 解析后的文档显示格式提示条
- [ ] TOC（目录）正确提取和显示
- [ ] 搜索功能在解析后的内容中正常工作

## 性能考虑

1. **解析性能**: Tika 解析大文档可能需要时间，已在 ViewModel 中使用协程异步处理
2. **内存使用**: 同时保存原始内容和解析后的内容会增加内存使用，但对于大多数文档是可接受的
3. **缓存策略**: 解析后的内容存储在 ViewModel 中，切换文档时会重新解析

## 关键问题修复：解析器未注册

### 问题症状

即使 `TikaDocumentParser` 存在，应用仍报错：
```
ERROR: No parser available for: word-sample.docx
ERROR: No parser available for: sample2.pdf
ERROR: No parser available for: sample.pptx
```

### 根本原因

`DocumentRegistry.initializePlatformParsers()` 从未被调用，导致：
1. `TikaDocumentParser` 没有注册到 `DocumentParserFactory`
2. `PdfDocumentParser` 没有注册
3. `JsoupDocumentParser` 没有注册

### 解决方案

在 `DocumentReaderViewModel` 的 `init` 块中添加初始化调用：

```kotlin
init {
    // Initialize platform-specific parsers (Tika on JVM, etc.)
    DocumentRegistry.initializePlatformParsers()
    
    loadDocuments()
    initializeLLMService()
}
```

### 平台初始化机制

`DocumentRegistry.jvm.kt` 中的 `platformInitialize()` 负责注册 JVM 平台的解析器：

```kotlin
actual fun platformInitialize() {
    // Register Tika parser for multiple formats
    val tikaFormats = listOf(
        DocumentFormatType.DOCX,  // Handles .doc, .docx, .ppt, .pptx
        DocumentFormatType.PLAIN_TEXT
    )
    
    tikaFormats.forEach { format ->
        DocumentParserFactory.registerParser(format) { TikaDocumentParser() }
    }

    // Register PDFBox parser for PDF
    DocumentParserFactory.registerParser(DocumentFormatType.PDF) { PdfDocumentParser() }
    
    // Register Jsoup parser for HTML
    DocumentParserFactory.registerParser(DocumentFormatType.HTML) { JsoupDocumentParser() }
}
```

### 支持的文档格式映射

`DocumentParserFactory.detectFormat()` 将文件扩展名映射到格式类型：

| 扩展名 | DocumentFormatType | 解析器 |
|--------|-------------------|--------|
| .md, .markdown | MARKDOWN | MarkdownDocumentParser |
| .pdf | PDF | PdfDocumentParser |
| .doc, .docx | DOCX | TikaDocumentParser |
| .ppt, .pptx | DOCX | TikaDocumentParser |
| .txt | PLAIN_TEXT | TikaDocumentParser |
| .html, .htm | HTML | JsoupDocumentParser |

**注意**: PPT/PPTX 也映射到 `DOCX` 类型，因为 Tika 可以处理所有 Office 格式。

## 未来改进

1. **缓存优化**: 考虑将解析后的内容缓存到数据库，避免重复解析
2. **进度指示**: 为大文档添加解析进度显示
3. **格式保留**: 探索保留更多格式信息（如表格、图片说明等）
4. **预览支持**: 对于某些格式，提供原始格式预览选项
5. **格式类型细化**: 考虑为 PPT/PPTX 添加独立的 `DocumentFormatType.PPTX`

