#!/usr/bin/env node

/**
 * Simple test to verify GLM provider is recognized
 */

import { JsKoogLLMService } from '../../mpp-core/build/packages/js/autodev-mpp-core.js';

// Test config with GLM provider
const testConfig = {
  providerName: 'glm',
  modelName: 'glm-4-plus',
  apiKey: 'test-api-key',
  temperature: 0.7,
  maxTokens: 128000,
  baseUrl: 'https://open.bigmodel.cn/api/paas/v4/'
};

try {
  console.log('Testing GLM provider recognition...');
  console.log('Test config:', JSON.stringify(testConfig, null, 2));
  
  const service = new JsKoogLLMService(testConfig);
  console.log('✅ SUCCESS: GLM provider recognized!');
  console.log('Service created successfully:', !!service);
  
  // Test other new providers
  console.log('\nTesting QWEN provider...');
  const qwenService = new JsKoogLLMService({
    ...testConfig,
    providerName: 'qwen',
    modelName: 'qwen-max'
  });
  console.log('✅ SUCCESS: QWEN provider recognized!');
  
  console.log('\nTesting KIMI provider...');
  const kimiService = new JsKoogLLMService({
    ...testConfig,
    providerName: 'kimi',
    modelName: 'moonshot-v1-32k'
  });
  console.log('✅ SUCCESS: KIMI provider recognized!');
  
  console.log('\nTesting CUSTOM_OPENAI_BASE provider...');
  const customService = new JsKoogLLMService({
    ...testConfig,
    providerName: 'custom_openai_base',
    modelName: 'custom-model'
  });
  console.log('✅ SUCCESS: CUSTOM_OPENAI_BASE provider recognized!');
  
  console.log('\n🎉 All provider tests passed!');
  process.exit(0);
} catch (error) {
  console.error('❌ FAILED: Error creating service');
  console.error('Error:', error.message);
  console.error('Stack:', error.stack);
  process.exit(1);
}

