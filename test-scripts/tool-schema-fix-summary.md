# CodingAgent 工具 Schema 问题修复总结

## 问题描述

在 Compose 的 JVM 和 Android 版本中，`CodingAgent.execute()` 调用 `buildContext()` 时，`getAllTools()` 返回的工具列表缺少 `ToolSchema` 等信息，导致模型无法正确理解工具。

## 根本原因

1. **SubAgent 参数类型问题**: `Agent` 基类的 `getParameterClass()` 方法硬编码返回 `"AgentInput"`，导致所有 SubAgent 都显示为通用参数类型，而不是具体的参数类型。

2. **提示词生成问题**: `CodingAgentContext.formatToolListForAI()` 方法对 `"AgentInput"` 类型的处理不够完善，导致生成的工具提示词缺少关键信息。

3. **示例缺失**: SubAgent 工具缺少使用示例，影响 AI 模型的理解。

## 修复方案

### 1. 修复 SubAgent 参数类型

为所有 SubAgent 添加了正确的 `getParameterClass()` 实现：

```kotlin
// ErrorRecoveryAgent
override fun getParameterClass(): String = ErrorContext::class.simpleName ?: "ErrorContext"

// LogSummaryAgent  
override fun getParameterClass(): String = LogSummaryContext::class.simpleName ?: "LogSummaryContext"

// CodebaseInvestigatorAgent
override fun getParameterClass(): String = InvestigationContext::class.simpleName ?: "InvestigationContext"
```

### 2. 改进提示词生成

改进了 `CodingAgentContext.formatToolListForAI()` 方法：

- 添加了对空描述的处理
- 改进了对 `"AgentInput"` 类型的特殊处理
- 为 SubAgent 提供了更合适的参数类型描述

### 3. 添加 SubAgent 示例

为所有 SubAgent 添加了使用示例：

```kotlin
"error-recovery" -> "/${tool.name} command=\"gradle build\" errorMessage=\"Compilation failed\""
"log-summary" -> "/${tool.name} command=\"npm test\" output=\"[long test output...]\""
"codebase-investigator" -> "/${tool.name} query=\"find all REST endpoints\" scope=\"methods\""
```

## 修复效果

### 修复前的工具提示词
```xml
<tool name="error-recovery">
  <description>Analyzes command failures and provides recovery plans</description>
  <parameters>
    <type>AgentInput</type>
    <usage>/error-recovery [parameters]</usage>
  </parameters>
  <example>
    /error-recovery <parameters>
  </example>
</tool>
```

### 修复后的工具提示词
```xml
<tool name="error-recovery">
  <description>Analyzes command failures and provides recovery plans</description>
  <parameters>
    <type>ErrorContext</type>
    <usage>/error-recovery [parameters]</usage>
  </parameters>
  <example>
    /error-recovery command="gradle build" errorMessage="Compilation failed"
  </example>
</tool>
```

## 验证方法

运行验证脚本：
```bash
./docs/test-scripts/verify-tool-schema-fix.sh
```

该脚本会：
1. 检查所有修复的文件是否存在
2. 验证 `getParameterClass()` 方法是否正确实现
3. 检查 `CodingAgentContext` 的改进是否到位
4. 运行编译测试确保修复不会破坏构建

## 预期结果

- ✅ SubAgent 工具现在显示正确的参数类型（ErrorContext, LogSummaryContext, InvestigationContext）
- ✅ 工具提示词包含更完整的 Schema 信息
- ✅ AI 模型能够更好地理解和使用工具
- ✅ 在 Compose JVM/Android 版本中工具调用应该正常工作

## 测试建议

1. **单元测试**: 创建测试验证 `getAllTools()` 返回的工具具有正确的参数类型
2. **集成测试**: 测试 `CodingAgentContext.formatToolListForAI()` 生成的提示词格式
3. **端到端测试**: 在实际的 Compose 应用中测试 CodingAgent 的工具调用功能

## 相关文件

- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/core/Agent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt`
