# 自动索引与全局搜索功能

## 概述

本文档描述了 Document Reader 的自动索引和全局源代码搜索功能的实现。

## 功能特性

### 1. 自动索引 (Auto-Indexing)

**问题**：之前的实现需要用户手动点击"索引文档"按钮，如果用户直接进入 Document Chat 会遇到"Document not found in index: null"错误。

**解决方案**：在 `DocumentReaderViewModel` 初始化时自动开始索引文档。

#### 实现位置
- **文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderViewModel.kt`
- **改动**:

```kotlin
init {
    // ... 现有初始化代码 ...
    
    // 自动开始索引文档（延迟一点以确保文档加载完成）
    scope.launch {
        kotlinx.coroutines.delay(500) // 等待 UI 初始化
        if (documents.isNotEmpty()) {
            println("🚀 Auto-indexing ${documents.size} documents...")
            startIndexing()
        }
    }
}
```

#### 用户体验改进
- ✅ 启动后自动索引项目中的所有文档（包括源代码）
- ✅ 用户无需手动触发索引操作
- ✅ 可以直接在 Document Chat 中询问关于代码的问题

### 2. 索引状态可视化

**功能**：在 Document Chat 的标题栏中显示索引状态。

#### 实现位置
- **文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentChatPane.kt`
- **改动**: 添加了索引状态指示器

#### 状态显示
1. **索引中**: 显示进度圆圈 + "当前/总数" (例如: "5/10")
2. **索引完成**: 显示✓图标
3. **未索引/空闲**: 不显示任何指示器

### 3. 全局源代码搜索

**问题**：之前的 DocQL 查询仅限于当前选中的文档，无法在整个项目中搜索代码。

**解决方案**：当没有选中文档时，DocQL 查询自动切换到全局搜索模式。

#### 实现位置
- **文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderPage.kt`
- **改动**:

```kotlin
onDocQLQuery = { query ->
    val document = viewModel.selectedDocument
    if (document != null) {
        // 查询当前选中的文档
        executeDocQL(query, document, null)
    } else {
        // 全局查询所有已索引的文档
        try {
            cc.unitmesh.devins.document.DocumentRegistry.queryDocuments(query)
        } catch (e: Exception) {
            cc.unitmesh.devins.document.docql.DocQLResult.Error("全局查询失败: ${e.message}")
        }
    }
}
```

#### 查询范围
- **选中文档时**: 仅在当前文档中搜索
- **未选中文档时**: 在所有已索引的文档中搜索（包括 PDF、Markdown、源代码等）

### 4. DocQL 语法帮助增强

**功能**：在 DocQL 搜索栏的语法帮助中添加了源代码查询示例。

#### 实现位置
- **文件**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocQLSearchBar.kt`
- **改动**: 添加了"Source Code (🆕 全局搜索)"部分

#### 新增查询示例

```jsonpath
# 查找类或方法
$.content.heading("DocQLExecutor")

# 查找所有类
$.entities[?(@.type=="ClassEntity")]

# 查找所有方法/函数
$.entities[?(@.type=="FunctionEntity")]

# 模糊查找方法名
$.entities[?(@.name~="parse")]

# 查看代码结构 (包 -> 类 -> 方法)
$.toc[*]
```

#### 用户提示
- 💡 **全局搜索提示**: "未选中文档时，查询将在所有已索引的文档中搜索（包括源代码）"

## 使用场景

### 场景 1: 查找项目中的类或接口

**操作**：
1. 启动 Document Reader（自动索引）
2. 不选择任何文档
3. 在 DocQL 搜索栏或 Document Chat 中输入：
   ```
   $.content.heading("CodingAgent")
   ```

**结果**：返回所有包含 "CodingAgent" 类的源代码文件及其内容。

### 场景 2: 查找所有包含特定关键字的方法

**操作**：
```jsonpath
$.entities[?(@.type=="FunctionEntity" && @.name~="execute")]
```

**结果**：返回所有名称中包含 "execute" 的方法/函数。

### 场景 3: 了解某个包的结构

**操作**：
```jsonpath
$.entities[?(@.type=="ClassEntity" && @.packageName=="cc.unitmesh.agent.document")]
```

**结果**：返回 `cc.unitmesh.agent.document` 包中的所有类。

### 场景 4: 通过 AI Agent 进行自然语言查询

**操作**：在 Document Chat 中直接询问：
```
"How does CodingAgent work?"
```

**过程**：
1. DocumentAgent 将自然语言转换为 DocQL 查询
2. 自动检测到需要搜索源代码
3. 生成适当的 DocQL 查询 (例如: `$.content.heading("CodingAgent")`)
4. 在全局索引中搜索
5. 返回相关代码并解释其工作原理

## 技术实现

### 自动索引流程

```
DocumentReaderViewModel.init()
  ↓
loadDocuments()
  ↓ (延迟 500ms)
startIndexing()
  ↓
DocumentIndexService.indexDocuments()
  ↓
DocumentRegistry.registerDocument()
```

### 全局搜索流程

```
用户输入 DocQL 查询
  ↓
StructuredInfoPane.onDocQLQuery()
  ↓
selectedDocument == null? 
  ├─ YES → DocumentRegistry.queryDocuments(query)  [全局搜索]
  └─ NO  → executeDocQL(query, document, null)     [当前文档]
```

### 支持的源代码格式

通过 `DocumentFormatType.SOURCE_CODE` 支持以下文件扩展名：
- **JVM**: `.java`, `.kt`, `.kts`
- **JavaScript/TypeScript**: `.js`, `.ts`, `.tsx`
- **Python**: `.py`
- **Go**: `.go`
- **Rust**: `.rs`
- **C#**: `.cs`

## 测试验证

### 单元测试
- **文件**: `mpp-core/src/jvmTest/kotlin/cc/unitmesh/devins/document/CodeDocumentParserTest.kt`
- **覆盖范围**:
  - 解析 Kotlin 代码文件
  - 保留方法体内容
  - 处理嵌套类
  - 按包名查找类
  - 按名称模式查询方法

### 手动测试
1. 启动 Document Reader GUI
2. 观察自动索引进度
3. 在 Document Chat 中询问代码相关问题
4. 验证搜索结果的准确性

## 注意事项

1. **索引时间**: 大型项目首次索引可能需要较长时间（几分钟）
2. **内存使用**: 索引会占用额外的内存来存储文档结构
3. **文件过滤**: 某些文件类型（如测试文件）可能需要额外的过滤逻辑
4. **增量索引**: 当前实现是全量索引，后续可以优化为增量索引

## 相关文件

### 核心实现
- `mpp-core/src/jvmMain/kotlin/cc/unitmesh/devins/document/CodeDocumentParser.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/document/DocumentAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/devins/document/DocumentRegistry.kt`

### UI 组件
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderViewModel.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentReaderPage.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocumentChatPane.kt`
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/document/DocQLSearchBar.kt`

### 测试
- `mpp-core/src/jvmTest/kotlin/cc/unitmesh/devins/document/CodeDocumentParserTest.kt`
- `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/server/cli/DocumentCli.kt`

## 后续改进建议

1. **性能优化**
   - 实现增量索引（只索引变更的文件）
   - 添加索引缓存机制
   - 支持后台异步索引

2. **搜索增强**
   - 支持正则表达式搜索
   - 支持代码语义搜索（基于 AST）
   - 添加搜索结果排序和相关性评分

3. **用户体验**
   - 添加索引进度详细信息（当前正在索引的文件名）
   - 支持暂停/恢复索引
   - 添加索引配置选项（选择要索引的目录、文件类型等）

4. **多平台支持**
   - 扩展到 JS/WASM 平台（目前 TreeSitter 解析器仅支持 JVM）
   - 实现轻量级的客户端索引

## 总结

这次改进实现了：
- ✅ 自动索引：无需手动触发
- ✅ 状态可视化：实时显示索引进度
- ✅ 全局搜索：在整个项目中搜索代码
- ✅ 语法帮助：提供源代码查询示例
- ✅ 友好体验：从启动到查询的完整流程

用户现在可以直接启动 Document Reader，在 Document Chat 中用自然语言询问关于代码的问题，系统会自动搜索并返回相关的源代码和解释。

