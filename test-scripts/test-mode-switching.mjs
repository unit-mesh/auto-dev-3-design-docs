#!/usr/bin/env node

/**
 * Test script for mode switching functionality
 * Tests the ModeManager and mode switching logic
 */

import { ModeManager, AgentModeFactory, ChatModeFactory } from '../../mpp-ui/dist/jsMain/typescript/modes/index.js';

async function testModeManager() {
  console.log('🧪 Testing Mode Manager...\n');

  const modeManager = new ModeManager();
  
  // Register modes
  console.log('📝 Registering modes...');
  modeManager.registerMode(new AgentModeFactory());
  modeManager.registerMode(new ChatModeFactory());
  
  const availableModes = modeManager.getAvailableModes();
  console.log(`✅ Available modes: ${availableModes.join(', ')}\n`);

  // Test mode info
  console.log('📋 Mode information:');
  for (const modeType of availableModes) {
    const info = modeManager.getModeInfo(modeType);
    if (info) {
      console.log(`  ${info.icon} ${info.displayName}: ${info.description}`);
    }
  }
  console.log();

  // Mock context
  const mockContext = {
    addMessage: (message) => console.log(`[MESSAGE] ${message.role}: ${message.content}`),
    setPendingMessage: (message) => console.log(`[PENDING] ${message ? message.content : 'null'}`),
    setIsCompiling: (compiling) => console.log(`[COMPILING] ${compiling}`),
    clearMessages: () => console.log('[CLEAR] Messages cleared'),
    logger: {
      info: (msg) => console.log(`[INFO] ${msg}`),
      warn: (msg) => console.log(`[WARN] ${msg}`),
      error: (msg, err) => console.log(`[ERROR] ${msg}`, err || '')
    },
    projectPath: process.cwd(),
    llmConfig: {
      provider: 'deepseek',
      model: 'deepseek-chat',
      apiKey: 'test-key',
      baseUrl: 'https://api.deepseek.com'
    }
  };

  // Test mode switching
  console.log('🔄 Testing mode switching...\n');

  try {
    // Switch to agent mode
    console.log('Switching to agent mode...');
    const agentSuccess = await modeManager.switchToMode('agent', mockContext);
    console.log(`Agent mode switch: ${agentSuccess ? '✅ Success' : '❌ Failed'}\n`);

    if (agentSuccess) {
      const currentMode = modeManager.getCurrentMode();
      console.log(`Current mode: ${currentMode?.type} - ${currentMode?.mode.getStatus()}\n`);
    }

    // Switch to chat mode
    console.log('Switching to chat mode...');
    const chatSuccess = await modeManager.switchToMode('chat', mockContext);
    console.log(`Chat mode switch: ${chatSuccess ? '✅ Success' : '❌ Failed'}\n`);

    if (chatSuccess) {
      const currentMode = modeManager.getCurrentMode();
      console.log(`Current mode: ${currentMode?.type} - ${currentMode?.mode.getStatus()}\n`);
    }

    // Test invalid mode
    console.log('Testing invalid mode...');
    const invalidSuccess = await modeManager.switchToMode('invalid', mockContext);
    console.log(`Invalid mode switch: ${invalidSuccess ? '❌ Unexpected success' : '✅ Expected failure'}\n`);

  } catch (error) {
    console.error('❌ Error during mode switching:', error);
  }

  // Cleanup
  await modeManager.cleanup();
  console.log('🧹 Cleanup completed');
}

// Run the test
testModeManager().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
