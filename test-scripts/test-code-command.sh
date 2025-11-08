#!/bin/bash

# Test script for AutoDev CLI code command
# This script demonstrates the proper usage of the code command

cd "$(dirname "$0")/../../mpp-ui" || exit 1

echo "=== AutoDev CLI Code Command Test ==="
echo

# Test 1: Show help
echo "1. Testing help command:"
npm run code -- --help
echo

# Test 2: Show error when missing required arguments
echo "2. Testing error handling (missing required arguments):"
npm run code
echo

# Test 3: Show all available methods
echo "3. Available methods to run the code command:"
echo
echo "   Method 1 (Recommended - using dedicated code script):"
echo "   npm run code -- --path /path/to/project --task \"Your task description\""
echo
echo "   Method 2 (Using start script):"
echo "   npm run start -- code --path /path/to/project --task \"Your task description\""
echo
echo "   Method 3 (Direct binary execution):"
echo "   node dist/jsMain/typescript/index.js code --path /path/to/project --task \"Your task description\""
echo

echo "=== Test Complete ==="



