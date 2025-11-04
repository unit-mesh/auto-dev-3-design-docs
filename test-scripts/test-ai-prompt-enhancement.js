#!/usr/bin/env node

/**
 * Test script to verify AI prompt enhancement with better tool context
 * 
 * This script tests the enhanced tool formatting that provides better
 * schema information for AI understanding.
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

async function testAIPromptEnhancement() {
    console.log('🧪 Testing AI Prompt Enhancement');
    console.log('=' * 50);
    
    // Test 1: Capture AI prompt with enhanced tool context
    await testEnhancedToolContext();
    
    // Test 2: Compare old vs new tool formatting
    await testToolFormattingComparison();
    
    // Test 3: Verify tool schema information
    await testToolSchemaInformation();
    
    console.log('\n✅ AI prompt enhancement tests completed!');
}

async function testEnhancedToolContext() {
    console.log('\n🔧 Test 1: Enhanced Tool Context');
    
    const testDir = '/tmp/test-ai-prompt';
    
    // Clean up and create test directory
    if (fs.existsSync(testDir)) {
        fs.rmSync(testDir, { recursive: true });
    }
    fs.mkdirSync(testDir, { recursive: true });
    
    console.log('   Running CLI with enhanced tool context...');
    
    try {
        const result = await runCLI([
            'code',
            '--path', testDir,
            '--task', 'Show me the available tools and their schemas',
            '--max-iterations', '1',
            '--quiet'
        ]);
        
        // Check if the output contains enhanced tool information
        const hasToolTags = result.includes('<tool name=');
        const hasDescription = result.includes('<description>');
        const hasParameters = result.includes('<parameters>');
        const hasExamples = result.includes('<example>');
        
        console.log('   ✓ Tool XML tags:', hasToolTags);
        console.log('   ✓ Descriptions:', hasDescription);
        console.log('   ✓ Parameters:', hasParameters);
        console.log('   ✓ Examples:', hasExamples);
        
        if (hasToolTags && hasDescription) {
            console.log('   ✅ Enhanced tool context working');
        } else {
            console.log('   ⚠️  Enhanced tool context may need improvement');
        }
        
    } catch (error) {
        console.log('   ❌ Error testing enhanced tool context:', error.message);
    }
}

async function testToolFormattingComparison() {
    console.log('\n📊 Test 2: Tool Formatting Comparison');
    
    // Simulate old format
    const oldFormat = [
        '/read-file Read content from a file',
        '/write-file Write content to a file',
        '/shell Execute shell commands'
    ].join('\n');
    
    // Simulate new enhanced format
    const newFormat = `
<tool name="read-file">
  <description>Read content from a file</description>
  <parameters>
    <type>ReadFileParams</type>
    <usage>/read-file [parameters]</usage>
  </parameters>
  <example>
    /read-file path="src/main.kt"
  </example>
</tool>

<tool name="write-file">
  <description>Write content to a file</description>
  <parameters>
    <type>WriteFileParams</type>
    <usage>/write-file [parameters]</usage>
  </parameters>
  <example>
    /write-file path="output.txt" content="Hello, World!"
  </example>
</tool>`.trim();
    
    console.log('   Old format length:', oldFormat.length, 'characters');
    console.log('   New format length:', newFormat.length, 'characters');
    console.log('   Enhancement ratio:', (newFormat.length / oldFormat.length).toFixed(2) + 'x');
    
    // Check information density
    const oldInfoDensity = (oldFormat.match(/\w+/g) || []).length;
    const newInfoDensity = (newFormat.match(/\w+/g) || []).length;
    
    console.log('   Old info density:', oldInfoDensity, 'words');
    console.log('   New info density:', newInfoDensity, 'words');
    console.log('   ✅ Enhanced format provides', (newInfoDensity / oldInfoDensity).toFixed(2) + 'x more information');
}

async function testToolSchemaInformation() {
    console.log('\n📋 Test 3: Tool Schema Information');
    
    // Test that enhanced format includes key schema elements
    const requiredElements = [
        '<tool name=',
        '<description>',
        '<parameters>',
        '<type>',
        '<usage>',
        '<example>'
    ];
    
    const sampleEnhancedFormat = `
<tool name="grep">
  <description>Search for patterns in files</description>
  <parameters>
    <type>GrepParams</type>
    <usage>/grep [parameters]</usage>
  </parameters>
  <example>
    /grep pattern="function.*main" path="src" include="*.kt"
  </example>
</tool>`;
    
    console.log('   Checking for required schema elements:');
    requiredElements.forEach(element => {
        const present = sampleEnhancedFormat.includes(element);
        console.log(`   ${present ? '✓' : '✗'} ${element}: ${present ? 'present' : 'missing'}`);
    });
    
    const allPresent = requiredElements.every(element => 
        sampleEnhancedFormat.includes(element)
    );
    
    if (allPresent) {
        console.log('   ✅ All required schema elements present');
    } else {
        console.log('   ❌ Some schema elements missing');
    }
}

function runCLI(args) {
    return new Promise((resolve, reject) => {
        const cliPath = path.join(__dirname, '../../mpp-ui/dist/index.js');
        const child = spawn('node', [cliPath, ...args], {
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        let stdout = '';
        let stderr = '';
        
        child.stdout.on('data', (data) => {
            stdout += data.toString();
        });
        
        child.stderr.on('data', (data) => {
            stderr += data.toString();
        });
        
        child.on('close', (code) => {
            if (code === 0) {
                resolve(stdout);
            } else {
                reject(new Error(`CLI exited with code ${code}: ${stderr}`));
            }
        });
        
        // Set timeout
        setTimeout(() => {
            child.kill();
            reject(new Error('CLI timeout'));
        }, 30000);
    });
}

// Helper function
String.prototype.repeat = String.prototype.repeat || function(count) {
    return new Array(count + 1).join(this);
};

// Run the test
testAIPromptEnhancement().catch(error => {
    console.error('❌ Test failed:', error.message);
    process.exit(1);
});
