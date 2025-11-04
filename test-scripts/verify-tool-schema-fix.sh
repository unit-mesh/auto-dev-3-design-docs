#!/bin/bash

# 验证工具 Schema 修复的脚本
# 
# 使用方法：
# ./docs/test-scripts/verify-tool-schema-fix.sh

set -e

echo "🔍 验证 CodingAgent 工具 Schema 修复"
echo "=================================================="

# 检查修复的文件
echo "📁 检查修复的文件..."

FIXED_FILES=(
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/core/Agent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt"
    "mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt"
)

for file in "${FIXED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 错误：找不到文件 $file"
        exit 1
    fi
    echo "✅ 找到文件: $file"
done

# 检查 getParameterClass 方法的修复
echo ""
echo "🔍 检查 getParameterClass 方法修复..."

# 检查 ErrorRecoveryAgent
if grep -q "override fun getParameterClass(): String = ErrorContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt; then
    echo "✅ ErrorRecoveryAgent.getParameterClass() 已修复"
else
    echo "❌ ErrorRecoveryAgent.getParameterClass() 未修复"
    exit 1
fi

# 检查 LogSummaryAgent
if grep -q "override fun getParameterClass(): String = LogSummaryContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt; then
    echo "✅ LogSummaryAgent.getParameterClass() 已修复"
else
    echo "❌ LogSummaryAgent.getParameterClass() 未修复"
    exit 1
fi

# 检查 CodebaseInvestigatorAgent
if grep -q "override fun getParameterClass(): String = InvestigationContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt; then
    echo "✅ CodebaseInvestigatorAgent.getParameterClass() 已修复"
else
    echo "❌ CodebaseInvestigatorAgent.getParameterClass() 未修复"
    exit 1
fi

# 检查 CodingAgentContext 的改进
echo ""
echo "🔍 检查 CodingAgentContext 改进..."

if grep -q "paramClass == \"AgentInput\"" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt; then
    echo "✅ CodingAgentContext 已改进 AgentInput 处理"
else
    echo "❌ CodingAgentContext 未改进 AgentInput 处理"
    exit 1
fi

if grep -q "error-recovery.*errorMessage" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt; then
    echo "✅ CodingAgentContext 已添加 SubAgent 示例"
else
    echo "❌ CodingAgentContext 未添加 SubAgent 示例"
    exit 1
fi

# 构建测试
echo ""
echo "🔨 构建测试..."
./gradlew :mpp-core:compileKotlinJvm

if [ $? -ne 0 ]; then
    echo "❌ 错误：JVM 编译失败"
    exit 1
fi

echo "✅ JVM 编译成功"

# 尝试构建其他平台
echo ""
echo "🔨 测试其他平台编译..."

./gradlew :mpp-core:compileKotlinJs
if [ $? -eq 0 ]; then
    echo "✅ JS 编译成功"
else
    echo "⚠️  JS 编译失败，可能存在平台兼容性问题"
fi

./gradlew :mpp-core:compileDebugKotlinAndroid
if [ $? -eq 0 ]; then
    echo "✅ Android 编译成功"
else
    echo "⚠️  Android 编译失败，可能存在平台兼容性问题"
fi

echo ""
echo "📋 修复总结："
echo "1. ✅ 修复了 Agent 基类的 getParameterClass() 方法注释"
echo "2. ✅ 为所有 SubAgent 添加了具体的 getParameterClass() 实现"
echo "3. ✅ 改进了 CodingAgentContext.formatToolListForAI() 方法"
echo "4. ✅ 添加了对 AgentInput 类型的特殊处理"
echo "5. ✅ 为 SubAgent 添加了使用示例"
echo "6. ✅ 改进了空描述的处理"

echo ""
echo "🎯 预期效果："
echo "- SubAgent 工具现在会显示正确的参数类型（ErrorContext, LogSummaryContext, InvestigationContext）"
echo "- 工具提示词将包含更完整的 Schema 信息"
echo "- AI 模型能够更好地理解和使用工具"
echo "- 在 Compose JVM/Android 版本中工具调用应该正常工作"

echo ""
echo "✅ 工具 Schema 修复验证完成"
