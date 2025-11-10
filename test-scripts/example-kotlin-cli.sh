#!/bin/bash

# Example usage of the Kotlin RemoteAgentCli
# This demonstrates the same usage as the TypeScript version

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo ""
echo "🚀 Kotlin RemoteAgentCli Example"
echo ""
echo "This is equivalent to the TypeScript CLI command:"
echo ""
echo "  node dist/jsMain/typescript/index.js server \\"
echo "    --task \"编写 BlogService 测试\" \\"
echo "    --project-id https://github.com/unit-mesh/untitled \\"
echo "    -s http://localhost:8080"
echo ""
echo "Running Kotlin version..."
echo ""

cd "$PROJECT_ROOT"

./gradlew :mpp-ui:run --args="--task \"编写 BlogService 测试\" --project-id https://github.com/unit-mesh/untitled --server http://localhost:8080"

