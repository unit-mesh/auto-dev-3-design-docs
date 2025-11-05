# TokenEstimator 修正后的流程示例

## 修正前的问题流程

```kotlin
// ❌ 错误的流程
fun streamPrompt(userPrompt: String, historyMessages: List<Message>) {
    // 1. 在没有完整 prompt 的情况下进行压缩决策
    val compressedMessages = tryAutoCompress(historyMessages) // 无法获取 prompt.latestTokenUsage
    
    // 2. 然后构建 prompt
    val prompt = buildPrompt(userPrompt, compressedMessages)
    
    // 3. 执行
    executor.executeStreaming(prompt, model)
}

private fun tryAutoCompress(historyMessages: List<Message>) {
    // 只能基于估算进行决策，不准确
    if (TokenEstimator.needsCompression(historyMessages, model, config, null)) {
        // 压缩逻辑
    }
}
```

## 修正后的正确流程

```kotlin
// ✅ 正确的流程
fun streamPrompt(userPrompt: String, historyMessages: List<Message>) {
    // 1. 先构建完整的 prompt 以便进行准确的 token 计算
    val initialPrompt = buildPrompt(userPrompt, historyMessages)
    
    // 2. 基于完整的 prompt 进行压缩决策
    val compressedMessages = tryAutoCompress(initialPrompt, historyMessages)
    
    // 3. 如果消息被压缩了，重新构建 prompt
    val finalPrompt = if (compressedMessages !== historyMessages) {
        buildPrompt(userPrompt, compressedMessages)
    } else {
        initialPrompt
    }
    
    // 4. 执行
    executor.executeStreaming(finalPrompt, model)
}

private fun tryAutoCompress(prompt: Prompt, historyMessages: List<Message>) {
    // 现在可以使用 prompt.latestTokenUsage 进行精确计算
    if (TokenEstimator.needsCompression(historyMessages, model, config, prompt)) {
        // 基于准确信息的压缩逻辑
    }
}
```

## 关键改进点

1. **完整上下文**：压缩决策现在基于完整的 prompt 对象
2. **精确计算**：能够使用 `prompt.latestTokenUsage` 获取实际 token 使用情况
3. **避免重复构建**：只有在需要压缩时才重新构建 prompt
4. **引用比较**：使用 `!==` 检查是否发生了压缩，避免不必要的重建

## Token 计算优先级

```kotlin
fun getCurrentTokenUsage(prompt: Prompt?, messages: List<Message>): Int {
    // 1. 优先使用实际的 token 使用情况
    prompt?.latestTokenUsage?.let { actualUsage ->
        if (actualUsage > 0) return actualUsage
    }
    
    // 2. 回退到改进的估算算法
    return estimateTokens(messages)
}
```

这样确保了 Token 计算的准确性，提高了压缩决策的质量。
