# TokenEstimator 重写测试脚本

## 测试目标
验证重写后的 TokenEstimator 能够正确使用 `model.maxOutputTokens` 和 `prompt.latestTokenUsage` 进行精确的 Token 计算。

## 测试步骤

### 1. 运行单元测试
```bash
./gradlew :mpp-core:jvmTest --tests "*TokenEstimator*"
```

### 2. 验证新的 API 使用
- ✅ `getTokenLimit(model: LLModel?, modelConfig: ModelConfig)` - 优先使用 LLModel 的 contextLength
- ✅ `getMaxOutputTokens(model: LLModel?, modelConfig: ModelConfig)` - 优先使用 LLModel 的 maxOutputTokens
- ✅ `getCurrentTokenUsage(prompt: Prompt?, messages: List<Message>)` - 优先使用 Prompt 的 latestTokenUsage
- ✅ `needsCompression()` 和 `getCompressionAdvice()` 方法支持新的参数

### 3. 验证改进的 Token 估算
- ✅ 更精确的中英文混合文本 Token 估算
- ✅ 考虑 JSON 格式和消息结构开销
- ✅ 区分可用输入 Token 和最大输出 Token

### 4. 验证兼容性
- ✅ 保留旧的 API 接口以确保向后兼容
- ✅ KoogLLMService 和 ChatCompressionService 正确使用新 API

## 主要改进

1. **精确的 Token 限制计算**：
   - 优先使用 `LLModel.contextLength` 而不是基于模型名称的硬编码值
   - 使用默认值 128000 作为回退，简化了复杂的模型名称匹配逻辑

2. **实际 Token 使用情况**：
   - 优先使用 `Prompt.latestTokenUsage` 获取实际的 Token 使用数量
   - 回退到改进的估算算法

3. **输出 Token 预留**：
   - 使用 `LLModel.maxOutputTokens` 计算实际可用于输入的 Token 数量
   - 避免因输出 Token 不足导致的截断问题

4. **改进的估算算法**：
   - 更精确的中英文字符 Token 比例
   - 考虑消息结构和对话开销

5. **修正压缩决策逻辑**：
   - 修正了 `streamPrompt` 中的压缩决策流程
   - 现在先构建完整的 `prompt` 对象，再基于完整信息进行压缩决策
   - `tryAutoCompress` 现在接收 `prompt` 参数，能够使用 `prompt.latestTokenUsage` 进行精确计算

## 测试结果
- ✅ 所有单元测试通过 (201 tests completed, 0 failed)
- ✅ JVM 编译无错误
- ✅ 向后兼容性保持
- ✅ KoogLLMService 和 ChatCompressionService 正确集成新 API

## 总结

TokenEstimator 已成功重写，现在能够：

1. **精确使用 LLModel 信息**：
   - 优先使用 `model.contextLength` 获取真实的 token 限制
   - 优先使用 `model.maxOutputTokens` 计算输出预留空间
   - 简化了复杂的模型名称匹配逻辑，使用 128000 作为默认值

2. **实际 Token 使用追踪**：
   - 优先使用 `prompt.latestTokenUsage` 获取实际 token 使用情况
   - 改进的估算算法作为回退方案

3. **智能压缩决策**：
   - 区分可用输入 token 和最大输出 token
   - 避免因输出空间不足导致的响应截断
   - 提供详细的压缩建议信息

4. **保持兼容性**：
   - 保留旧的 API 接口确保现有代码正常工作
   - 所有相关服务类已更新使用新 API

这次重写解决了原有 Token 计算逻辑不准确的问题，现在能够更好地利用 Koog 框架提供的精确信息进行 Token 管理和压缩决策。

## 关键修正

**问题**：原来的 `tryAutoCompress` 方法在没有完整 `prompt` 对象的情况下进行压缩决策，无法获取 `prompt.latestTokenUsage`，导致 token 计算不准确。

**解决方案**：
1. 修改 `streamPrompt` 流程：先构建完整的 `prompt` 对象
2. 将完整的 `prompt` 传递给 `tryAutoCompress` 方法
3. 现在能够使用 `prompt.latestTokenUsage` 进行精确的 token 计算
4. 如果需要压缩，重新构建 `prompt` 以确保一致性

这样确保了压缩决策基于准确的 token 使用情况，而不是仅仅基于估算。
