# 上下文压缩功能

本文档介绍 mpp-core 中的上下文压缩功能，该功能基于 Gemini CLI 的设计，用于解决长对话历史导致的 token 限制问题。

## 功能概述

当对话历史变得过长时，上下文压缩功能会自动将历史对话压缩为结构化的状态快照，既保留了关键信息，又大幅减少了 token 使用量。

### 核心特性

1. **自动压缩触发**：当 token 使用量超过模型限制的 70% 时自动触发
2. **智能分割**：保留最近 30% 的对话，压缩前面 70% 的内容
3. **结构化快照**：生成包含目标、知识、文件状态、操作历史等的 XML 快照
4. **压缩验证**：确保压缩后 token 数量确实减少
5. **失败重试控制**：压缩失败后等待一定数量的新消息再重试

## 使用方法

### 1. 基本配置

```kotlin
import cc.unitmesh.llm.compression.CompressionConfig

val compressionConfig = CompressionConfig(
    contextPercentageThreshold = 0.7,  // 70% 时触发压缩
    preserveRecentRatio = 0.3,         // 保留最近 30% 的对话
    autoCompressionEnabled = true,      // 启用自动压缩
    retryAfterMessages = 5             // 失败后等待 5 条消息再重试
)
```

### 2. 集成到 KoogLLMService

```kotlin
import cc.unitmesh.llm.KoogLLMService
import cc.unitmesh.llm.ModelConfig

val modelConfig = ModelConfig(/* 你的模型配置 */)
val llmService = KoogLLMService.create(modelConfig, compressionConfig)

// 自动压缩会在 streamPrompt 时自动触发
val response = llmService.streamPrompt(
    userPrompt = "你的问题",
    historyMessages = historyMessages,
    autoCompress = true  // 启用自动压缩
)
```

### 3. 手动压缩

```kotlin
// 手动压缩历史消息
val compressionResult = llmService.compressHistory(historyMessages, force = true)

when (compressionResult.info.compressionStatus) {
    CompressionStatus.COMPRESSED -> {
        println("压缩成功：${compressionResult.info.originalTokenCount} -> ${compressionResult.info.newTokenCount}")
        // 使用压缩后的消息
        val compressedMessages = compressionResult.newMessages!!
    }
    CompressionStatus.NOOP -> {
        println("无需压缩")
    }
    else -> {
        println("压缩失败：${compressionResult.info.errorMessage}")
    }
}
```

### 4. 使用 ConversationManager

```kotlin
import cc.unitmesh.agent.conversation.ConversationManager

val conversationManager = ConversationManager(llmService, systemPrompt)

// 检查是否需要压缩
if (conversationManager.needsCompression()) {
    val result = conversationManager.compressHistory()
    println("压缩比例：${result.info.compressionRatio}")
}

// 获取对话统计
val stats = conversationManager.getConversationStats()
println("Token 使用率：${stats.utilizationRatio * 100}%")
```

### 5. 使用 ChatHistoryManager

```kotlin
import cc.unitmesh.devins.llm.ChatHistoryManager
import cc.unitmesh.llm.compression.ChatCompressionService

val compressionService = ChatCompressionService(executor, model, compressionConfig)
val historyManager = ChatHistoryManager(compressionService, compressionConfig)

// 自动压缩当前会话
val result = historyManager.tryCompressCurrentSession(modelConfig)
```

## 压缩提示词结构

压缩功能使用结构化的 XML 提示词来生成状态快照：

```xml
<state_snapshot>
    <overall_goal>
        <!-- 用户的高级目标 -->
    </overall_goal>
    
    <key_knowledge>
        <!-- 关键事实、约定和约束 -->
    </key_knowledge>
    
    <file_system_state>
        <!-- 文件系统状态变化 -->
    </file_system_state>
    
    <recent_actions>
        <!-- 最近的重要操作和结果 -->
    </recent_actions>
    
    <current_plan>
        <!-- 当前的执行计划 -->
    </current_plan>
    
    <context_metadata>
        <!-- 其他重要的上下文信息 -->
    </context_metadata>
</state_snapshot>
```

## 配置参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `contextPercentageThreshold` | 0.7 | 触发压缩的 token 阈值（占模型限制的比例） |
| `preserveRecentRatio` | 0.3 | 保留最近对话的比例 |
| `autoCompressionEnabled` | true | 是否启用自动压缩 |
| `retryAfterMessages` | 5 | 压缩失败后等待的消息数量 |

## 最佳实践

1. **合理设置阈值**：根据你的使用场景调整 `contextPercentageThreshold`
2. **保留足够上下文**：`preserveRecentRatio` 不要设置得太小，确保保留足够的最近上下文
3. **监控压缩效果**：定期检查压缩比例和效果
4. **处理压缩失败**：为压缩失败的情况提供降级方案

## 注意事项

1. 压缩是一个相对耗时的操作，建议在合适的时机进行
2. 压缩后的状态快照可能不如原始对话详细，但包含了关键信息
3. 如果压缩后 token 数量反而增加，系统会自动放弃压缩
4. 压缩功能依赖于 AI 模型的理解和总结能力
