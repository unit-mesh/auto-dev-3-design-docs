#!/bin/bash

# Test runner for optimized AI Agent architecture
# This script runs all tests to verify the optimized agent implementation

set -e  # Exit on any error

echo "🧪 Running All AI Agent Architecture Tests"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${BLUE}🔍 Running: $test_name${NC}"
    echo "----------------------------------------"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 1. Build and compile tests
echo -e "${YELLOW}📦 Building project...${NC}"
cd "$(dirname "$0")/../.."
./gradlew :mpp-core:compileKotlinJvm

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed! Cannot proceed with tests.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"

# 2. Run unit tests
run_test "Unit Tests" "./gradlew :mpp-core:test"

# 3. Run Kotlin script tests (if kotlin command is available)
if command -v kotlin &> /dev/null; then
    run_test "CodebaseInvestigatorAgent Test" "kotlin docs/test-scripts/test-codebase-investigator.kt"
    run_test "Optimized CodingAgent Test" "kotlin docs/test-scripts/test-optimized-coding-agent.kt"
    run_test "Agent Integration Test" "kotlin docs/test-scripts/test-agent-integration.kt"
else
    echo -e "${YELLOW}⚠️  Kotlin command not found. Skipping script tests.${NC}"
    echo "   To run script tests, install Kotlin CLI or run them manually."
fi

# 4. Run specific architecture tests
run_test "Agent Communication Tests" "./gradlew :mpp-core:test --tests '*AgentChannel*'"
run_test "SubAgent Tests" "./gradlew :mpp-core:test --tests '*SubAgent*'"
run_test "DefaultAgentExecutor Tests" "./gradlew :mpp-core:test --tests '*DefaultAgentExecutor*'"

# 5. Run integration tests
run_test "Full Integration Tests" "./gradlew :mpp-core:test --tests '*Integration*'"

# 6. Build CLI to verify end-to-end functionality
echo -e "\n${YELLOW}🔧 Testing CLI build...${NC}"
run_test "CLI Build Test" "cd mpp-ui && npm run build:ts"

# Summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "================"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! The optimized AI Agent architecture is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed. Please review the output above.${NC}"
    exit 1
fi
