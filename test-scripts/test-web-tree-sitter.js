#!/usr/bin/env node
/**
 * Test script to verify web-tree-sitter integration in mpp-codegraph
 * 
 * This script tests:
 * 1. Whether web-tree-sitter can be loaded
 * 2. Whether the mpp-codegraph CodeParser can parse code
 * 3. Whether the parsed results are correct
 * 
 * Run from mpp-ui directory:
 *   node ../docs/test-scripts/test-web-tree-sitter.js
 */

const mppCore = require('@autodev/mpp-core');
const fs = require('fs');
const path = require('path');

const { cc: KotlinCC } = mppCore;

// Test code samples
const JAVA_CODE = `
package com.example;

public class HelloWorld {
    private String name;
    
    public void sayHello() {
        System.out.println("Hello, " + name);
    }
    
    public String getName() {
        return name;
    }
}
`;

const KOTLIN_CODE = `
package com.example

class Greeting {
    private val message: String = "Hello"
    
    fun greet(name: String): String {
        return "$message, $name!"
    }
}
`;

const TYPESCRIPT_CODE = `
interface User {
    name: string;
    age: number;
}

class UserService {
    private users: User[] = [];
    
    addUser(user: User): void {
        this.users.push(user);
    }
    
    getUsers(): User[] {
        return this.users;
    }
}
`;

async function testWebTreeSitter() {
    console.log('\n🧪 Testing web-tree-sitter integration\n');
    console.log('='.repeat(60));
    
    // Test 1: Check if web-tree-sitter module can be loaded
    console.log('\n📦 Test 1: Loading web-tree-sitter module...');
    let TreeSitter;
    try {
        TreeSitter = require('web-tree-sitter');
        console.log('✅ web-tree-sitter module loaded successfully');
        console.log(`   Module type: ${typeof TreeSitter}`);
    } catch (error) {
        console.log('❌ Failed to load web-tree-sitter:', error.message);
        console.log('\n   This means the module is NOT available to the CLI.');
        console.log('   Check if web-tree-sitter is in node_modules.');
        return false;
    }
    
    // Test 2: Check if @unit-mesh/treesitter-artifacts exists
    console.log('\n📦 Test 2: Loading treesitter-artifacts...');
    let wasmDir;
    try {
        const artifactsPath = require.resolve('@unit-mesh/treesitter-artifacts/package.json');
        console.log('✅ treesitter-artifacts found at:', artifactsPath);
        
        // Check for WASM files
        wasmDir = path.join(path.dirname(artifactsPath), 'wasm');
        if (fs.existsSync(wasmDir)) {
            const wasmFiles = fs.readdirSync(wasmDir).filter(f => f.endsWith('.wasm'));
            console.log(`   Found ${wasmFiles.length} WASM grammar files`);
            console.log(`   Languages: ${wasmFiles.slice(0, 5).join(', ')}...`);
        }
    } catch (error) {
        console.log('❌ Failed to load treesitter-artifacts:', error.message);
    }
    
    // Test 3: Try to use mpp-codegraph CodeParser
    console.log('\n📦 Test 3: Testing mpp-codegraph CodeParser...');
    try {
        // Check if CodeGraphFactory exists
        const CodeGraphFactory = KotlinCC.unitmesh.codegraph?.CodeGraphFactory;
        if (CodeGraphFactory) {
            console.log('✅ CodeGraphFactory found in mpp-core exports');
            
            const parser = CodeGraphFactory.createParser();
            console.log('✅ Parser created:', typeof parser);
            
            // Try to parse Java code
            console.log('\n   Parsing Java code...');
            const javaNodes = await parser.parseNodes(JAVA_CODE, 'HelloWorld.java', 'JAVA');
            console.log(`   ✅ Parsed ${javaNodes.length} nodes from Java code`);
            if (javaNodes.length > 0) {
                console.log('   Nodes found:');
                javaNodes.forEach(node => {
                    console.log(`     - ${node.type}: ${node.name}`);
                });
            }
        } else {
            console.log('⚠️  CodeGraphFactory not found in exports');
            console.log('   Available exports:', Object.keys(KotlinCC.unitmesh || {}).join(', '));
        }
    } catch (error) {
        console.log('❌ CodeParser test failed:', error.message);
        console.log('   Stack:', error.stack?.split('\n').slice(0, 3).join('\n'));
    }
    
    // Test 4: Test direct web-tree-sitter initialization
    console.log('\n📦 Test 4: Direct web-tree-sitter initialization...');
    try {
        // Initialize TreeSitter
        await TreeSitter.init();
        console.log('✅ TreeSitter.init() succeeded');
        
        // Create parser
        const parser = new TreeSitter();
        console.log('✅ TreeSitter parser created');
        
        // Try to load a language
        if (!wasmDir) {
            const artifactsPath = require.resolve('@unit-mesh/treesitter-artifacts/package.json');
            wasmDir = path.join(path.dirname(artifactsPath), 'wasm');
        }
        const javaWasm = path.join(wasmDir, 'tree-sitter-java.wasm');
        
        if (fs.existsSync(javaWasm)) {
            const Java = await TreeSitter.Language.load(javaWasm);
            parser.setLanguage(Java);
            console.log('✅ Java language loaded');
            
            // Parse code
            const tree = parser.parse(JAVA_CODE);
            console.log('✅ Code parsed successfully');
            console.log(`   Root node type: ${tree.rootNode.type}`);
            console.log(`   Child count: ${tree.rootNode.childCount}`);
            
            // Walk the tree to find class and methods
            const nodes = [];
            function walk(node, depth = 0) {
                if (['class_declaration', 'method_declaration', 'field_declaration'].includes(node.type)) {
                    nodes.push({ type: node.type, text: node.text.substring(0, 50) + '...' });
                }
                for (let i = 0; i < node.childCount; i++) {
                    walk(node.child(i), depth + 1);
                }
            }
            walk(tree.rootNode);
            
            console.log(`   Found ${nodes.length} relevant nodes:`);
            nodes.forEach(n => console.log(`     - ${n.type}`));
        } else {
            console.log('❌ Java WASM file not found at:', javaWasm);
        }
    } catch (error) {
        console.log('❌ Direct web-tree-sitter test failed:', error.message);
        console.log('   Stack:', error.stack?.split('\n').slice(0, 5).join('\n'));
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('🏁 Test complete\n');
    
    return true;
}

// Run the test
testWebTreeSitter().catch(console.error);

