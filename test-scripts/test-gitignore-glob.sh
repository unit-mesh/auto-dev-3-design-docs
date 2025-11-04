#!/bin/bash

# Test script for GitIgnore support in GlobTool
# This script creates a test project structure with .gitignore files
# and verifies that the GlobTool respects gitignore rules

set -e

echo "=== Testing GitIgnore Support in GlobTool ==="
echo ""

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
echo "Created test directory: $TEST_DIR"

# Setup test project structure
cd "$TEST_DIR"

# Create directory structure
mkdir -p src/main/kotlin
mkdir -p src/test/kotlin
mkdir -p build/classes
mkdir -p target/output
mkdir -p node_modules/package
mkdir -p .git/info

# Create test files
touch src/main/kotlin/Main.kt
touch src/main/kotlin/Utils.kt
touch src/test/kotlin/MainTest.kt
touch build/classes/Main.class
touch target/output/app.jar
touch node_modules/package/index.js
touch README.md
touch .gitignore
touch local.properties

# Create .gitignore file
cat > .gitignore << 'EOF'
# Build outputs
*.class
*.jar
build/
target/

# Dependencies
node_modules/

# Local config
local.properties

# Keep important files
!important.jar
EOF

# Create nested .gitignore
cat > src/.gitignore << 'EOF'
# Ignore generated files in src
*.generated.kt
EOF

# Create a generated file
touch src/main/kotlin/Generated.generated.kt

echo ""
echo "Test project structure created:"
find . -type f | sort

echo ""
echo "=== Running mpp-core tests ==="
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:cleanTest :mpp-core:test --tests "cc.unitmesh.agent.tool.gitignore.*"

echo ""
echo "=== Test completed successfully ==="
echo "Cleaning up test directory: $TEST_DIR"
rm -rf "$TEST_DIR"

