#!/usr/bin/env node

/**
 * Test script to simulate tool output and analyze logging issues
 */

import { TuiRenderer } from '../../mpp-ui/dist/jsMain/typescript/agents/render/TuiRenderer.js';

// Mock context
const mockContext = {
  addMessage: (message) => {
    console.log(`\n=== ${message.role.toUpperCase()} MESSAGE ===`);
    console.log(message.content);
    console.log('='.repeat(50));
  },
  setPendingMessage: (message) => {
    if (message) {
      console.log(`\n--- PENDING: ${message.content.substring(0, 100)}...`);
    } else {
      console.log('\n--- PENDING CLEARED ---');
    }
  },
  setIsCompiling: (compiling) => console.log(`[COMPILING] ${compiling}`),
  clearMessages: () => console.log('[CLEAR] Messages cleared'),
  logger: {
    info: (msg) => console.log(`[INFO] ${msg}`),
    warn: (msg) => console.log(`[WARN] ${msg}`),
    error: (msg, err) => console.log(`[ERROR] ${msg}`, err || '')
  }
};

async function testToolOutputs() {
  console.log('🧪 Testing Tool Output Rendering...\n');

  const renderer = new TuiRenderer(mockContext);

  // Test 1: Simulate list-files tool with lots of output
  console.log('📁 Testing list-files tool output...');
  renderer.renderToolCall('list-files', '{"path": ".", "recursive": true}');
  
  // Simulate a very long file list
  const longFileList = Array.from({length: 100}, (_, i) => 
    `src/main/java/com/example/package${i}/SomeVeryLongClassName${i}.java`
  ).join('\n');
  
  renderer.renderToolResult('list-files', true, longFileList, longFileList);

  console.log('\n' + '='.repeat(80) + '\n');

  // Test 2: Simulate read-file tool with large file content
  console.log('📄 Testing read-file tool output...');
  renderer.renderToolCall('read-file', '{"path": "src/main/java/LargeFile.java"}');
  
  const largeFileContent = Array.from({length: 200}, (_, i) => 
    `    // Line ${i + 1}: This is a comment explaining some complex business logic`
  ).join('\n');
  
  renderer.renderToolResult('read-file', true, largeFileContent, largeFileContent);

  console.log('\n' + '='.repeat(80) + '\n');

  // Test 3: Simulate shell command with verbose output
  console.log('🔧 Testing shell command output...');
  renderer.renderToolCall('shell', '{"command": "npm install --verbose"}');
  
  const verboseNpmOutput = Array.from({length: 150}, (_, i) => 
    `npm info ${i}: Installing package-${i}@1.0.${i} from registry...`
  ).join('\n');
  
  renderer.renderToolResult('shell', true, verboseNpmOutput, verboseNpmOutput);

  console.log('\n' + '='.repeat(80) + '\n');

  // Test 4: Simulate iteration headers and LLM responses
  console.log('🤖 Testing iteration and LLM output...');
  
  for (let i = 1; i <= 3; i++) {
    renderer.renderIterationHeader(i, 10);
    
    renderer.renderLLMResponseStart();
    
    // Simulate streaming response
    const chunks = [
      'I need to analyze the codebase structure first.',
      ' Let me start by examining the project files.',
      '\n\nBased on my analysis, I can see that this is a complex project with multiple modules.',
      ' I should break this down into smaller tasks.',
      '\n\n```typescript\n// Here is some code example\nfunction example() {\n  return "hello";\n}\n```',
      '\n\nThis approach will ensure better maintainability and scalability.'
    ];
    
    for (const chunk of chunks) {
      renderer.renderLLMResponseChunk(chunk);
    }
    
    renderer.renderLLMResponseEnd();
  }

  console.log('\n🎯 Analysis Complete!');
  console.log('\nIssues identified:');
  console.log('1. Tool outputs are not truncated - can flood the screen');
  console.log('2. No visual separation between different tool calls');
  console.log('3. Iteration headers might be too verbose');
  console.log('4. Large file contents are displayed in full');
  console.log('5. No summary/preview for long outputs');
}

testToolOutputs().catch(console.error);
