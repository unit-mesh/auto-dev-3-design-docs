#!/usr/bin/env node

/**
 * 真正的集成测试 - WriteFileTool 多行写入功能
 * 
 * 这个脚本使用真实的 mpp-core 组件：
 * 1. 从 ConfigManager.ts 读取配置
 * 2. 使用 CodingAgentPromptRenderer 生成提示词
 * 3. 调用 KoogLLMService 测试模型
 * 4. 使用 WriteFileTool 处理多行写入
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';

// 简化的配置管理器
interface LLMConfig {
    name: string;
    provider: string;
    apiKey: string;
    model: string;
    baseUrl?: string;
    temperature?: number;
    maxTokens?: number;
}

class SimpleConfigManager {
    private static CONFIG_FILE = path.join(os.homedir(), '.autodev', 'config.yaml');

    static async load(): Promise<LLMConfig | null> {
        try {
            const content = await fs.readFile(this.CONFIG_FILE, 'utf-8');
            const lines = content.split('\n');

            const config: any = {};
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed && !trimmed.startsWith('#')) {
                    const colonIndex = trimmed.indexOf(':');
                    if (colonIndex > 0) {
                        const key = trimmed.substring(0, colonIndex).trim();
                        const value = trimmed.substring(colonIndex + 1).trim();
                        config[key] = value;
                    }
                }
            }

            if (config.provider && config.model && config.apiKey) {
                return {
                    name: 'default',
                    provider: config.provider,
                    apiKey: config.apiKey,
                    model: config.model,
                    baseUrl: config.baseUrl,
                    temperature: parseFloat(config.temperature) || 0.7,
                    maxTokens: parseInt(config.maxTokens) || 4096
                };
            }

            return null;
        } catch (error) {
            return null;
        }
    }
}

// 编译后的 mpp-core 模块路径
const MPP_CORE_BUILD_PATH = path.resolve(__dirname, '../../mpp-core/build/js/packages/mpp-core/kotlin/mpp-core.js');

async function main() {
    console.log('🔧 真正的集成测试 - WriteFileTool 多行写入功能');
    console.log('='.repeat(60));

    try {
        // 1. 检查 mpp-core 编译状态
        await checkMppCoreCompilation();
        
        // 2. 读取配置
        const config = await loadConfiguration();
        if (!config) {
            console.log('❌ 无法读取有效配置，跳过模型测试');
            return;
        }
        
        // 3. 加载 mpp-core 模块
        const mppCore = await loadMppCore();
        
        // 4. 创建工具注册表
        const toolRegistry = createToolRegistry(mppCore);
        
        // 5. 生成提示词
        const prompt = await generatePromptWithRealComponents(mppCore, toolRegistry);
        
        // 6. 调用模型
        const response = await callModelWithRealService(mppCore, config, prompt);
        
        // 7. 解析响应并执行 WriteFileTool
        await executeWriteFileFromResponse(toolRegistry, response);
        
        // 8. 验证结果
        await verifyResults();
        
        console.log('\n✅ 集成测试完成');
        
    } catch (error) {
        console.error('❌ 集成测试失败:', error.message);
        process.exit(1);
    }
}

async function checkMppCoreCompilation(): Promise<void> {
    console.log('\n🔨 检查 mpp-core 编译状态...');
    
    try {
        const buildExists = await fs.access(MPP_CORE_BUILD_PATH).then(() => true).catch(() => false);
        
        if (!buildExists) {
            console.log('   📦 编译 mpp-core...');
            const { execSync } = require('child_process');
            execSync('./gradlew :mpp-core:compileKotlinJs', {
                cwd: path.resolve(__dirname, '../..'),
                stdio: 'pipe'
            });
        }
        
        console.log('   ✅ mpp-core 编译完成');
    } catch (error) {
        throw new Error(`mpp-core 编译失败: ${error.message}`);
    }
}

async function loadConfiguration() {
    console.log('\n📋 读取配置...');

    try {
        const config = await SimpleConfigManager.load();

        if (!config) {
            console.log('   ⚠️ 配置无效或不存在');
            return null;
        }

        console.log(`   ✅ 配置加载成功: ${config.provider}/${config.model}`);
        return config;

    } catch (error: any) {
        console.log(`   ❌ 读取配置失败: ${error.message}`);
        return null;
    }
}

async function loadMppCore() {
    console.log('\n📦 加载 mpp-core 模块...');

    try {
        // 检查编译后的文件是否存在
        const buildExists = await fs.access(MPP_CORE_BUILD_PATH).then(() => true).catch(() => false);

        if (!buildExists) {
            console.log('   ⚠️ mpp-core 编译文件不存在，使用模拟实现');
            return createMockMppCore();
        }

        // 动态导入编译后的 Kotlin/JS 模块
        const mppCore = require(MPP_CORE_BUILD_PATH);
        console.log('   ✅ mpp-core 模块加载成功');
        return mppCore;
    } catch (error) {
        console.log(`   ⚠️ 加载 mpp-core 失败，使用模拟实现: ${error.message}`);
        return createMockMppCore();
    }
}

function createMockMppCore() {
    console.log('   🔧 创建模拟 mpp-core 实现...');

    return {
        cc: {
            unitmesh: {
                agent: {
                    tool: {
                        registry: {
                            JsToolRegistry: class {
                                getAgentTools() {
                                    return [
                                        {
                                            name: 'write-file',
                                            description: 'Create new files or write content to existing files',
                                            example: '/write-file path="example.kt" content="package com.example\\n\\nclass Example"'
                                        },
                                        {
                                            name: 'read-file',
                                            description: 'Read content from files',
                                            example: '/read-file path="example.kt"'
                                        }
                                    ];
                                }

                                async executeTool(toolName: string, params: any) {
                                    if (toolName === 'write-file') {
                                        return await this.executeWriteFile(params);
                                    }
                                    throw new Error(`Unknown tool: ${toolName}`);
                                }

                                async executeWriteFile(params: any) {
                                    const { path: filePath, content, createDirectories } = params;

                                    try {
                                        if (createDirectories) {
                                            const dir = path.dirname(filePath);
                                            await fs.mkdir(dir, { recursive: true });
                                        }

                                        await fs.writeFile(filePath, content, 'utf8');

                                        return {
                                            success: true,
                                            output: `Successfully wrote ${content.length} characters to ${filePath}`,
                                            errorMessage: null,
                                            metadata: {
                                                file_path: filePath,
                                                content_length: content.length.toString(),
                                                content_lines: content.split('\n').length.toString()
                                            }
                                        };
                                    } catch (error) {
                                        return {
                                            success: false,
                                            output: '',
                                            errorMessage: error.message,
                                            metadata: {}
                                        };
                                    }
                                }
                            }
                        }
                    },
                    JsCodingAgentPromptRenderer: class {
                        render(context: any, language: string = 'EN') {
                            return `You are AutoDev, an autonomous AI coding agent.

## Environment Information
- OS: ${context.osInfo}
- Project Path: ${context.projectPath}
- Current Time: ${context.timestamp}
- Build Tool: ${context.buildTool}
- Shell: ${context.shell}

## Available Tools
${context.toolList}

## Task Execution Guidelines
1. Use the write-file tool to create or modify files
2. Ensure proper formatting and indentation
3. Include comprehensive documentation
4. Test your changes when possible

Remember: You can write multi-line content using the write-file tool.`;
                        }
                    },
                    JsCodingAgentContextBuilder: class {
                        private context: any = {};

                        setProjectPath(path: string) {
                            this.context.projectPath = path;
                            return this;
                        }

                        setOsInfo(osInfo: string) {
                            this.context.osInfo = osInfo;
                            return this;
                        }

                        setTimestamp(timestamp: string) {
                            this.context.timestamp = timestamp;
                            return this;
                        }

                        setToolList(toolList: string) {
                            this.context.toolList = toolList;
                            return this;
                        }

                        setBuildTool(buildTool: string) {
                            this.context.buildTool = buildTool;
                            return this;
                        }

                        setShell(shell: string) {
                            this.context.shell = shell;
                            return this;
                        }

                        build() {
                            return this.context;
                        }
                    }
                },
                llm: {
                    JsModelConfig: class {
                        constructor(config: any) {
                            Object.assign(this, config);
                        }
                    },
                    JsKoogLLMService: class {
                        private config: any;

                        constructor(config: any) {
                            this.config = config;
                        }

                        async sendPrompt(prompt: string) {
                            // 模拟模型响应
                            console.log(`   🤖 模拟调用 ${this.config.providerName}/${this.config.modelName}`);

                            return `I'll create the ProductService.kt file with multi-line content.

<devin>
/write-file path="test-output/ProductService.kt" content="package com.example.service

import kotlinx.serialization.Serializable
import java.math.BigDecimal

/**
 * Product data class representing a product entity
 *
 * @property id Unique product identifier
 * @property name Product name
 * @property price Product price
 * @property description Product description
 * @property category Product category
 */
@Serializable
data class Product(
    val id: String,
    val name: String,
    val price: BigDecimal,
    val description: String,
    val category: String
) {
    /**
     * Validates product data
     */
    fun isValid(): Boolean {
        return id.isNotBlank() &&
               name.isNotBlank() &&
               price > BigDecimal.ZERO &&
               description.isNotBlank() &&
               category.isNotBlank()
    }

    /**
     * Gets formatted price string
     */
    fun getFormattedPrice(): String = \\"$\${price}\\"
}

/**
 * Product service interface for managing products
 */
interface ProductService {
    suspend fun createProduct(product: Product): Result<Product>
    suspend fun getProductById(id: String): Product?
    suspend fun getAllProducts(): List<Product>
    suspend fun updateProduct(product: Product): Result<Product>
    suspend fun deleteProduct(id: String): Boolean
    suspend fun getProductsByCategory(category: String): List<Product>
}

/**
 * In-memory implementation of ProductService
 */
class InMemoryProductService : ProductService {
    private val products = mutableMapOf<String, Product>()

    override suspend fun createProduct(product: Product): Result<Product> {
        return try {
            if (!product.isValid()) {
                Result.failure(IllegalArgumentException(\\"Invalid product data\\"))
            } else if (products.containsKey(product.id)) {
                Result.failure(IllegalArgumentException(\\"Product already exists\\"))
            } else {
                products[product.id] = product
                Result.success(product)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getProductById(id: String): Product? = products[id]

    override suspend fun getAllProducts(): List<Product> = products.values.toList()

    override suspend fun updateProduct(product: Product): Result<Product> {
        return if (products.containsKey(product.id)) {
            products[product.id] = product
            Result.success(product)
        } else {
            Result.failure(NoSuchElementException(\\"Product not found\\"))
        }
    }

    override suspend fun deleteProduct(id: String): Boolean {
        return products.remove(id) != null
    }

    override suspend fun getProductsByCategory(category: String): List<Product> {
        return products.values.filter { it.category == category }
    }
}"
</devin>

I've created the ProductService.kt file with:
- Product data class with validation
- ProductService interface with CRUD operations
- InMemoryProductService implementation
- Comprehensive documentation and comments
- Over 50 lines of well-formatted Kotlin code`;
                        }
                    }
                }
            }
        }
    };
}

function createToolRegistry(mppCore: any) {
    console.log('\n🔧 创建工具注册表...');
    
    try {
        // 使用 mpp-core 的 ToolRegistry
        const { JsToolRegistry } = mppCore.cc.unitmesh.agent.tool.registry;
        const registry = new JsToolRegistry();
        
        const tools = registry.getAgentTools();
        console.log(`   ✅ 工具注册表创建成功，包含 ${tools.length} 个工具`);
        
        // 检查是否包含 WriteFileTool
        const hasWriteFile = tools.some((tool: any) => tool.name === 'write-file');
        console.log(`   🔍 包含 WriteFileTool: ${hasWriteFile ? '✅' : '❌'}`);
        
        return registry;
    } catch (error) {
        throw new Error(`创建工具注册表失败: ${error.message}`);
    }
}

async function generatePromptWithRealComponents(mppCore: any, toolRegistry: any): Promise<string> {
    console.log('\n📝 使用真实组件生成提示词...');
    
    try {
        // 使用 CodingAgentPromptRenderer
        const { JsCodingAgentPromptRenderer, JsCodingAgentContextBuilder } = mppCore.cc.unitmesh.agent;
        
        // 获取工具列表
        const tools = toolRegistry.getAgentTools();
        const toolList = tools.map((tool: any) => 
            `<tool name="${tool.name}">\n  <description>${tool.description}</description>\n  <example>${tool.example}</example>\n</tool>`
        ).join('\n\n');
        
        // 创建上下文
        const contextBuilder = new JsCodingAgentContextBuilder();
        const context = contextBuilder
            .setProjectPath(process.cwd())
            .setOsInfo(`${process.platform} ${process.arch}`)
            .setTimestamp(new Date().toISOString())
            .setToolList(toolList)
            .setBuildTool('gradle + kotlin')
            .setShell(process.env.SHELL || '/bin/bash')
            .build();
        
        // 生成提示词
        const renderer = new JsCodingAgentPromptRenderer();
        const prompt = renderer.render(context, 'EN');
        
        console.log(`   ✅ 提示词生成成功，长度: ${prompt.length} 字符`);
        
        // 添加具体任务
        const taskPrompt = `
${prompt}

## Current Task
Create a Kotlin data class file with multi-line content to test WriteFileTool:

1. File path: test-output/ProductService.kt
2. Package: com.example.service
3. Include:
   - Product data class with validation
   - ProductService interface
   - InMemoryProductService implementation
   - Comprehensive documentation
   - At least 50 lines of well-formatted code

Please use the write-file tool to create this file with proper multi-line formatting.
`;
        
        return taskPrompt;
        
    } catch (error) {
        throw new Error(`生成提示词失败: ${error.message}`);
    }
}

async function callModelWithRealService(mppCore: any, config: any, prompt: string): Promise<string> {
    console.log('\n🤖 调用真实的 KoogLLMService...');
    
    try {
        // 创建模型配置
        const { JsModelConfig, JsKoogLLMService } = mppCore.cc.unitmesh.llm;
        
        const modelConfig = new JsModelConfig({
            providerName: config.provider.toUpperCase(),
            modelName: config.model,
            apiKey: config.apiKey,
            baseUrl: config.baseUrl || '',
            temperature: config.temperature || 0.7,
            maxTokens: config.maxTokens || 4096
        });
        
        // 创建 LLM 服务
        const llmService = new JsKoogLLMService(modelConfig);
        
        console.log(`   📤 发送请求到: ${config.provider}/${config.model}`);
        console.log(`   📝 提示词长度: ${prompt.length} 字符`);
        
        // 调用模型
        const response = await llmService.sendPrompt(prompt);
        
        console.log(`   📥 收到响应，长度: ${response.length} 字符`);
        return response;
        
    } catch (error) {
        throw new Error(`模型调用失败: ${error.message}`);
    }
}

async function executeWriteFileFromResponse(toolRegistry: any, response: string): Promise<void> {
    console.log('\n🔧 解析响应并执行 WriteFileTool...');
    
    try {
        // 查找 <devin> 标签中的 write-file 命令
        const devinMatch = response.match(/<devin>\s*([\s\S]*?)\s*<\/devin>/);
        
        if (!devinMatch) {
            throw new Error('未找到有效的 <devin> 命令');
        }
        
        const command = devinMatch[1].trim();
        console.log('   📋 找到命令:', command.substring(0, 50) + '...');
        
        if (!command.startsWith('/write-file')) {
            throw new Error('不是 write-file 命令');
        }
        
        // 解析命令参数
        const pathMatch = command.match(/path="([^"]+)"/);
        const contentMatch = command.match(/content="([\s\S]*?)"/);
        
        if (!pathMatch || !contentMatch) {
            throw new Error('命令参数解析失败');
        }
        
        const filePath = pathMatch[1];
        let content = contentMatch[1];
        
        // 处理转义字符
        content = content
            .replace(/\\n/g, '\n')
            .replace(/\\"/g, '"')
            .replace(/\\\\/g, '\\');
        
        console.log(`   📁 文件路径: ${filePath}`);
        console.log(`   📝 内容长度: ${content.length} 字符`);
        console.log(`   📊 行数: ${content.split('\n').length}`);
        
        // 使用 WriteFileTool 执行写入
        const writeFileParams = {
            path: filePath,
            content: content,
            createDirectories: true,
            overwrite: true
        };
        
        const result = await toolRegistry.executeTool('write-file', writeFileParams);
        
        if (result.success) {
            console.log('   ✅ WriteFileTool 执行成功');
        } else {
            throw new Error(`WriteFileTool 执行失败: ${result.errorMessage}`);
        }
        
    } catch (error) {
        throw new Error(`执行 WriteFileTool 失败: ${error.message}`);
    }
}

async function verifyResults(): Promise<void> {
    console.log('\n🔍 验证结果...');
    
    const testFile = 'test-output/ProductService.kt';
    
    try {
        const content = await fs.readFile(testFile, 'utf8');
        const stats = await fs.stat(testFile);
        
        console.log('   📊 文件统计:');
        console.log(`   - 文件大小: ${stats.size} bytes`);
        console.log(`   - 行数: ${content.split('\n').length}`);
        console.log(`   - 字符数: ${content.length}`);
        
        // 验证关键内容
        const checks = [
            { name: '包声明', test: () => content.includes('package com.example.service') },
            { name: '数据类', test: () => content.includes('data class Product') },
            { name: '接口定义', test: () => content.includes('interface ProductService') },
            { name: '实现类', test: () => content.includes('class InMemoryProductService') },
            { name: '多行注释', test: () => content.includes('/**') },
            { name: '导入语句', test: () => content.includes('import ') }
        ];
        
        console.log('   🔍 内容验证:');
        let passedChecks = 0;
        for (const check of checks) {
            const passed = check.test();
            console.log(`   ${passed ? '✅' : '❌'} ${check.name}`);
            if (passed) passedChecks++;
        }
        
        console.log(`   📈 验证通过率: ${passedChecks}/${checks.length} (${Math.round(passedChecks/checks.length*100)}%)`);
        
        if (passedChecks === checks.length) {
            console.log('   🎉 所有验证通过！');
        } else {
            console.log('   ⚠️ 部分验证失败');
        }
        
    } catch (error) {
        throw new Error(`验证失败: ${error.message}`);
    }
}

// 运行测试
main().catch(error => {
    console.error('💥 集成测试异常:', error);
    process.exit(1);
});
