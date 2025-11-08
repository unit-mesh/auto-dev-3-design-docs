#!/bin/bash

# 测试并行工具执行的脚本
# 创建时间: 2025-01-07
# 用途: 验证 CodingAgent 的并行工具执行功能

set -e

echo "=================================="
echo "🧪 Testing Parallel Tool Execution"
echo "=================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试项目路径
TEST_PROJECT="/Users/phodal/IdeaProjects/untitled"

# CLI 路径
CLI_PATH="/Volumes/source/ai/autocrud/mpp-ui/dist/jsMain/typescript/index.js"

# 检查 CLI 是否存在
if [ ! -f "$CLI_PATH" ]; then
    echo "❌ CLI not found at $CLI_PATH"
    echo "Please run: cd mpp-ui && npm run build"
    exit 1
fi

# 测试场景 1: 多文件读取（应该触发并行读取）
echo -e "${BLUE}📝 Test 1: Multiple File Reading${NC}"
echo "Task: Read and summarize build.gradle.kts, settings.gradle.kts, and gradle.properties"
echo ""
node "$CLI_PATH" code \
  --task "Read the contents of build.gradle.kts, settings.gradle.kts, and gradle.properties files and give me a brief summary of each" \
  -p "$TEST_PROJECT" 2>&1 | tee test1-output.log

echo ""
echo -e "${YELLOW}Checking for parallel execution indicators...${NC}"
grep -i "parallel" test1-output.log || echo "⚠️  No parallel execution message found"
grep -i "read-file" test1-output.log | head -5
echo ""
echo "---"
echo ""

# 测试场景 2: Spring AI 集成（复杂任务，应触发多个工具）
echo -e "${BLUE}📝 Test 2: Spring AI Integration (Complex Task)${NC}"
echo "Task: Add Spring AI with DeepSeek to project"
echo ""
node "$CLI_PATH" code \
  --task "Add Spring AI to project with DeepSeek integration. I use deepseek. Create a simple service example that uses the ChatClient. Here is the documentation: https://docs.spring.io/spring-ai/reference/api/chat/deepseek-chat.html" \
  -p "$TEST_PROJECT" 2>&1 | tee test2-output.log

echo ""
echo -e "${YELLOW}Checking for parallel execution indicators...${NC}"
grep -i "parallel" test2-output.log || echo "⚠️  No parallel execution message found"
grep -c "🔧" test2-output.log | xargs -I {} echo "Tool calls: {}"
echo ""
echo "---"
echo ""

# 测试场景 3: 多个搜索和读取操作
echo -e "${BLUE}📝 Test 3: Multiple Search and Read Operations${NC}"
echo "Task: Find all Kotlin files and Java files in src directory"
echo ""
node "$CLI_PATH" code \
  --task "Find all .kt files and all .java files in the src directory, then show me the count for each" \
  -p "$TEST_PROJECT" 2>&1 | tee test3-output.log

echo ""
echo -e "${YELLOW}Checking for parallel execution indicators...${NC}"
grep -i "parallel" test3-output.log || echo "⚠️  No parallel execution message found"
grep -i "glob\|grep" test3-output.log | head -5
echo ""
echo "---"
echo ""

# 测试场景 4: 混合操作（读取 + 搜索）
echo -e "${BLUE}📝 Test 4: Mixed Operations (Read + Search)${NC}"
echo "Task: Analyze project structure"
echo ""
node "$CLI_PATH" code \
  --task "I want to understand this project. Please: 1) Read the README.md file, 2) List all files matching *.gradle*, 3) Find all main class files" \
  -p "$TEST_PROJECT" 2>&1 | tee test4-output.log

echo ""
echo -e "${YELLOW}Checking for parallel execution indicators...${NC}"
grep -i "parallel" test4-output.log || echo "⚠️  No parallel execution message found"
grep -c "🔧" test4-output.log | xargs -I {} echo "Tool calls: {}"
echo ""
echo "---"
echo ""

# 汇总结果
echo ""
echo "=================================="
echo "📊 Test Summary"
echo "=================================="
echo ""

echo "Test output files generated:"
ls -lh test*-output.log

echo ""
echo "Parallel execution analysis:"
for i in 1 2 3 4; do
    count=$(grep -c "parallel" "test${i}-output.log" || echo "0")
    if [ "$count" -gt 0 ]; then
        echo -e "  Test $i: ${GREEN}✓ Detected $count parallel execution(s)${NC}"
    else
        echo -e "  Test $i: ${YELLOW}⚠️  No parallel execution detected${NC}"
    fi
done

echo ""
echo "Tool call counts per test:"
for i in 1 2 3 4; do
    count=$(grep -c "🔧" "test${i}-output.log" || echo "0")
    echo "  Test $i: $count tool call(s)"
done

echo ""
echo -e "${GREEN}✅ All tests completed!${NC}"
echo ""
echo "Review the test*-output.log files for detailed analysis."


