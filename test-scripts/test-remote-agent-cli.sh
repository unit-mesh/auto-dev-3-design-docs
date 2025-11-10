#!/bin/bash

# Test script for Remote Agent CLI (Kotlin version)
# This script demonstrates how to use the Kotlin CLI to connect to mpp-server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Remote Agent CLI Test Script (Kotlin)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Configuration
SERVER_URL="${SERVER_URL:-http://localhost:8080}"
PROJECT_ID="${PROJECT_ID:-autocrud}"
TASK="${TASK:-Write tests for BlogService}"
PROVIDER="${PROVIDER:-deepseek}"
MODEL="${MODEL:-deepseek-chat}"
API_KEY="${API_KEY:-}"

# Check if API key is provided
if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}⚠️  Warning: API_KEY not set. Using server config.${NC}"
    USE_SERVER_CONFIG="--use-server-config"
else
    USE_SERVER_CONFIG=""
fi

echo -e "${GREEN}Configuration:${NC}"
echo -e "  Server URL: ${BLUE}$SERVER_URL${NC}"
echo -e "  Project ID: ${BLUE}$PROJECT_ID${NC}"
echo -e "  Task: ${BLUE}$TASK${NC}"
echo -e "  Provider: ${BLUE}$PROVIDER${NC}"
echo -e "  Model: ${BLUE}$MODEL${NC}"
echo ""

# Check if server is running
echo -e "${YELLOW}Checking if server is running...${NC}"
if curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Server is running${NC}"
else
    echo -e "${RED}❌ Server is not running at $SERVER_URL${NC}"
    echo -e "${YELLOW}Please start the server first:${NC}"
    echo -e "  cd /Volumes/source/ai/autocrud"
    echo -e "  ./gradlew :mpp-server:run"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Running Kotlin Remote Agent CLI...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Build the arguments
ARGS="--server $SERVER_URL --project-id $PROJECT_ID --task \"$TASK\""

if [ -n "$USE_SERVER_CONFIG" ]; then
    ARGS="$ARGS $USE_SERVER_CONFIG"
else
    ARGS="$ARGS --provider $PROVIDER --model $MODEL --api-key $API_KEY"
fi

# Run the CLI
cd /Volumes/source/ai/autocrud

echo -e "${YELLOW}Command:${NC}"
echo -e "  ./gradlew :mpp-ui:runRemoteAgentCli --args=\"$ARGS\""
echo ""

# Execute
./gradlew :mpp-ui:runRemoteAgentCli --args="$ARGS"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Test completed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

