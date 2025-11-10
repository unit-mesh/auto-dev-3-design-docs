#!/bin/bash

# Compare Kotlin and TypeScript CLI implementations
# This script runs both versions side-by-side for comparison

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  AutoDev CLI Comparison Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if mpp-server is running
echo -e "${YELLOW}Checking if mpp-server is running...${NC}"
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${RED}✗ mpp-server is not running!${NC}"
    echo ""
    echo "Please start mpp-server first:"
    echo "  cd $PROJECT_ROOT"
    echo "  ./gradlew :mpp-server:run"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ mpp-server is running${NC}"
echo ""

# Parse arguments
TASK="${1:-编写 BlogService 测试}"
PROJECT_ID="${2:-https://github.com/unit-mesh/untitled}"
SERVER="${3:-http://localhost:8080}"

echo -e "${BLUE}Test Parameters:${NC}"
echo "  Task: $TASK"
echo "  Project: $PROJECT_ID"
echo "  Server: $SERVER"
echo ""

# Create temp log files
KOTLIN_LOG=$(mktemp)
TS_LOG=$(mktemp)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Running TypeScript CLI...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT/mpp-ui"

# Build TypeScript CLI if needed
if [ ! -d "dist/jsMain/typescript" ]; then
    echo -e "${YELLOW}Building TypeScript CLI...${NC}"
    npm run build
    echo ""
fi

# Run TypeScript CLI
echo "$ node dist/jsMain/typescript/index.js server --task \"$TASK\" --project-id \"$PROJECT_ID\" -s \"$SERVER\""
echo ""

node dist/jsMain/typescript/index.js server \
  --task "$TASK" \
  --project-id "$PROJECT_ID" \
  -s "$SERVER" | tee "$TS_LOG"

TS_EXIT_CODE=$?

echo ""
echo -e "${GREEN}TypeScript CLI completed with exit code: $TS_EXIT_CODE${NC}"
echo ""

# Wait a bit before running Kotlin version
sleep 2

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Running Kotlin CLI...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"

echo "$ ./gradlew :mpp-ui:run --args=\"--task '$TASK' --project-id '$PROJECT_ID' --server '$SERVER'\""
echo ""

./gradlew :mpp-ui:run --args="--task \"$TASK\" --project-id \"$PROJECT_ID\" --server \"$SERVER\"" | tee "$KOTLIN_LOG"

KOTLIN_EXIT_CODE=$?

echo ""
echo -e "${GREEN}Kotlin CLI completed with exit code: $KOTLIN_EXIT_CODE${NC}"
echo ""

# Compare results
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Comparison Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check exit codes
if [ "$TS_EXIT_CODE" -eq "$KOTLIN_EXIT_CODE" ]; then
    echo -e "${GREEN}✓ Exit codes match: $TS_EXIT_CODE${NC}"
else
    echo -e "${RED}✗ Exit codes differ:${NC}"
    echo "  TypeScript: $TS_EXIT_CODE"
    echo "  Kotlin: $KOTLIN_EXIT_CODE"
fi
echo ""

# Check for key markers in output
echo "Checking output consistency..."
echo ""

# Function to check for marker in log
check_marker() {
    local marker="$1"
    local ts_log="$2"
    local kotlin_log="$3"
    
    local ts_has=$(grep -c "$marker" "$ts_log" || echo "0")
    local kotlin_has=$(grep -c "$marker" "$kotlin_log" || echo "0")
    
    if [ "$ts_has" -gt 0 ] && [ "$kotlin_has" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Both have: $marker"
    elif [ "$ts_has" -eq 0 ] && [ "$kotlin_has" -eq 0 ]; then
        echo -e "${YELLOW}○${NC} Neither has: $marker"
    else
        echo -e "${RED}✗${NC} Mismatch: $marker (TS: $ts_has, Kotlin: $kotlin_has)"
    fi
}

check_marker "Server is" "$TS_LOG" "$KOTLIN_LOG"
check_marker "Cloning repository" "$TS_LOG" "$KOTLIN_LOG"
check_marker "Clone completed" "$TS_LOG" "$KOTLIN_LOG"
check_marker "Repository ready" "$TS_LOG" "$KOTLIN_LOG"
check_marker "Task completed" "$TS_LOG" "$KOTLIN_LOG"

echo ""
echo "Log files saved at:"
echo "  TypeScript: $TS_LOG"
echo "  Kotlin: $KOTLIN_LOG"
echo ""

# Offer to show diff
read -p "Show detailed diff? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}Detailed Diff:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    diff -u "$TS_LOG" "$KOTLIN_LOG" || true
fi

echo ""
echo -e "${GREEN}Comparison complete!${NC}"
echo ""

