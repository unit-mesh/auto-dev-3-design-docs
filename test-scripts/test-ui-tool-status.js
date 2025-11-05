#!/usr/bin/env node

/**
 * Simple test script to verify ToolLoadingStatus in a running UI
 * This script can be run while the UI is running to check the actual values
 */

const fs = require('fs');
const path = require('path');

async function testToolLoadingStatus() {
    console.log('🧪 Testing ToolLoadingStatus values...');
    
    try {
        // Method 1: Check if we can find any log output files
        const logPaths = [
            '/tmp/autodev-ui.log',
            './ui.log',
            './build/logs/ui.log'
        ];
        
        for (const logPath of logPaths) {
            if (fs.existsSync(logPath)) {
                console.log(`📋 Found log file: ${logPath}`);
                const logContent = fs.readFileSync(logPath, 'utf8');
                
                // Look for tool loading status logs
                const statusMatches = logContent.match(/\[getToolLoadingStatus\].*?MCP tools total: (\d+)/g);
                if (statusMatches) {
                    console.log('✅ Found ToolLoadingStatus logs:');
                    statusMatches.forEach(match => console.log(`   ${match}`));
                }
                
                const dialogMatches = logContent.match(/\[ToolConfigDialog\].*?MCP: (\d+)\/(\d+)/g);
                if (dialogMatches) {
                    console.log('✅ Found ToolConfigDialog logs:');
                    dialogMatches.forEach(match => console.log(`   ${match}`));
                }
            }
        }
        
        // Method 2: Create a simple test configuration
        console.log('\n🔧 Creating test configuration...');
        
        const testConfig = {
            enabledBuiltinTools: ['read-file', 'write-file', 'shell'],
            enabledMcpTools: ['list_files', 'read_file', 'write_file'], // 3 tools from config
            mcpServers: {
                filesystem: {
                    command: 'npx',
                    args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
                    env: {},
                    disabled: false
                },
                github: {
                    command: 'npx', 
                    args: ['-y', '@modelcontextprotocol/server-github'],
                    env: { GITHUB_PERSONAL_ACCESS_TOKEN: 'dummy' },
                    disabled: false
                }
            }
        };
        
        console.log('📊 Expected vs Actual:');
        console.log(`   Config enabled MCP tools: ${testConfig.enabledMcpTools.length}`);
        console.log(`   Expected discovered tools: ~40 (14 from filesystem + 26 from github)`);
        console.log(`   UI should show: ${testConfig.enabledMcpTools.length}/40 not ${testConfig.enabledMcpTools.length}/${testConfig.enabledMcpTools.length}`);
        
        // Method 3: Suggest direct testing approach
        console.log('\n💡 Direct testing suggestions:');
        console.log('1. Add debug logs to ToolConfigDialog.kt (already done)');
        console.log('2. Add debug logs to CodingAgentViewModel.getToolLoadingStatus()');
        console.log('3. Check console output when running the UI');
        console.log('4. Use browser dev tools if running as web app');
        
        return true;
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        return false;
    }
}

// Method 4: Create a minimal test that can be run alongside the UI
function createMinimalTest() {
    console.log('\n🚀 Minimal test approach:');
    console.log('Run this command in another terminal while UI is running:');
    console.log('');
    console.log('# Watch for debug logs:');
    console.log('tail -f /dev/stdout | grep -E "(ToolConfigDialog|getToolLoadingStatus|MCP.*tools)"');
    console.log('');
    console.log('# Or check the UI console output for:');
    console.log('- "🔍 [ToolConfigDialog] Tool counts:"');
    console.log('- "🔍 [getToolLoadingStatus] Debug info:"');
    console.log('');
    console.log('Expected output should show:');
    console.log('- MCP: 3/40 (3 enabled out of 40 discovered)');
    console.log('- NOT MCP: 3/3 (which indicates the bug)');
}

// Run the test
testToolLoadingStatus().then(success => {
    createMinimalTest();
    process.exit(success ? 0 : 1);
}).catch(error => {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
});
