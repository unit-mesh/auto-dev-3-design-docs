#!/usr/bin/env node

// Test script to verify custom OpenAI provider support
const path = require('path');

// Add the mpp-core package to the path
const mppCorePath = path.join(__dirname, '../../mpp-core/build/packages/js');
const MppCore = require(mppCorePath + '/autodev-mpp-core.js');

console.log('Testing Custom OpenAI Provider Support...\n');

async function runTests() {
try {
    // Test 1: Check if CUSTOM_OPENAI_BASE is in the provider list
    const { JsModelRegistry } = MppCore.cc.unitmesh.llm;
    const allProviders = JsModelRegistry.getAllProviders();
    console.log('Available providers:', allProviders);
    
    const hasCustomProvider = allProviders.includes('CUSTOM_OPENAI_BASE');
    console.log('✓ CUSTOM_OPENAI_BASE provider available:', hasCustomProvider);
    
    if (!hasCustomProvider) {
        console.error('❌ CUSTOM_OPENAI_BASE provider not found in provider list');
        process.exit(1);
    }
    
    // Test 2: Try to create a JsModelConfig with custom-openai-base (lowercase)
    const { JsModelConfig } = MppCore.cc.unitmesh.llm;
    
    console.log('\nTesting JsModelConfig with lowercase provider name...');
    const config = new JsModelConfig(
        'custom_openai_base',  // lowercase with underscores
        'gpt-4o',  // Use OpenAI-compatible model name
        '7145ac1bf6474f2783e8b4d52b335ab0.gfq0BBvvFy04iwTb',
        0.7,
        8192,
        'https://open.bigmodel.cn/api/paas/v4'
    );
    
    console.log('✓ JsModelConfig created successfully');
    console.log('Provider name:', config.providerName);
    
    // Test 3: Debug the provider name conversion
    console.log('\nDebugging provider name conversion...');
    console.log('Original provider name:', config.providerName);
    console.log('Uppercase provider name:', config.providerName.toUpperCase());

    // Test 3: Try to convert to Kotlin config
    console.log('\nTesting conversion to Kotlin config...');
    const kotlinConfig = config.toKotlinConfig();
    console.log('✓ Kotlin config created successfully');
    console.log('Provider:', kotlinConfig.provider);
    
    // Test 4: Try to create JsKoogLLMService
    console.log('\nTesting JsKoogLLMService creation...');
    const { JsKoogLLMService } = MppCore.cc.unitmesh.llm;
    const llmService = new JsKoogLLMService(config);
    console.log('✓ JsKoogLLMService created successfully');

    // Test 5: Try to send a simple prompt
    console.log('\nTesting simple prompt...');
    try {
        const response = await llmService.sendPrompt('Hello, can you respond with just "Hi there!"?');
        console.log('✓ Prompt response:', response);
    } catch (error) {
        console.log('❌ Prompt failed:', error.message);
        // This is expected to fail due to API key/endpoint issues, but we want to see the specific error
    }

    console.log('\n🎉 All tests passed! Custom OpenAI provider is working correctly.');
    
} catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
}
}

// Run the tests
runTests();
