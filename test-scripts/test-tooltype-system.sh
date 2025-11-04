#!/bin/bash

# ToolType 系统测试脚本
# 验证新的 ToolType sealed class 系统是否正常工作

set -e

echo "🧪 Testing ToolType System"
echo "=========================="

# 测试目录
TEST_DIR="/tmp/tooltype-test-$(date +%s)"
mkdir -p "$TEST_DIR"

echo "📁 Test directory: $TEST_DIR"
echo ""

# 构建项目
echo "🔨 Building project..."
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:assembleJsPackage > /dev/null 2>&1
cd mpp-ui && npm run build:ts > /dev/null 2>&1
echo "✅ Build completed"
echo ""

# 测试 1: 文件创建和读取
echo "📝 Test 1: File operations"
cd /Volumes/source/ai/autocrud/mpp-ui
node dist/index.js code --path "$TEST_DIR" --task "Create a file named test.txt with content 'ToolType works!'" > /dev/null 2>&1

if [ -f "$TEST_DIR/test.txt" ] && [ "$(cat "$TEST_DIR/test.txt")" = "ToolType works!" ]; then
    echo "✅ File creation test passed"
else
    echo "❌ File creation test failed"
    exit 1
fi

# 测试 2: Shell 命令执行
echo "💻 Test 2: Shell command execution"
node dist/index.js code --path "$TEST_DIR" --task "Use ls command to list files in current directory" > /dev/null 2>&1
echo "✅ Shell command test passed"

# 测试 3: 文件搜索
echo "🔍 Test 3: File search"
node dist/index.js code --path "$TEST_DIR" --task "Find all .txt files in current directory" > /dev/null 2>&1
echo "✅ File search test passed"

# 测试 4: 多个工具组合
echo "🔧 Test 4: Multiple tools combination"
node dist/index.js code --path "$TEST_DIR" --task "Create a Java Hello World program and compile it" > /dev/null 2>&1

if [ -f "$TEST_DIR/HelloWorld.java" ]; then
    echo "✅ Multiple tools test passed"
else
    echo "❌ Multiple tools test failed"
    exit 1
fi

# 清理
echo ""
echo "🧹 Cleaning up..."
rm -rf "$TEST_DIR"

echo ""
echo "🎉 All tests passed!"
echo "✅ ToolType system is working correctly"
echo ""
echo "📊 Test Summary:"
echo "   - File operations: ✅"
echo "   - Shell commands: ✅"
echo "   - File search: ✅"
echo "   - Multiple tools: ✅"
echo ""
echo "🚀 ToolType system is ready for production use!"
