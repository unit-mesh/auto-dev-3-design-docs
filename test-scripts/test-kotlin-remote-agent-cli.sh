#!/bin/bash

# Test Kotlin Remote Agent CLI
# This script tests the Kotlin CLI implementation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Kotlin Remote Agent CLI Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Configuration
SERVER_URL="${SERVER_URL:-http://localhost:8080}"
PROJECT_ID="${PROJECT_ID:-autocrud}"
TASK="${TASK:-列出所有 Kotlin 文件}"

echo -e "${GREEN}Configuration:${NC}"
echo -e "  Server: ${SERVER_URL}"
echo -e "  Project: ${PROJECT_ID}"
echo -e "  Task: ${TASK}"
echo ""

# Check server health
echo -e "${YELLOW}Checking server...${NC}"
if curl -sf "${SERVER_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is running${NC}"
else
    echo -e "${RED}✗ Server not responding at ${SERVER_URL}${NC}"
    echo -e "${YELLOW}  Please start mpp-server first:${NC}"
    echo -e "  cd $PROJECT_ROOT"
    echo -e "  ./gradlew :mpp-server:bootRun"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Test 1: Show help${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"
./gradlew :mpp-ui:runRemoteAgentCli --args="--help" --console=plain 2>&1 | grep -A 30 "AutoDev Remote Agent CLI"

echo ""
echo -e "${GREEN}✓ Help test passed${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Test 2: Run actual task${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run the CLI
./gradlew :mpp-ui:runRemoteAgentCli --args="--server ${SERVER_URL} --project-id ${PROJECT_ID} --task \"${TASK}\" --use-server-config" --console=plain

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}All tests completed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

