#!/bin/bash

# 简单的并行测试 - 多文件读取
# 这个测试应该明确触发并行工具执行

echo "🧪 Simple Parallel Execution Test"
echo "=================================="
echo ""

CLI_PATH="/Volumes/source/ai/autocrud/mpp-ui/dist/jsMain/typescript/index.js"
PROJECT_PATH="${1:-.}"

echo "Testing multiple file reads (should execute in parallel)"
echo ""

# 测试 1: 明确要求读取多个文件
echo "Test: Read 3 files simultaneously"
echo "---"
node "$CLI_PATH" code \
  --task "Please read these three files at the same time and tell me their sizes: 1) README.md, 2) package.json, 3) build.gradle.kts" \
  -p "$PROJECT_PATH" 2>&1 | tee -a simple-test.log

echo ""
echo "========================"
echo "📊 Quick Analysis"
echo "========================"
echo ""

# 检查是否有并行执行的标记
if grep -q "🔄 Executing.*tools in parallel" simple-test.log; then
    PARALLEL_COUNT=$(grep -c "🔄 Executing.*tools in parallel" simple-test.log)
    echo "✅ Parallel execution detected: $PARALLEL_COUNT time(s)"
    
    # 显示并行执行的详细信息
    echo ""
    echo "Parallel execution details:"
    grep "🔄 Executing.*tools in parallel" simple-test.log
else
    echo "⚠️  No parallel execution message found"
    echo ""
    echo "Tool calls in the log:"
    grep "🔧 /" simple-test.log | head -10
fi

echo ""
echo "Total tool calls: $(grep -c "🔧 /" simple-test.log || echo "0")"
echo ""
echo "Full log saved to: simple-test.log"

