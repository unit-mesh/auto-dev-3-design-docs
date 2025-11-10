#!/bin/bash
# Test CLI with Git Clone (simulated through POST API since CLI doesn't support gitUrl yet)
# Usage: ./test-cli-with-git-clone.sh

set -e

echo "🔍 Testing Git Clone + Agent with improved CLI output..."
echo ""
echo "Note: This test uses curl to POST since CLI doesn't support gitUrl parameter yet."
echo "The output simulates what the CLI will show after we add gitUrl support."
echo ""

# Pipe the SSE stream through a simple Node.js renderer
cd /Volumes/source/ai/autocrud/mpp-ui

node -e "
const { ServerRenderer } = require('./dist/jsMain/typescript/agents/render/ServerRenderer.js');
const readline = require('readline');

const renderer = new ServerRenderer();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

let currentEvent = '';
let currentData = '';

rl.on('line', (line) => {
  if (line.startsWith('event:')) {
    currentEvent = line.substring(6).trim();
  } else if (line.startsWith('data:')) {
    currentData = line.substring(5).trim();
  } else if (line.trim() === '' && currentEvent && currentData) {
    try {
      const parsed = JSON.parse(currentData);
      const event = { type: currentEvent, ...parsed };
      renderer.renderEvent(event);
    } catch (e) {
      // Skip invalid events
    }
    currentEvent = '';
    currentData = '';
  }
});

rl.on('close', () => {
  console.log('\\n✅ Stream ended');
});
" < <(curl -N -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "projectId": "untitled-test",
    "task": "分析这个 Spring Boot 项目的主要 Java 文件",
    "gitUrl": "https://github.com/unit-mesh/untitled",
    "branch": "master"
  }' \
  --max-time 60 2>&1 | grep -E "^(event:|data:)")

echo ""
echo "✅ Test completed!"

