# 上下文压缩功能实现总结

## 🎯 实现概述

基于 Gemini CLI 的设计，成功在 mpp-core 中实现了完整的上下文压缩功能，用于解决长对话历史导致的 token 限制问题。

## 📦 实现的组件

### 1. 核心数据类 (`compression/CompressionConfig.kt`)

```kotlin
// 压缩配置
CompressionConfig(
    contextPercentageThreshold = 0.7,  // 70% 时触发
    preserveRecentRatio = 0.3,          // 保留最近 30%
    autoCompressionEnabled = true,
    retryAfterMessages = 5
)

// 压缩状态枚举
enum class CompressionStatus {
    COMPRESSED,
    COMPRESSION_FAILED_INFLATED_TOKEN_COUNT,
    COMPRESSION_FAILED_TOKEN_COUNT_ERROR,
    NOOP,
    COMPRESSION_FAILED_ERROR
}

// Token 信息追踪
data class TokenInfo(
    totalTokens: Int,
    inputTokens: Int,
    outputTokens: Int,
    timestamp: Long
)

// 压缩结果
data class ChatCompressionInfo(
    originalTokenCount: Int,
    newTokenCount: Int,
    compressionStatus: CompressionStatus,
    errorMessage: String? = null
)
```

### 2. 压缩提示词 (`compression/CompressionPrompts.kt`)

使用结构化的 XML 格式保存状态快照：

```xml
<state_snapshot>
    <overall_goal>用户的高级目标</overall_goal>
    <key_knowledge>关键事实和约束</key_knowledge>
    <file_system_state>文件操作记录</file_system_state>
    <recent_actions>最近的操作和结果</recent_actions>
    <current_plan>当前执行计划</current_plan>
    <context_metadata>其他重要上下文</context_metadata>
</state_snapshot>
```

### 3. 压缩服务 (`compression/ChatCompressionService.kt`)

核心功能：

- **智能分段**：`findCompressSplitPoint()` - 在用户消息处分割，保留最近对话
- **LLM 总结**：`generateSummary()` - 使用 AIAgent 生成状态快照
- **Token 估算**：`estimateTokenCount()` - 粗略估计（4字符≈1token）
- **压缩验证**：防止 token 反向膨胀

### 4. LLM 服务集成 (`KoogLLMService.kt`)

新增功能：

- **Token 追踪**：在 `StreamFrame.End` 时自动更新 token 信息
- **自动压缩触发**：达到阈值时回调通知
- **压缩方法**：`tryCompressHistory()` 支持手动和自动压缩
- **状态管理**：失败重试控制、消息计数

关键代码：

```kotlin
streamPrompt(
    userPrompt: String,
    historyMessages: List<Message>,
    onTokenUpdate: ((TokenInfo) -> Unit)?,
    onCompressionNeeded: ((Int, Int) -> Unit)?
): Flow<String>

suspend fun tryCompressHistory(
    historyMessages: List<Message>,
    force: Boolean = false
): CompressionResult
```

### 5. 对话管理器增强 (`ConversationManager.kt`)

新增功能：

- **自动压缩**：在 `sendMessage()` 前检查并压缩
- **回调机制**：
  - `onTokenUpdate` - Token 使用更新
  - `onCompressionNeeded` - 压缩建议
  - `onCompressionCompleted` - 压缩完成
- **统计信息**：`getConversationStats()` 获取 token 使用率

## 🔄 工作流程

```
┌─────────────────────┐
│  用户发送消息        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  检查 token 使用率   │
└──────┬──────────────┘
       │
       ▼ (>70%)
┌─────────────────────┐
│  触发压缩检查        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  找到分割点 (70%)    │
│  保留最近 30%        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  LLM 生成摘要        │
│  (结构化 XML)        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  验证 token 数量     │
│  (防止膨胀)          │
└──────┬──────────────┘
       │
       ▼ (成功)
┌─────────────────────┐
│  更新对话历史        │
│  继续对话            │
└─────────────────────┘
```

## 📊 Token 追踪机制

```kotlin
// StreamFrame.End 自动捕获
StreamFrame.End -> 
    metaInfo=ResponseMetaInfo(
        totalTokensCount=5086,
        inputTokensCount=5009,
        outputTokensCount=77
    )

// 转换为 TokenInfo
TokenInfo(
    totalTokens = 5086,
    inputTokens = 5009,
    outputTokens = 77,
    timestamp = 1730785533792
)
```

## 🎯 使用示例

### 基本使用

```kotlin
// 1. 创建配置
val compressionConfig = CompressionConfig(
    contextPercentageThreshold = 0.7,
    preserveRecentRatio = 0.3,
    autoCompressionEnabled = true
)

// 2. 创建服务
val llmService = KoogLLMService.create(modelConfig, compressionConfig)

// 3. 创建对话管理器
val conversationManager = ConversationManager(
    llmService = llmService,
    systemPrompt = "你是一个有用的 AI 助手。",
    autoCompress = true
)

// 4. 设置回调
conversationManager.onTokenUpdate = { tokenInfo ->
    val usage = tokenInfo.getUsagePercentage(llmService.getMaxTokens())
    println("Token 使用率: ${usage}%")
}

conversationManager.onCompressionCompleted = { result ->
    println("压缩完成！节省: ${result.info.tokensSaved} tokens")
}

// 5. 发送消息（自动处理压缩）
conversationManager.sendMessage("你的问题").collect { chunk ->
    print(chunk)
}
```

### 手动压缩

```kotlin
// 检查是否需要压缩
if (conversationManager.needsCompression()) {
    val result = conversationManager.compressHistory(force = true)
    
    when (result.info.compressionStatus) {
        CompressionStatus.COMPRESSED -> {
            println("✅ 压缩成功!")
            println("   节省: ${result.info.tokensSaved} tokens")
        }
        else -> {
            println("❌ 压缩失败: ${result.info.errorMessage}")
        }
    }
}
```

### 获取统计信息

```kotlin
val stats = conversationManager.getConversationStats()
println("消息数: ${stats.messageCount}")
println("Token 使用: ${stats.tokenInfo.inputTokens} / ${stats.maxTokens}")
println("使用率: ${stats.utilizationRatio * 100}%")
```

## ✅ 测试验证

- ✅ 编译成功（JVM 目标）
- ✅ 无 lint 错误
- ✅ 类型检查通过
- 📝 集成测试脚本：`docs/test-scripts/context-compression-demo.kt`

## 🔑 核心设计原则

1. **渐进式触发**：70% 阈值，避免突然卡顿
2. **LLM 自压缩**：利用 AI 自身的理解和总结能力
3. **结构化记忆**：XML 格式保证信息完整性
4. **安全优先**：多重检查，避免破坏对话状态
5. **用户可控**：支持手动和自动双模式
6. **失败保护**：膨胀检测 + 重试限制

## 📈 性能特点

| 特性 | 说明 |
|------|------|
| 压缩阈值 | 默认 70%，可配置 |
| 保留比例 | 默认保留最近 30% |
| Token 估算 | 4 字符 ≈ 1 token |
| 失败重试 | 默认等待 5 条消息后重试 |
| 压缩时机 | 发送消息前自动检查 |

## 🎨 相比 Gemini CLI 的优化

1. **简化集成**：直接集成到 `KoogLLMService`，无需独立客户端
2. **统一接口**：使用 `AIAgent` 执行压缩，保持一致性
3. **回调机制**：提供丰富的回调函数，便于 UI 集成
4. **统计信息**：`ConversationStats` 提供完整的对话统计

## 📚 相关文件

- `/mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/compression/CompressionConfig.kt`
- `/mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/compression/CompressionPrompts.kt`
- `/mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/compression/ChatCompressionService.kt`
- `/mpp-core/src/commonMain/kotlin/cc/unitmesh/llm/KoogLLMService.kt`
- `/mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/conversation/ConversationManager.kt`
- `/docs/context-compression.md` - 使用文档
- `/docs/test-scripts/context-compression-demo.kt` - 测试示例

## 🚀 后续扩展

1. **更精确的 Token 计数**：集成专门的 tokenizer 库
2. **压缩策略优化**：支持不同的分割策略
3. **缓存机制**：缓存压缩结果，避免重复压缩
4. **可视化**：添加 UI 显示压缩效果和历史
5. **多语言支持**：优化不同语言的 token 估算

## 🎉 总结

成功实现了一套完整的上下文压缩系统，核心特点：

- ✅ **自动化**：达到阈值自动触发，无需用户干预
- ✅ **智能化**：使用 LLM 生成结构化摘要
- ✅ **安全性**：多重检查，防止 token 膨胀
- ✅ **灵活性**：支持手动和自动双模式
- ✅ **可观测**：丰富的回调和统计信息

这套系统确保即使在长对话场景下，Agent 也能：
- 记住目标和计划
- 保留关键知识
- 维持工具调用状态
- 避免重复工作

