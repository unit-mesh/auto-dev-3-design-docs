#!/bin/bash

# 专门测试 Spring AI 添加场景的并行工具执行
# 这个场景应该会触发多个工具的并行执行

set -e

echo "🧪 Testing Spring AI Integration with Parallel Tool Execution"
echo "=============================================================="
echo ""

# 项目路径
PROJECT_PATH="${1:-/Users/phodal/IdeaProjects/untitled}"
CLI_PATH="/Volumes/source/ai/autocrud/mpp-ui/dist/jsMain/typescript/index.js"

# 检查 CLI 是否存在
if [ ! -f "$CLI_PATH" ]; then
    echo "❌ CLI not found. Building..."
    cd /Volumes/source/ai/autocrud/mpp-ui
    npm run build
    cd -
fi

echo "📂 Project: $PROJECT_PATH"
echo "🚀 Starting test..."
echo ""

# 运行测试并捕获输出
node "$CLI_PATH" code \
  --task "add Spring ai to project and also a service example, I use deepseek, here it's the documentation https://docs.spring.io/spring-ai/reference/api/chat/deepseek-chat.html" \
  -p "$PROJECT_PATH" 2>&1 | tee spring-ai-test.log

echo ""
echo "=============================================================="
echo "📊 Analysis Results"
echo "=============================================================="
echo ""

# 检查并行执行指示器
echo "1. Parallel Execution Indicators:"
echo "-----------------------------------"
grep -i "🔄 Executing.*tools in parallel" spring-ai-test.log || echo "⚠️  No parallel execution message found"
echo ""

# 统计工具调用
echo "2. Tool Call Statistics:"
echo "------------------------"
echo "Total tool calls: $(grep -c "🔧 /" spring-ai-test.log || echo "0")"
echo ""
echo "Tool breakdown:"
grep "🔧 /" spring-ai-test.log | sed 's/🔧 \//  - /' | head -20
echo ""

# 检查并行执行的工具组
echo "3. Parallel Tool Groups:"
echo "------------------------"
# 查找多个连续的工具调用（可能表示并行执行）
awk '
  /🔄 Executing.*tools in parallel/ { 
    print "Found parallel execution group:"
    getline; while (/🔧 \//) { print "  " $0; getline } 
  }
' spring-ai-test.log

echo ""

# 检查迭代次数和效率
echo "4. Execution Efficiency:"
echo "------------------------"
ITERATIONS=$(grep -c "\[.*\] Analyzing and executing" spring-ai-test.log || echo "0")
echo "Total iterations: $ITERATIONS"
echo ""

# 查找常见的读写模式
echo "5. Common Tool Patterns:"
echo "------------------------"
echo "Read operations: $(grep -c "read-file" spring-ai-test.log || echo "0")"
echo "Write operations: $(grep -c "write-file" spring-ai-test.log || echo "0")"
echo "Edit operations: $(grep -c "edit-file" spring-ai-test.log || echo "0")"
echo "Glob operations: $(grep -c "glob" spring-ai-test.log || echo "0")"
echo "Grep operations: $(grep -c "grep" spring-ai-test.log || echo "0")"
echo ""

# 检查是否有错误
echo "6. Error Check:"
echo "---------------"
if grep -q "❌" spring-ai-test.log; then
    echo "⚠️  Errors detected:"
    grep "❌" spring-ai-test.log | head -5
else
    echo "✅ No errors detected"
fi
echo ""

# 检查最终结果
echo "7. Task Completion:"
echo "-------------------"
if grep -q "✓ Task marked as complete\|✅" spring-ai-test.log; then
    echo "✅ Task completed successfully"
else
    echo "⚠️  Task may not have completed"
fi
echo ""

echo "=============================================================="
echo "📝 Full log saved to: spring-ai-test.log"
echo "=============================================================="



