#!/bin/bash

# 压缩功能完整测试脚本
# 测试 JVM 和 JS 平台的压缩功能

set -e

echo "🧪 压缩功能完整测试"
echo "=" | head -c 50 && echo

# 1. 编译和测试 JVM 平台
echo "📋 1. JVM 平台测试"
echo "   编译 JVM 测试..."
./gradlew :mpp-core:jvmTestClasses --quiet

echo "   运行 JVM 压缩测试..."
./gradlew :mpp-core:jvmTest --tests "*Compression*" --quiet
echo "   ✅ JVM 测试通过"

# 2. 编译和测试 JS 平台
echo ""
echo "📋 2. JS 平台测试"
echo "   编译 JS 测试..."
./gradlew :mpp-core:jsTestClasses --quiet

echo "   运行 JS 测试..."
./gradlew :mpp-core:jsTest --quiet
echo "   ✅ JS 测试通过"

# 3. 构建 JS 包
echo ""
echo "📋 3. JS 包构建和功能测试"
echo "   构建 JS 包..."
./gradlew :mpp-core:assembleJsPackage --quiet

echo "   运行 JS 功能测试..."
node docs/test-scripts/test-compression-functionality.js
echo "   ✅ JS 功能测试通过"

# 4. 测试总结
echo ""
echo "📊 4. 测试总结"
echo "   ✅ JVM 平台：编译通过，单元测试通过"
echo "   ✅ JS 平台：编译通过，单元测试通过，功能测试通过"
echo "   ✅ 压缩配置：CompressionConfig, TokenInfo, ChatCompressionInfo"
echo "   ✅ LLM 服务集成：KoogLLMService 压缩功能"
echo "   ✅ JS 导出：JsCompressionConfig, JsTokenInfo, JsChatCompressionInfo"

echo ""
echo "🎉 所有压缩功能测试通过！"
echo ""
echo "📝 测试覆盖范围："
echo "   - CompressionConfig 参数验证"
echo "   - TokenInfo 使用率计算和压缩需求检查"
echo "   - ChatCompressionInfo 压缩比例计算"
echo "   - KoogLLMService 压缩集成"
echo "   - ConversationManager 压缩功能"
echo "   - JavaScript 平台兼容性"
echo ""
echo "✨ 压缩功能已准备就绪，可以在实际项目中使用！"
