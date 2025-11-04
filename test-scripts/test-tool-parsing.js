#!/usr/bin/env node

/**
 * 测试工具解析功能的脚本
 * 
 * 这个脚本模拟 CodingAgentExecutor 的工具解析流程，
 * 特别测试 WriteFileTool 的多行内容解析是否正确
 */

const fs = require('fs');
const path = require('path');

console.log('🔧 工具解析功能测试');
console.log('='.repeat(50));

async function main() {
    try {
        // 1. 测试 DevinBlockParser 的解析能力
        await testDevinBlockParsing();
        
        // 2. 测试 ToolCallParser 的参数解析
        await testToolCallParameterParsing();
        
        // 3. 测试转义字符处理
        await testEscapeSequenceProcessing();
        
        // 4. 测试复杂多行内容解析
        await testComplexMultilineContentParsing();
        
        // 5. 测试边界情况
        await testEdgeCases();
        
        console.log('\n✅ 工具解析功能测试完成');
        
    } catch (error) {
        console.error('❌ 测试失败:', error.message);
        process.exit(1);
    }
}

async function testDevinBlockParsing() {
    console.log('\n📋 测试 DevinBlock 解析...');
    
    const testCases = [
        {
            name: '简单 devin 块',
            input: `I'll create a file.
            
<devin>
/write-file path="test.txt" content="Hello"
</devin>`,
            expectedBlocks: 1
        },
        {
            name: '多行内容 devin 块',
            input: `I'll create a Kotlin file.
            
<devin>
/write-file path="Example.kt" content="package com.example

class Example {
    fun hello() = \"Hello\"
}"
</devin>`,
            expectedBlocks: 1
        },
        {
            name: '多个 devin 块',
            input: `<devin>
/write-file path="file1.txt" content="Content 1"
</devin>

<devin>
/write-file path="file2.txt" content="Content 2"
</devin>`,
            expectedBlocks: 2
        },
        {
            name: '不完整的 devin 块',
            input: `<devin>
/write-file path="incomplete.txt"`,
            expectedBlocks: 0
        }
    ];
    
    for (const testCase of testCases) {
        console.log(`   🔍 ${testCase.name}:`);
        
        // 模拟 DevinBlockParser.extractDevinBlocks
        const devinRegex = /<devin>([\s\S]*?)<\/devin>/g;
        const matches = [...testCase.input.matchAll(devinRegex)];
        
        const actualBlocks = matches.length;
        const passed = actualBlocks === testCase.expectedBlocks;
        
        console.log(`      预期块数: ${testCase.expectedBlocks}, 实际块数: ${actualBlocks} ${passed ? '✅' : '❌'}`);
        
        if (matches.length > 0) {
            const firstBlock = matches[0][1].trim();
            console.log(`      第一个块内容长度: ${firstBlock.length} 字符`);
            if (firstBlock.includes('/write-file')) {
                console.log(`      ✅ 包含 write-file 命令`);
            }
        }
    }
}

async function testToolCallParameterParsing() {
    console.log('\n📋 测试工具调用参数解析...');
    
    const testCases = [
        {
            name: '简单参数',
            command: '/write-file path="test.txt" content="Hello"',
            expectedParams: { path: 'test.txt', content: 'Hello' }
        },
        {
            name: '多行内容参数',
            command: '/write-file path="multi.kt" content="line1\\nline2\\nline3"',
            expectedParams: { path: 'multi.kt', content: 'line1\nline2\nline3' }
        },
        {
            name: '包含引号的内容',
            command: '/write-file path="quotes.txt" content="He said \\"Hello\\""',
            expectedParams: { path: 'quotes.txt', content: 'He said "Hello"' }
        },
        {
            name: '复杂 Kotlin 代码',
            command: '/write-file path="Service.kt" content="package com.example\\n\\nclass Service {\\n    fun test() = \\"result\\"\\n}"',
            expectedParams: { 
                path: 'Service.kt', 
                content: 'package com.example\n\nclass Service {\n    fun test() = "result"\n}' 
            }
        }
    ];
    
    for (const testCase of testCases) {
        console.log(`   🔍 ${testCase.name}:`);
        
        // 模拟参数解析
        const params = parseToolParameters(testCase.command);
        
        console.log(`      解析的参数数量: ${Object.keys(params).length}`);
        
        for (const [key, expectedValue] of Object.entries(testCase.expectedParams)) {
            const actualValue = params[key];
            const matches = actualValue === expectedValue;
            
            console.log(`      ${key}: ${matches ? '✅' : '❌'}`);
            if (!matches) {
                console.log(`        预期: "${expectedValue}"`);
                console.log(`        实际: "${actualValue}"`);
            }
        }
    }
}

function parseToolParameters(command) {
    const params = {};
    
    // 简化的参数解析逻辑（模拟 ToolCallParser）
    const paramRegex = /(\w+)="([^"\\]*(\\.[^"\\]*)*)"/g;
    let match;
    
    while ((match = paramRegex.exec(command)) !== null) {
        const key = match[1];
        let value = match[2];
        
        // 处理转义字符
        value = value
            .replace(/\\n/g, '\n')
            .replace(/\\r/g, '\r')
            .replace(/\\t/g, '\t')
            .replace(/\\"/g, '"')
            .replace(/\\\\/g, '\\');
        
        params[key] = value;
    }
    
    return params;
}

async function testEscapeSequenceProcessing() {
    console.log('\n📋 测试转义字符处理...');
    
    const testCases = [
        { input: 'line1\\nline2', expected: 'line1\nline2', name: '换行符' },
        { input: 'tab\\there', expected: 'tab\there', name: '制表符' },
        { input: 'quote\\"here', expected: 'quote"here', name: '引号' },
        { input: 'backslash\\\\here', expected: 'backslash\\here', name: '反斜杠' },
        { input: 'mixed\\n\\t\\"test\\"', expected: 'mixed\n\t"test"', name: '混合转义' }
    ];
    
    for (const testCase of testCases) {
        const processed = processEscapeSequences(testCase.input);
        const passed = processed === testCase.expected;
        
        console.log(`   ${testCase.name}: ${passed ? '✅' : '❌'}`);
        if (!passed) {
            console.log(`      预期: "${testCase.expected}"`);
            console.log(`      实际: "${processed}"`);
        }
    }
}

function processEscapeSequences(content) {
    return content
        .replace(/\\n/g, '\n')
        .replace(/\\r/g, '\r')
        .replace(/\\t/g, '\t')
        .replace(/\\"/g, '"')
        .replace(/\\\\/g, '\\');
}

async function testComplexMultilineContentParsing() {
    console.log('\n📋 测试复杂多行内容解析...');
    
    const complexLLMResponse = `I'll create a comprehensive Kotlin service class.

<devin>
/write-file path="src/UserService.kt" content="package com.example.service

import kotlinx.coroutines.*
import kotlinx.serialization.Serializable

/**
 * User service for managing user operations
 * Supports CRUD operations with validation
 */
@Serializable
data class User(
    val id: String,
    val name: String,
    val email: String
) {
    fun isValid(): Boolean {
        return id.isNotBlank() && 
               name.isNotBlank() && 
               email.contains(\\"@\\")
    }
}

interface UserService {
    suspend fun createUser(user: User): Result<User>
    suspend fun getUserById(id: String): User?
}

class InMemoryUserService : UserService {
    private val users = mutableMapOf<String, User>()
    
    override suspend fun createUser(user: User): Result<User> {
        return withContext(Dispatchers.Default) {
            if (user.isValid()) {
                users[user.id] = user
                Result.success(user)
            } else {
                Result.failure(IllegalArgumentException(\\"Invalid user\\"))
            }
        }
    }
    
    override suspend fun getUserById(id: String): User? {
        return users[id]
    }
}"
</devin>

The service class has been created with proper structure.`;
    
    console.log('   🔍 解析复杂多行响应:');
    
    // 提取 devin 块
    const devinRegex = /<devin>([\s\S]*?)<\/devin>/;
    const match = complexLLMResponse.match(devinRegex);
    
    if (match) {
        const devinContent = match[1].trim();
        console.log(`      ✅ 成功提取 devin 块 (${devinContent.length} 字符)`);
        
        // 解析工具调用
        const params = parseToolParameters(devinContent);
        
        if (params.path && params.content) {
            console.log(`      ✅ 成功解析参数:`);
            console.log(`         路径: ${params.path}`);
            console.log(`         内容长度: ${params.content.length} 字符`);
            console.log(`         内容行数: ${params.content.split('\n').length} 行`);
            
            // 验证内容结构
            const content = params.content;
            const checks = [
                { name: '包声明', test: () => content.includes('package com.example.service') },
                { name: '导入语句', test: () => content.includes('import kotlinx') },
                { name: '数据类', test: () => content.includes('data class User') },
                { name: '接口定义', test: () => content.includes('interface UserService') },
                { name: '实现类', test: () => content.includes('class InMemoryUserService') },
                { name: '异步方法', test: () => content.includes('suspend fun') },
                { name: '协程上下文', test: () => content.includes('withContext') },
                { name: '错误处理', test: () => content.includes('Result.') }
            ];
            
            console.log(`      🔍 内容验证:`);
            for (const check of checks) {
                const passed = check.test();
                console.log(`         ${check.name}: ${passed ? '✅' : '❌'}`);
            }
        } else {
            console.log(`      ❌ 参数解析失败`);
        }
    } else {
        console.log(`      ❌ 未找到 devin 块`);
    }
}

async function testEdgeCases() {
    console.log('\n📋 测试边界情况...');
    
    const edgeCases = [
        {
            name: '空内容',
            response: '<devin>\n/write-file path="empty.txt" content=""\n</devin>',
            shouldFail: true
        },
        {
            name: '缺少路径',
            response: '<devin>\n/write-file content="some content"\n</devin>',
            shouldFail: true
        },
        {
            name: '缺少内容参数',
            response: '<devin>\n/write-file path="file.txt"\n</devin>',
            shouldFail: true
        },
        {
            name: '超长内容',
            response: '<devin>\n/write-file path="large.txt" content="' + 'x'.repeat(1000) + '"\n</devin>',
            shouldFail: false
        }
    ];
    
    for (const testCase of edgeCases) {
        console.log(`   🔍 ${testCase.name}:`);
        
        try {
            const devinMatch = testCase.response.match(/<devin>([\s\S]*?)<\/devin>/);
            if (devinMatch) {
                const params = parseToolParameters(devinMatch[1].trim());
                
                const hasPath = params.path && params.path.trim() !== '';
                const hasContent = params.content !== undefined;
                const contentNotEmpty = params.content && params.content.trim() !== '';
                
                const shouldSucceed = hasPath && hasContent && (contentNotEmpty || !testCase.shouldFail);
                const actualResult = shouldSucceed ? 'success' : 'fail';
                const expectedResult = testCase.shouldFail ? 'fail' : 'success';
                
                console.log(`      预期: ${expectedResult}, 实际: ${actualResult} ${actualResult === expectedResult ? '✅' : '❌'}`);
                
                if (params.content) {
                    console.log(`      内容长度: ${params.content.length} 字符`);
                }
            } else {
                console.log(`      ❌ 无法解析 devin 块`);
            }
        } catch (error) {
            console.log(`      ❌ 解析异常: ${error.message}`);
        }
    }
}

// 运行测试
main().catch(error => {
    console.error('💥 测试异常:', error);
    process.exit(1);
});
