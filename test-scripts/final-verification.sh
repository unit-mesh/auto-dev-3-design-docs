#!/bin/bash

# 最终验证脚本：确认工具 Schema 修复是否成功
# 
# 使用方法：
# ./docs/test-scripts/final-verification.sh

set -e

echo "🎯 CodingAgent 工具 Schema 修复 - 最终验证"
echo "=================================================="

# 检查修复的关键文件
echo "📁 检查修复文件..."

# 1. 检查 Agent.kt 的注释改进
if grep -q "子类应该重写此方法以返回具体的参数类型名称" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/core/Agent.kt; then
    echo "✅ Agent.kt 注释已改进"
else
    echo "❌ Agent.kt 注释未改进"
    exit 1
fi

# 2. 检查 ErrorRecoveryAgent 的 getParameterClass 修复
if grep -q "override fun getParameterClass(): String = ErrorContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/ErrorRecoveryAgent.kt; then
    echo "✅ ErrorRecoveryAgent.getParameterClass() 已修复"
else
    echo "❌ ErrorRecoveryAgent.getParameterClass() 未修复"
    exit 1
fi

# 3. 检查 LogSummaryAgent 的 getParameterClass 修复
if grep -q "override fun getParameterClass(): String = LogSummaryContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/LogSummaryAgent.kt; then
    echo "✅ LogSummaryAgent.getParameterClass() 已修复"
else
    echo "❌ LogSummaryAgent.getParameterClass() 未修复"
    exit 1
fi

# 4. 检查 CodebaseInvestigatorAgent 的 getParameterClass 修复
if grep -q "override fun getParameterClass(): String = InvestigationContext::class.simpleName" mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/subagent/CodebaseInvestigatorAgent.kt; then
    echo "✅ CodebaseInvestigatorAgent.getParameterClass() 已修复"
else
    echo "❌ CodebaseInvestigatorAgent.getParameterClass() 未修复"
    exit 1
fi

# 5. 检查 CodingAgentContext 的改进
if grep -q 'paramClass == "AgentInput"' mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt; then
    echo "✅ CodingAgentContext 已改进 AgentInput 处理"
else
    echo "❌ CodingAgentContext 未改进 AgentInput 处理"
    exit 1
fi

# 6. 检查 SubAgent 示例的添加
if grep -q 'error-recovery.*command.*errorMessage' mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/CodingAgentContext.kt; then
    echo "✅ SubAgent 示例已添加"
else
    echo "❌ SubAgent 示例未添加"
    exit 1
fi

echo ""
echo "🔨 编译验证..."

# 验证编译是否成功
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
echo "📊 修复效果分析..."

# 分析修复前后的差异
echo "🔍 修复前的问题:"
echo "  - SubAgent 的 getParameterClass() 返回通用的 'AgentInput'"
echo "  - 工具提示词缺少具体的参数类型信息"
echo "  - AI 模型无法正确理解工具的参数结构"
echo "  - 在 Compose JVM/Android 版本中工具调用失败"

echo ""
echo "✅ 修复后的改进:"
echo "  - ErrorRecoveryAgent 返回 'ErrorContext'"
echo "  - LogSummaryAgent 返回 'LogSummaryContext'"
echo "  - CodebaseInvestigatorAgent 返回 'InvestigationContext'"
echo "  - 工具提示词包含具体的参数类型和使用示例"
echo "  - AI 模型能够更好地理解和使用工具"

echo ""
echo "🎯 预期的工具提示词格式:"
cat << 'EOF'
<tool name="error-recovery">
  <description>Analyzes command failures and provides recovery plans</description>
  <parameters>
    <type>ErrorContext</type>
    <usage>/error-recovery [parameters]</usage>
  </parameters>
  <example>
    /error-recovery command="gradle build" errorMessage="Compilation failed"
  </example>
</tool>
EOF

echo ""
echo "📋 下一步建议:"
echo "1. 在实际的 Compose 应用中测试 CodingAgent"
echo "2. 验证工具调用是否正常工作"
echo "3. 检查生成的提示词是否包含正确的 Schema 信息"
echo "4. 监控 AI 模型对工具的理解和使用情况"

echo ""
echo "🎉 工具 Schema 修复验证完成！"
echo "所有检查都通过，修复应该已经解决了原始问题。"
