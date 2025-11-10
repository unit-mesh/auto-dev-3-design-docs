#!/bin/bash
# Test POST SSE API (used by CLI client)
# Usage: ./test-post-sse.sh

set -e

echo "🔍 Testing POST SSE API (Client-Server compatibility)..."
echo ""

# Test 1: Health check
echo "1️⃣  Health check:"
curl -s http://localhost:8080/health | jq
echo ""

# Test 2: List projects
echo "2️⃣  Available projects:"
curl -s http://localhost:8080/api/projects | jq '.projects[] | {id, name}'
echo ""

# Test 3: POST SSE with existing project
PROJECT_ID=".vim_runtime"
TASK="list the main configuration files"

echo "3️⃣  Testing POST SSE API with existing project:"
echo "   Method: POST"
echo "   Project: $PROJECT_ID"
echo "   Task: $TASK"
echo ""

curl -N -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d "{
    \"projectId\": \"${PROJECT_ID}\",
    \"task\": \"${TASK}\"
  }" \
  --max-time 30 2>&1 | head -100

echo ""
echo "✅ POST SSE API test completed!"

