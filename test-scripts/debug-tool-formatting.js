#!/usr/bin/env node

/**
 * Debug script to test tool formatting directly
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

async function debugToolFormatting() {
    console.log('🔍 Debugging Tool Formatting');
    console.log('=' * 50);
    
    const testDir = '/tmp/debug-tool-format';
    
    // Clean up and create test directory
    if (fs.existsSync(testDir)) {
        fs.rmSync(testDir, { recursive: true });
    }
    fs.mkdirSync(testDir, { recursive: true });
    
    console.log('Running CLI with verbose output to capture tool formatting...');
    
    try {
        const result = await runCLIWithOutput([
            'code',
            '--path', testDir,
            '--task', 'List the available tools and show their detailed information',
            '--max-iterations', '1'
        ]);
        
        console.log('\n📄 CLI Output Analysis:');
        console.log('Total output length:', result.length);
        
        // Look for tool-related patterns
        const patterns = [
            { name: 'Tool XML tags', pattern: /<tool name=/ },
            { name: 'Tool descriptions', pattern: /<description>/ },
            { name: 'Tool parameters', pattern: /<parameters>/ },
            { name: 'Tool examples', pattern: /<example>/ },
            { name: 'Simple tool format', pattern: /\/\w+\s+\w+/ },
            { name: 'Available Tools section', pattern: /Available Tools|可用工具/ },
            { name: 'DevIns commands', pattern: /DevIns commands/ }
        ];
        
        patterns.forEach(({ name, pattern }) => {
            const matches = result.match(pattern);
            const count = matches ? matches.length : 0;
            console.log(`   ${count > 0 ? '✓' : '✗'} ${name}: ${count} matches`);
        });
        
        // Extract tool list section if present
        const toolSectionMatch = result.match(/## Available Tools[\s\S]*?(?=##|$)/);
        if (toolSectionMatch) {
            console.log('\n📋 Tool Section Found:');
            console.log('---');
            console.log(toolSectionMatch[0].substring(0, 500) + '...');
            console.log('---');
        } else {
            console.log('\n❌ No tool section found in output');
        }
        
        // Look for specific tool names
        const toolNames = ['read-file', 'write-file', 'shell', 'grep', 'glob'];
        console.log('\n🔧 Tool Name Detection:');
        toolNames.forEach(toolName => {
            const found = result.includes(toolName);
            console.log(`   ${found ? '✓' : '✗'} ${toolName}: ${found ? 'found' : 'not found'}`);
        });
        
    } catch (error) {
        console.log('❌ Error running CLI:', error.message);
    }
}

function runCLIWithOutput(args) {
    return new Promise((resolve, reject) => {
        const cliPath = path.join(__dirname, '../../mpp-ui/dist/index.js');
        const child = spawn('node', [cliPath, ...args], {
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        let stdout = '';
        let stderr = '';
        
        child.stdout.on('data', (data) => {
            const text = data.toString();
            stdout += text;
            // Also log to console for real-time debugging
            process.stdout.write(text);
        });
        
        child.stderr.on('data', (data) => {
            const text = data.toString();
            stderr += text;
            process.stderr.write(text);
        });
        
        child.on('close', (code) => {
            resolve(stdout + stderr); // Include both stdout and stderr
        });
        
        // Set timeout
        setTimeout(() => {
            child.kill();
            resolve(stdout + stderr);
        }, 45000);
    });
}

// Helper function
String.prototype.repeat = String.prototype.repeat || function(count) {
    return new Array(count + 1).join(this);
};

// Run the debug
debugToolFormatting().catch(error => {
    console.error('❌ Debug failed:', error.message);
    process.exit(1);
});
