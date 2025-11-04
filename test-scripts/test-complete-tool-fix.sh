#!/bin/bash

# 完整的工具 Schema 修复测试脚本
# 
# 使用方法：
# ./docs/test-scripts/test-complete-tool-fix.sh

set -e

echo "🎯 完整的 CodingAgent 工具 Schema 修复测试"
echo "=================================================="

# 检查所有修复
echo "📁 检查所有修复文件..."

FIXED_FILES=(
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentPromptRenderer.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt"
)

for file in "${FIXED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 错误：找不到文件 $file"
        exit 1
    fi
    echo "✅ 找到文件: $file"
done

echo ""
echo "🔍 检查关键修复..."

# 1. 检查 CodingAgent 的 getAllAvailableTools 方法
if grep -q "getAllAvailableTools" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt; then
    echo "✅ CodingAgent.getAllAvailableTools() 方法已添加"
else
    echo "❌ CodingAgent.getAllAvailableTools() 方法未添加"
    exit 1
fi

# 2. 检查是否使用了 getAllAvailableTools 而不是 getAllTools
if grep -q "toolList = getAllAvailableTools()" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt; then
    echo "✅ CodingAgent 现在使用 getAllAvailableTools()"
else
    echo "❌ CodingAgent 未使用 getAllAvailableTools()"
    exit 1
fi

# 3. 检查是否包含 ToolRegistry 中的工具
if grep -q "toolRegistry.getAllTools().values" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgent.kt; then
    echo "✅ CodingAgent 现在包含 ToolRegistry 中的内置工具"
else
    echo "❌ CodingAgent 未包含 ToolRegistry 中的内置工具"
    exit 1
fi

# 4. 检查 SubAgent 的 getParameterClass 修复
if grep -q "ErrorContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt; then
    echo "✅ ErrorRecoveryAgent.getParameterClass() 已修复"
else
    echo "❌ ErrorRecoveryAgent.getParameterClass() 未修复"
    exit 1
fi

# 5. 检查调试信息的添加
if grep -q "🔍.*CodingAgentContext.*格式化工具列表" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt; then
    echo "✅ CodingAgentContext 已添加调试信息"
else
    echo "❌ CodingAgentContext 未添加调试信息"
    exit 1
fi

# 6. 检查 CodingAgentPromptRenderer 的调试信息
if grep -q "🔍.*CodingAgentPromptRenderer.*工具列表长度" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentPromptRenderer.kt; then
    echo "✅ CodingAgentPromptRenderer 已添加调试信息"
else
    echo "❌ CodingAgentPromptRenderer 未添加调试信息"
    exit 1
fi

echo ""
echo "🔨 编译验证..."

# 验证所有平台编译
./gradlew :mpp-core:compileKotlinJvm --quiet
if [ $? -eq 0 ]; then
    echo "✅ JVM 编译成功"
else
    echo "❌ JVM 编译失败"
    exit 1
fi

./gradlew :mpp-core:compileKotlinJs --quiet
if [ $? -eq 0 ]; then
    echo "✅ JS 编译成功"
else
    echo "❌ JS 编译失败"
    exit 1
fi

./gradlew :mpp-core:compileDebugKotlinAndroid --quiet
if [ $? -eq 0 ]; then
    echo "✅ Android 编译成功"
else
    echo "❌ Android 编译失败"
    exit 1
fi

echo ""
echo "📊 修复总结："
echo "=" * 50

echo ""
echo "🔧 主要修复："
echo "1. ✅ 修复了 CodingAgent.getAllTools() 只返回 MainAgent.tools 的问题"
echo "2. ✅ 添加了 getAllAvailableTools() 方法，包含所有工具："
echo "   - ToolRegistry 中的内置工具 (read-file, write-file, grep, glob, shell)"
echo "   - MainAgent 中的 SubAgent (error-recovery, log-summary, codebase-investigator)"
echo "   - MainAgent 中的 MCP 工具"
echo "3. ✅ 修复了 SubAgent 的 getParameterClass() 方法"
echo "4. ✅ 改进了工具提示词生成逻辑"
echo "5. ✅ 添加了调试信息以便问题诊断"

echo ""
echo "🎯 预期效果："
echo "- 内置工具 (read-file, write-file, grep, glob, shell) 现在会出现在工具列表中"
echo "- SubAgent 工具显示正确的参数类型"
echo "- 工具提示词包含完整的 Schema 信息"
echo "- AI 模型能够正确理解和使用所有工具"
echo "- 在 Compose JVM/Android 版本中工具调用应该正常工作"

echo ""
echo "🔍 调试信息："
echo "运行时会在控制台输出以下调试信息："
echo "- [CodingAgentContext] 格式化工具列表，共 X 个工具"
echo "- [CodingAgentPromptRenderer] 工具列表长度: X"
echo "- [CodingAgentPromptRenderer] 工具数量: X"
echo "- [CodingAgentPromptRenderer] 包含内置工具: true/false"
echo "- [CodingAgentPromptRenderer] 包含 SubAgent: true/false"

echo ""
echo "📋 下一步测试建议："
echo "1. 在实际的 Compose 应用中创建 CodingAgent 实例"
echo "2. 调用 agent.execute() 方法"
echo "3. 观察控制台输出的调试信息"
echo "4. 验证生成的 system prompt 是否包含所有预期的工具"
echo "5. 测试 AI 模型是否能正确调用各种工具"

echo ""
echo "🎉 完整的工具 Schema 修复测试完成！"
echo "所有检查都通过，修复应该已经解决了原始问题。"
