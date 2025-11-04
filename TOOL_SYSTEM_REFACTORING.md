# Tool System Refactoring

## 问题描述

原有的Tool体系存在以下问题：

1. **字符串硬编码**: AgentDefinition的ToolConfig使用字符串方式定义工具名称（如"read-file"），容易导致不一致
2. **工具注册冲突**: toolConfig和init里的Agent注册存在冲突
3. **系统提示硬编码**: buildCodingAgentSystemPrompt里的Tools是硬编码的，没有使用变量方式获取所有tool
4. **架构不统一**: 没有采用全局统一的CodingAgentTemplate和CodingAgentPromptRenderer

## 解决方案

### 1. 统一工具名称管理

**创建ToolNames常量对象**:
```kotlin
object ToolNames {
    // File system tools
    const val READ_FILE = "read-file"
    const val WRITE_FILE = "write-file"
    const val SHELL = "shell"
    const val GLOB = "glob"
    
    // SubAgent tools
    const val ERROR_RECOVERY = "error-recovery"
    const val LOG_SUMMARY = "log-summary"
    const val CODEBASE_INVESTIGATOR = "codebase-investigator"
    
    val ALL_TOOLS = setOf(...)
}
```

### 2. 更新工具配置

**使用常量替代字符串**:
```kotlin
toolConfig = ToolConfig(
    allowedTools = listOf(
        ToolNames.READ_FILE,
        ToolNames.WRITE_FILE, 
        ToolNames.SHELL,
        ToolNames.GLOB,
        ToolNames.ERROR_RECOVERY,
        ToolNames.LOG_SUMMARY,
        ToolNames.CODEBASE_INVESTIGATOR
    )
)
```

### 3. 统一系统提示渲染

**使用CodingAgentPromptRenderer**:
```kotlin
override fun buildSystemPrompt(context: CodingAgentContext, language: String): String {
    val renderer = CodingAgentPromptRenderer()
    val tools = getAllTools()
    return renderer.renderSystemPrompt(tools, language)
}
```

### 4. 动态工具列表注入

**CodingAgentTemplate支持动态工具**:
```
## Available Tools
You have access to the following tools through DevIns commands:

${toolList}
```

**CodingAgentPromptRenderer动态填充**:
```kotlin
fun renderSystemPrompt(tools: List<Tool>, language: String = "EN"): String {
    val toolDescriptions = tools.map { tool ->
        "- **${tool.name}**: ${tool.description}"
    }.joinToString("\n")
    
    variableTable.addVariable("toolList", VariableType.STRING, toolDescriptions)
    // ...
}
```

## 架构改进

### 1. 跨平台支持

**Platform抽象**:
```kotlin
expect object Platform {
    fun getOSName(): String
    fun getDefaultShell(): String
}
```

### 2. SubAgent名称统一

**所有SubAgent使用ToolNames常量**:
```kotlin
// ErrorRecoveryAgent
AgentDefinition(name = ToolNames.ERROR_RECOVERY, ...)

// LogSummaryAgent  
AgentDefinition(name = ToolNames.LOG_SUMMARY, ...)

// CodebaseInvestigatorAgent
AgentDefinition(name = ToolNames.CODEBASE_INVESTIGATOR, ...)
```

## 测试验证

运行测试脚本验证重构结果：
```bash
node docs/test-scripts/test-tool-system.js
```

测试覆盖：
- ✅ JVM和JS编译成功
- ✅ CLI构建和运行正常
- ✅ 工具名称常量化
- ✅ 动态系统提示生成
- ✅ 跨平台兼容性

## 效果

1. **一致性**: 工具名称统一管理，避免字符串不匹配
2. **可维护性**: 修改工具名称只需更新ToolNames常量
3. **动态性**: 系统提示自动包含所有注册的工具
4. **跨平台**: 支持JVM、JS、Android、WASM等多平台
5. **架构统一**: 使用统一的模板和渲染系统

## JS编译问题修复

### 问题描述
Webpack 5不再自动提供Node.js核心模块的polyfill，导致在浏览器环境中使用Node.js模块（如`fs`、`os`、`path`、`child_process`）时出现编译错误。

### 解决方案

**1. 环境检测**
```kotlin
private val isNodeJs: Boolean = js("typeof process !== 'undefined' && process.versions && process.versions.node") as Boolean
```

**2. 条件模块加载**
```kotlin
private val fsModule: dynamic = if (isNodeJs) js("require('fs')") else null
private val pathModule: dynamic = if (isNodeJs) js("require('path')") else null
```

**3. 优雅降级**
```kotlin
actual suspend fun load(): AutoDevConfigWrapper {
    if (!isNodeJs) {
        console.warn("Config loading not supported in browser environment")
        return createEmpty()
    }
    // Node.js specific implementation...
}
```

### 修复的文件
- `mpp-ui/src/jsMain/kotlin/cc/unitmesh/devins/ui/config/ConfigManager.js.kt`
- `mpp-core/src/jsMain/kotlin/cc/unitmesh/devins/filesystem/DefaultFileSystem.js.kt`

## 文件变更

- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/ToolNames.kt` - 新增工具名称常量
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt` - 使用常量和统一渲染
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentPromptRenderer.kt` - 支持动态工具列表
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/Platform.kt` - 新增跨平台方法
- `mpp-core/src/*/kotlin/cc/unitmesh/agent/Platform.*` - 各平台实现
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/*.kt` - 使用ToolNames常量
- `mpp-ui/src/jsMain/kotlin/cc/unitmesh/devins/ui/config/ConfigManager.js.kt` - JS环境兼容性修复
- `mpp-core/src/jsMain/kotlin/cc/unitmesh/devins/filesystem/DefaultFileSystem.js.kt` - JS环境兼容性修复
