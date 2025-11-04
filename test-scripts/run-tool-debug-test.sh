#!/bin/bash

# 调试脚本：运行 CodingAgent 工具 Schema 问题测试
# 
# 使用方法：
# ./docs/test-scripts/run-tool-debug-test.sh

set -e

echo "🔍 开始调试 CodingAgent 工具 Schema 问题"
echo "=================================================="

# 检查项目结构
echo "📁 检查项目结构..."
if [ ! -f "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt" ]; then
    echo "❌ 错误：找不到 CodingAgent.kt 文件"
    exit 1
fi

if [ ! -f "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentTemplate.kt" ]; then
    echo "❌ 错误：找不到 CodingAgentTemplate.kt 文件"
    exit 1
fi

echo "✅ 项目结构检查通过"

# 构建 mpp-core 模块
echo ""
echo "🔨 构建 mpp-core 模块..."
./gradlew :mpp-core:clean :mpp-core:compileKotlinJvm

if [ $? -ne 0 ]; then
    echo "❌ 错误：mpp-core JVM 编译失败"
    exit 1
fi

echo "✅ JVM 编译成功"

# 尝试构建 JS 版本
echo ""
echo "🔨 构建 mpp-core JS 版本..."
./gradlew :mpp-core:compileKotlinJs

if [ $? -ne 0 ]; then
    echo "⚠️  警告：JS 编译失败，可能存在平台兼容性问题"
else
    echo "✅ JS 编译成功"
fi

# 创建临时测试文件
echo ""
echo "📝 创建工具调试测试..."

cat > /tmp/tool_debug_test.kt << 'EOF'
import cc.unitmesh.agent.CodingAgent
import cc.unitmesh.agent.AgentTask
import cc.unitmesh.agent.CodingAgentContext
import cc.unitmesh.llm.KoogLLMService
import kotlinx.coroutines.runBlocking

fun main() {
    println("🔍 开始工具 Schema 调试测试")
    
    // 创建模拟的 LLM 服务
    val mockLLMService = object : KoogLLMService {
        override suspend fun chat(messages: List<Any>, model: String?): String {
            return "Mock response"
        }
        override suspend fun completion(prompt: String, model: String?): String {
            return "Mock completion"
        }
    }
    
    // 创建 CodingAgent 实例
    val agent = CodingAgent(
        projectPath = "/tmp/test-project",
        llmService = mockLLMService
    )
    
    // 测试工具列表获取
    val tools = agent.getAllTools()
    println("📦 发现 ${tools.size} 个工具:")
    
    tools.forEach { tool ->
        println("  - 名称: ${tool.name}")
        println("    描述: ${tool.description}")
        println("    参数类: ${tool.getParameterClass()}")
        println("    类型: ${tool::class.simpleName}")
        println()
    }
    
    // 测试上下文构建
    val task = AgentTask("测试任务", "/tmp/test-project")
    
    runBlocking {
        try {
            // 这里会调用 buildContext，进而调用 getAllTools()
            val context = CodingAgentContext.fromTask(task, tools)
            
            println("📋 生成的工具列表提示词:")
            println("=" * 50)
            println(context.toolList)
            println("=" * 50)
            
            // 检查提示词质量
            val toolListLines = context.toolList.split("\n")
            val emptyDescriptions = toolListLines.count { it.contains("<description></description>") }
            val unitParameters = toolListLines.count { it.contains("<type>Unit</type>") }
            val missingExamples = toolListLines.count { 
                it.contains("<tool name=") && !context.toolList.contains("<example>")
            }
            
            println("🔍 提示词质量分析:")
            println("  - 空描述数量: $emptyDescriptions")
            println("  - Unit 参数类型数量: $unitParameters") 
            println("  - 缺少示例的工具数量: $missingExamples")
            
            if (emptyDescriptions > 0 || unitParameters > 0) {
                println("❌ 发现工具 Schema 问题！")
                System.exit(1)
            } else {
                println("✅ 工具 Schema 检查通过")
            }
            
        } catch (e: Exception) {
            println("❌ 测试失败: ${e.message}")
            e.printStackTrace()
            System.exit(1)
        }
    }
}
EOF

echo "✅ 测试文件创建完成"

# 运行测试（如果可能的话）
echo ""
echo "🚀 运行工具调试测试..."
echo "注意：由于依赖关系，可能需要手动在 IDE 中运行测试"

echo ""
echo "📋 手动测试步骤："
echo "1. 在 IDE 中打开项目"
echo "2. 创建一个测试类，复制上面的测试代码"
echo "3. 运行测试并观察输出"
echo "4. 检查工具列表是否包含完整的 Schema 信息"

echo ""
echo "🔍 重点检查项："
echo "- getAllTools() 返回的工具数量是否正确"
echo "- 每个工具的 description 是否为空"
echo "- getParameterClass() 是否返回 'Unit'"
echo "- formatToolListForAI() 生成的 XML 格式是否正确"
echo "- MCP 工具是否正确注册和格式化"

echo ""
echo "✅ 调试脚本执行完成"
