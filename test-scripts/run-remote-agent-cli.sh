#!/bin/bash

# Run RemoteAgentCli - Kotlin version of the TypeScript CLI
# This script builds and runs the Kotlin CLI for testing RemoteAgentClient

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔨 Building mpp-ui module..."
cd "$PROJECT_ROOT"
./gradlew :mpp-ui:assemble

echo ""
echo "🔨 Compiling RemoteAgentCli.kt..."
cd "$SCRIPT_DIR"

# Find the mpp-ui JAR
MPP_UI_JAR=$(find "$PROJECT_ROOT/mpp-ui/build/libs" -name "mpp-ui-*.jar" | grep -v "sources" | grep -v "javadoc" | head -n 1)

if [ -z "$MPP_UI_JAR" ]; then
    echo "❌ Error: Could not find mpp-ui JAR file"
    echo "Please run: ./gradlew :mpp-ui:assemble"
    exit 1
fi

echo "   Using JAR: $MPP_UI_JAR"

# Compile the CLI
kotlinc RemoteAgentCli.kt \
    -include-runtime \
    -d RemoteAgentCli.jar \
    -cp "$MPP_UI_JAR:$HOME/.gradle/caches/modules-2/files-2.1/**/*.jar" \
    -jvm-target 17

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""
echo "🚀 Running RemoteAgentCli..."
echo ""

# Run the CLI with provided arguments
kotlin -cp "RemoteAgentCli.jar:$MPP_UI_JAR" cc.unitmesh.devins.cli.test.RemoteAgentCliKt "$@"

