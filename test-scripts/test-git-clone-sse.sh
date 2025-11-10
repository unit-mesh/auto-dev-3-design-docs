#!/bin/bash
# Test SSE API with Git Clone functionality
# Usage: ./test-git-clone-sse.sh

set -e

echo "🔍 Testing SSE API with Git Clone..."
echo ""

# Test with a public GitHub repository
GIT_URL="https://github.com/unit-mesh/auto-dev"
BRANCH="master"
PROJECT_ID="auto-dev-test"
TASK="List the main files and folders in this project"

echo "📦 Testing git clone + agent execution:"
echo "   Git URL: $GIT_URL"
echo "   Branch: $BRANCH"
echo "   Project ID: $PROJECT_ID"
echo "   Task: $TASK"
echo ""

# URL encode the parameters
ENCODED_GIT_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$GIT_URL'))")
ENCODED_TASK=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$TASK'))")
ENCODED_BRANCH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$BRANCH'))")

curl -N "http://localhost:8080/api/agent/stream?projectId=${PROJECT_ID}&task=${ENCODED_TASK}&gitUrl=${ENCODED_GIT_URL}&branch=${ENCODED_BRANCH}" \
  -H "Accept: text/event-stream" \
  --max-time 120 2>&1

echo ""
echo "✅ Test completed!"

