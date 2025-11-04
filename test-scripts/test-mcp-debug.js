#!/usr/bin/env node

/**
 * Test script to debug MCP tool loading in CodingAgent
 */

const path = require('path');
const fs = require('fs');

async function testMcpToolLoading() {
    console.log('🧪 Testing MCP Tool Loading in CodingAgent');
    console.log('=' * 50);
    
    try {
        // Import the compiled mpp-core module
        const mppCore = require('../../mpp-core/build/compileSync/js/main/productionLibrary/kotlin/autodev-mpp-core.js');
        
        console.log('✅ Successfully imported mpp-core module');
        
        // Test tool config loading
        console.log('\n📁 Testing tool config loading...');
        const toolConfig = await mppCore.loadToolConfig();
        
        console.log('Tool config loaded:');
        console.log('  Enabled builtin tools:', toolConfig.enabledBuiltinTools.length);
        console.log('  Enabled MCP tools:', toolConfig.enabledMcpTools.length);
        console.log('  MCP servers:', Object.keys(toolConfig.mcpServers).length);
        
        if (toolConfig.enabledMcpTools.length > 0) {
            console.log('  MCP tools list:');
            toolConfig.enabledMcpTools.forEach(tool => {
                console.log(`    - ${tool}`);
            });
        }
        
        // Test CodingAgent initialization
        console.log('\n🤖 Testing CodingAgent initialization...');
        const agent = await mppCore.createCodingAgent();
        
        console.log('✅ CodingAgent created successfully');
        
        // Test tool registration
        console.log('\n🔧 Testing tool registration...');
        const registeredTools = agent.getRegisteredTools ? agent.getRegisteredTools() : [];
        console.log(`Registered tools: ${registeredTools.length}`);
        
        if (registeredTools.length > 0) {
            console.log('Registered tool names:');
            registeredTools.forEach(tool => {
                console.log(`  - ${tool.name || tool}`);
            });
        }
        
    } catch (error) {
        console.error('❌ Error during testing:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

// Helper function
function repeat(str, times) {
    return str.repeat(times);
}

// Run the test
testMcpToolLoading().then(() => {
    console.log('\n✅ Test completed');
}).catch(error => {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
});
