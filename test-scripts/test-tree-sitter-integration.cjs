#!/usr/bin/env node
/**
 * Test script to verify web-tree-sitter integration with mpp-codegraph
 * 
 * Run from mpp-ui directory:
 *   cd mpp-ui && node ../docs/test-scripts/test-tree-sitter-integration.cjs
 * 
 * Or run directly (will auto-detect mpp-ui location):
 *   node docs/test-scripts/test-tree-sitter-integration.cjs
 * 
 * This verifies:
 * 1. web-tree-sitter module is accessible
 * 2. treesitter-artifacts WASM files are available
 * 3. Direct parsing works
 * 4. Document registration through mpp-core works
 */

const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

// Find mpp-ui directory (either cwd or relative to script)
function findMppUiDir() {
    const candidates = [
        process.cwd(),
        path.join(process.cwd(), 'mpp-ui'),
        path.join(__dirname, '../../mpp-ui')
    ];
    
    for (const dir of candidates) {
        if (fs.existsSync(path.join(dir, 'package.json'))) {
            const pkg = JSON.parse(fs.readFileSync(path.join(dir, 'package.json'), 'utf-8'));
            if (pkg.name === '@autodev/cli') {
                return dir;
            }
        }
    }
    
    console.error('❌ Could not find mpp-ui directory');
    console.error('   Run this script from the mpp-ui directory or project root');
    process.exit(1);
}

const mppUiDir = findMppUiDir();
console.log('📁 Using mpp-ui at:', mppUiDir);

// Create require function that resolves from mpp-ui's node_modules
const mppRequire = createRequire(path.join(mppUiDir, 'package.json'));

const JAVA_CODE = `
package com.example;

public class HelloWorld {
    private String name;
    
    public void sayHello() {
        System.out.println("Hello, " + name);
    }
}
`;

async function main() {
    console.log('\n🧪 web-tree-sitter Integration Test\n');
    console.log('='.repeat(60));
    
    let allPassed = true;
    
    // Test 1: Check web-tree-sitter module
    console.log('\n📦 Test 1: web-tree-sitter module availability');
    try {
        const TreeSitter = mppRequire('web-tree-sitter');
        console.log('✅ PASSED - web-tree-sitter loaded');
    } catch (error) {
        console.log('❌ FAILED -', error.message);
        allPassed = false;
    }
    
    // Test 2: Check treesitter-artifacts
    console.log('\n📦 Test 2: treesitter-artifacts WASM files');
    try {
        const pkgPath = mppRequire.resolve('@unit-mesh/treesitter-artifacts/package.json');
        const wasmDir = path.join(path.dirname(pkgPath), 'wasm');
        const wasmFiles = fs.readdirSync(wasmDir).filter(f => f.endsWith('.wasm'));
        console.log(`✅ PASSED - Found ${wasmFiles.length} WASM grammars`);
    } catch (error) {
        console.log('❌ FAILED -', error.message);
        allPassed = false;
    }
    
    // Test 3: Direct tree-sitter parsing
    console.log('\n📦 Test 3: Direct tree-sitter parsing');
    try {
        const TreeSitter = mppRequire('web-tree-sitter');
        await TreeSitter.init();
        
        const parser = new TreeSitter();
        const pkgPath = mppRequire.resolve('@unit-mesh/treesitter-artifacts/package.json');
        const wasmDir = path.join(path.dirname(pkgPath), 'wasm');
        const javaWasm = path.join(wasmDir, 'tree-sitter-java.wasm');
        
        const Java = await TreeSitter.Language.load(javaWasm);
        parser.setLanguage(Java);
        
        const tree = parser.parse(JAVA_CODE);
        console.log(`✅ PASSED - Parsed Java code (root: ${tree.rootNode.type})`);
    } catch (error) {
        console.log('❌ FAILED -', error.message);
        allPassed = false;
    }
    
    // Test 4: Document registration via mpp-core
    console.log('\n📦 Test 4: mpp-core document registration');
    try {
        const mppCore = mppRequire('@autodev/mpp-core');
        const { cc: KotlinCC } = mppCore;
        
        KotlinCC.unitmesh.llm.JsDocumentRegistry.initializePlatformParsers();
        
        const mockLlmService = new KotlinCC.unitmesh.llm.JsKoogLLMService(
            new KotlinCC.unitmesh.llm.JsModelConfig('OPENAI', 'gpt-4', 'test-key', 0.7, 8192, '')
        );
        
        const dummyParser = KotlinCC.unitmesh.llm.JsDocumentParserFactory.createParserForFile('dummy.md');
        const agent = new KotlinCC.unitmesh.agent.JsDocumentAgent(mockLlmService, dummyParser, null, null);
        
        const result = await agent.registerDocument('Test.java', JAVA_CODE);
        console.log(`✅ PASSED - Document registration: ${result ? 'success' : 'skipped'}`);
    } catch (error) {
        console.log('❌ FAILED -', error.message);
        if (error.message.includes("Cannot find module 'web-tree-sitter'")) {
            console.log('   💡 FIX: Run "npm run build:kotlin-deps" to install dependencies');
        }
        allPassed = false;
    }
    
    console.log('\n' + '='.repeat(60));
    console.log(allPassed ? '✅ All tests passed!' : '❌ Some tests failed');
    console.log();
    
    process.exit(allPassed ? 0 : 1);
}

main().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});

