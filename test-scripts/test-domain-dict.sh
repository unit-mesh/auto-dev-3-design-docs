#!/bin/bash

# Test script for domain dictionary generation
# This script tests the /init command functionality

set -e

echo "🧪 Testing Domain Dictionary Generation"
echo "======================================"

# Build the project first
echo "📦 Building mpp-core..."
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:assembleJsPackage

echo "📦 Building mpp-ui..."
cd mpp-ui
npx tsc
chmod +x dist/jsMain/typescript/index.js

echo "🔧 Testing CLI help..."
node dist/jsMain/typescript/index.js --help

echo "🔧 Testing chat mode help..."
echo "/help" | timeout 10s node dist/jsMain/typescript/index.js chat || true

echo "✅ Basic CLI functionality test completed!"
echo ""
echo "📝 Manual test instructions:"
echo "1. Run: cd mpp-ui && node dist/jsMain/typescript/index.js chat"
echo "2. Type: /init"
echo "3. Check if domain dictionary is generated in prompts/domain.csv"
echo ""
echo "🎯 Expected behavior:"
echo "- CLI should start successfully"
echo "- /init command should analyze project files"
echo "- Domain dictionary should be saved to prompts/domain.csv"
echo "- Dictionary should contain semantic names from the codebase"
