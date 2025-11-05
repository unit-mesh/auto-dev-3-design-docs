#!/usr/bin/env kotlin

/**
 * 上下文压缩功能演示脚本
 * 
 * 这个脚本演示了如何使用 mpp-core 中的上下文压缩功能
 */

import cc.unitmesh.devins.llm.Message
import cc.unitmesh.devins.llm.MessageRole
import cc.unitmesh.llm.ModelConfig
import cc.unitmesh.llm.LLMProviderType
import cc.unitmesh.llm.compression.*

suspend fun main() {
    println("🚀 上下文压缩功能演示")
    println("=" * 50)
    
    // 1. 创建模型配置
    val modelConfig = ModelConfig(
        provider = LLMProviderType.DEEPSEEK,
        modelName = "deepseek-chat",
        apiKey = "your-api-key-here", // 在实际使用中请替换为真实的 API Key
        temperature = 0.7,
        maxTokens = 32768
    )
    
    // 2. 创建压缩配置
    val compressionConfig = CompressionConfig(
        contextPercentageThreshold = 0.7,  // 70% 时触发压缩
        preserveRecentRatio = 0.3,         // 保留最近 30% 的对话
        autoCompressionEnabled = true,      // 启用自动压缩
        retryAfterMessages = 5             // 失败后等待 5 条消息再重试
    )
    
    // 3. 创建测试消息历史
    val messages = createTestMessages()
    
    println("📊 原始消息统计:")
    println("- 消息数量: ${messages.size}")
    
    // 4. 估算 Token 使用情况
    val advice = TokenEstimator.getCompressionAdvice(messages, modelConfig)
    println("- 估算 Token 数: ${advice.currentTokens}")
    println("- Token 限制: ${advice.tokenLimit}")
    println("- 使用率: ${String.format("%.1f", advice.utilizationRatio * 100)}%")
    println("- 是否需要压缩: ${if (advice.needsCompression) "是" else "否"}")
    println("- 建议: ${advice.recommendedAction}")
    
    // 5. 测试消息分割
    println("\n🔪 消息分割测试:")
    val splitResult = MessageSplitter.splitMessages(messages, compressionConfig.preserveRecentRatio)
    println("- 需要压缩的消息: ${splitResult.messagesToCompress.size}")
    println("- 需要保留的消息: ${splitResult.messagesToKeep.size}")
    println("- 压缩比例: ${String.format("%.1f", splitResult.compressionRatio * 100)}%")
    println("- 分割结果有效: ${MessageSplitter.validateSplitResult(splitResult)}")
    
    // 6. 演示压缩配置验证
    println("\n⚙️ 压缩配置验证:")
    println("- 配置有效性: ${compressionConfig.isValid()}")
    
    // 7. 演示不同模型的 Token 限制
    println("\n🤖 不同模型的 Token 限制:")
    val models = listOf(
        "gpt-4" to LLMProviderType.OPENAI,
        "gpt-3.5-turbo" to LLMProviderType.OPENAI,
        "claude-3-sonnet" to LLMProviderType.ANTHROPIC,
        "gemini-pro" to LLMProviderType.GOOGLE,
        "deepseek-chat" to LLMProviderType.DEEPSEEK
    )
    
    models.forEach { (modelName, provider) ->
        val config = ModelConfig(provider = provider, modelName = modelName)
        val limit = TokenEstimator.getTokenLimit(config)
        println("- $modelName: ${limit} tokens")
    }
    
    println("\n✅ 演示完成！")
    println("\n💡 提示:")
    println("- 在实际使用中，请配置正确的 API Key")
    println("- 可以根据需要调整压缩阈值和保留比例")
    println("- 建议在生产环境中监控压缩效果和性能")
}

/**
 * 创建测试消息历史
 */
fun createTestMessages(): List<Message> {
    val messages = mutableListOf<Message>()
    
    // 添加系统消息
    messages.add(Message(
        role = MessageRole.SYSTEM,
        content = "你是一个专业的软件开发助手，擅长 Kotlin、Java 和软件架构设计。"
    ))
    
    // 添加多轮对话
    val conversations = listOf(
        "用户" to "请帮我设计一个用户管理系统的架构",
        "助手" to "我来帮你设计一个用户管理系统架构。首先，我们需要考虑以下几个核心组件：\n\n1. 用户实体层（Entity Layer）\n2. 数据访问层（Repository Layer）\n3. 业务逻辑层（Service Layer）\n4. 控制器层（Controller Layer）\n5. 安全认证层（Security Layer）",
        
        "用户" to "能详细说明一下数据访问层的设计吗？",
        "助手" to "当然！数据访问层的设计应该遵循以下原则：\n\n1. 使用 Repository 模式\n2. 定义清晰的接口\n3. 支持多种数据源\n4. 实现数据缓存策略\n5. 处理事务管理",
        
        "用户" to "如何实现用户权限管理？",
        "助手" to "用户权限管理可以采用 RBAC（基于角色的访问控制）模型：\n\n1. 用户（User）\n2. 角色（Role）\n3. 权限（Permission）\n4. 用户-角色关联\n5. 角色-权限关联",
        
        "用户" to "请提供一些 Kotlin 代码示例",
        "助手" to "以下是一些 Kotlin 代码示例：\n\n```kotlin\ndata class User(\n    val id: Long,\n    val username: String,\n    val email: String,\n    val roles: Set<Role>\n)\n\ndata class Role(\n    val id: Long,\n    val name: String,\n    val permissions: Set<Permission>\n)\n\ninterface UserRepository {\n    suspend fun findById(id: Long): User?\n    suspend fun findByUsername(username: String): User?\n    suspend fun save(user: User): User\n}\n```",
        
        "用户" to "如何处理密码加密和验证？",
        "助手" to "密码安全处理的最佳实践：\n\n1. 使用强哈希算法（如 bcrypt、Argon2）\n2. 添加盐值（Salt）\n3. 实现密码强度验证\n4. 支持密码重置功能\n5. 记录登录尝试和失败次数"
    )
    
    conversations.forEach { (role, content) ->
        val messageRole = if (role == "用户") MessageRole.USER else MessageRole.ASSISTANT
        messages.add(Message(role = messageRole, content = content))
    }
    
    return messages
}

// 扩展函数：重复字符串
operator fun String.times(n: Int): String = this.repeat(n)

// 如果作为脚本运行
if (args.isEmpty()) {
    kotlinx.coroutines.runBlocking {
        main()
    }
}
