#!/bin/bash

# Simple test script to verify wasm codegraph setup
# This script builds the wasm module and attempts basic verification

set -e

echo "=== Building mpp-codegraph wasmJs module ==="
./gradlew :mpp-codegraph:clean :mpp-codegraph:wasmJsProductionLibrary

echo ""
echo "=== Checking generated files ==="
ls -lh mpp-codegraph/build/dist/wasmJs/productionLibrary/

echo ""
echo "=== Checking for web-tree-sitter in node_modules ==="
if [ -d "build/wasm/node_modules/web-tree-sitter" ]; then
    echo "✓ web-tree-sitter found"
    ls -lh build/wasm/node_modules/web-tree-sitter/ | head -10
else
    echo "✗ web-tree-sitter NOT found"
fi

echo ""
echo "=== Checking for treesitter-artifacts in node_modules ==="
if [ -d "build/wasm/node_modules/@unit-mesh/treesitter-artifacts" ]; then
    echo "✓ treesitter-artifacts found"
    ls -lh build/wasm/node_modules/@unit-mesh/treesitter-artifacts/ | head -10
else
    echo "✗ treesitter-artifacts NOT found"
fi

echo ""
echo "=== Build complete ==="
