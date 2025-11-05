#!/usr/bin/env node

/**
 * 压缩功能测试脚本 (JavaScript)
 * 
 * 测试 mpp-core 的压缩功能在 JS 平台上的工作情况
 */

const fs = require('fs');
const path = require('path');

async function main() {
    console.log('🧪 压缩功能测试 (JavaScript 平台)');
    console.log('='.repeat(50));
    
    try {
        // 1. 检查构建产物
        console.log('\n📦 1. 检查构建产物');
        await checkBuildArtifacts();
        
        // 2. 加载 mpp-core
        console.log('\n📚 2. 加载 mpp-core');
        const mppCore = await loadMppCore();
        
        // 3. 测试压缩配置
        console.log('\n⚙️  3. 测试压缩配置');
        await testCompressionConfig(mppCore);
        
        // 4. 测试 TokenInfo
        console.log('\n📊 4. 测试 TokenInfo');
        await testTokenInfo(mppCore);
        
        // 5. 测试 LLM 服务集成
        console.log('\n🤖 5. 测试 LLM 服务集成');
        await testLLMServiceIntegration(mppCore);
        
        console.log('\n✅ 所有测试通过！');
        
    } catch (error) {
        console.error('\n❌ 测试失败:', error.message);
        console.error(error.stack);
        process.exit(1);
    }
}

async function checkBuildArtifacts() {
    const buildPath = 'mpp-core/build/packages/js';
    
    if (!fs.existsSync(buildPath)) {
        throw new Error(`构建产物不存在: ${buildPath}`);
    }
    
    const packageJson = path.join(buildPath, 'package.json');
    if (!fs.existsSync(packageJson)) {
        throw new Error(`package.json 不存在: ${packageJson}`);
    }
    
    console.log('   ✅ 构建产物检查通过');
}

async function loadMppCore() {
    try {
        const MppCore = require('../../mpp-core/build/packages/js');
        
        console.log('   📋 可用的模块:');
        console.log('   - cc.unitmesh.llm:', Object.keys(MppCore.cc?.unitmesh?.llm || {}));
        console.log('   - cc.unitmesh.llm.compression:', Object.keys(MppCore.cc?.unitmesh?.llm?.compression || {}));
        
        return MppCore;
        
    } catch (error) {
        throw new Error(`加载 mpp-core 失败: ${error.message}`);
    }
}

async function testCompressionConfig(mppCore) {
    const { JsCompressionConfig } = mppCore.cc.unitmesh.llm;

    if (!JsCompressionConfig) {
        throw new Error('JsCompressionConfig 类未找到');
    }

    // 测试默认配置
    const defaultConfig = new JsCompressionConfig();
    console.log('   ✅ 默认配置创建成功');
    console.log(`      阈值: ${defaultConfig.contextPercentageThreshold}`);
    console.log(`      保留比例: ${defaultConfig.preserveRecentRatio}`);
    console.log(`      自动压缩: ${defaultConfig.autoCompressionEnabled}`);

    // 测试自定义配置
    const customConfig = new JsCompressionConfig(0.8, 0.2, false, 10);
    console.log('   ✅ 自定义配置创建成功');
    console.log(`      自定义阈值: ${customConfig.contextPercentageThreshold}`);
}

async function testTokenInfo(mppCore) {
    const { JsTokenInfo } = mppCore.cc.unitmesh.llm;

    if (!JsTokenInfo) {
        throw new Error('JsTokenInfo 类未找到');
    }

    // 测试默认 TokenInfo
    const defaultTokenInfo = new JsTokenInfo();
    console.log('   ✅ 默认 TokenInfo 创建成功');
    console.log(`      总 tokens: ${defaultTokenInfo.totalTokens}`);
    console.log(`      输入 tokens: ${defaultTokenInfo.inputTokens}`);

    // 测试自定义 TokenInfo
    const customTokenInfo = new JsTokenInfo(1000, 600, 400, Date.now());

    // 测试使用率计算
    const usage = customTokenInfo.getUsagePercentage(1000);
    console.log(`   ✅ 使用率计算: ${usage}%`);

    // 测试压缩需求检查
    const needsCompression = customTokenInfo.needsCompression(1000, 0.7);
    console.log(`   ✅ 压缩需求检查: ${needsCompression ? '需要' : '不需要'}`);
}

async function testLLMServiceIntegration(mppCore) {
    const { JsModelConfig, JsKoogLLMService, JsCompressionConfig } = mppCore.cc.unitmesh.llm;

    if (!JsModelConfig || !JsKoogLLMService) {
        throw new Error('LLM 服务类未找到');
    }

    // 创建模型配置
    const modelConfig = new JsModelConfig(
        'OPENAI',
        'gpt-3.5-turbo',
        'test-key',
        0.7,
        1000,
        'https://api.openai.com/v1'
    );

    const compressionConfig = new JsCompressionConfig();

    // 创建 LLM 服务
    const llmService = new JsKoogLLMService(modelConfig, compressionConfig);
    console.log('   ✅ LLM 服务创建成功');

    // 测试基本方法
    const maxTokens = llmService.getMaxTokens();
    console.log(`   ✅ 最大 tokens: ${maxTokens}`);

    const tokenInfo = llmService.getLastTokenInfo();
    console.log(`   ✅ 初始 token 信息: 输入=${tokenInfo.inputTokens}, 输出=${tokenInfo.outputTokens}`);

    // 重置压缩状态
    llmService.resetCompressionState();
    console.log('   ✅ 压缩状态重置成功');
}

// 运行测试
main().catch(console.error);
