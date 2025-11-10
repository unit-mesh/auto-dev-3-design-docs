#!/bin/bash
# Complete flow test: Git Clone + Agent execution via CLI
#
# This tests the full workflow of cloning a repository and running an agent task

set -e

echo "🧪 Testing complete workflow: Git Clone + Agent"
echo ""

# Kill any existing server
pkill -f "mpp-server" || true
sleep 2

# Start the server in the background
echo "🚀 Starting mpp-server..."
cd /Volumes/source/ai/autocrud/mpp-server
./build/install/mpp-server/bin/mpp-server > /tmp/mpp-server.log 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to be ready
echo "⏳ Waiting for server to start..."
for i in {1..30}; do
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Server is ready"
    break
  fi
  sleep 1
done

# Test with Git Clone
echo ""
echo "📦 Testing Git Clone + Agent execution..."
echo ""

curl -N -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "projectId": "test-untitled",
    "task": "List the main Java source files in this Spring Boot project",
    "gitUrl": "https://github.com/unit-mesh/untitled",
    "branch": "master"
  }' \
  --max-time 120 2>&1

echo ""
echo "✅ Test completed"
echo ""

# Cleanup
kill $SERVER_PID || true

