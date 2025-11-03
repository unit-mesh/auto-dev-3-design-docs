#!/bin/bash

# Test script for CLI improvements
# Tests the optimized CLI tool with the improvements made

echo "🧪 Testing CLI improvements..."
echo "================================"

# Create a simple test project
TEST_DIR="/tmp/autodev-cli-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Create a simple Java file for testing
cat > "$TEST_DIR/Hello.java" << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
        
        // Some additional code to test syntax highlighting
        String message = "This is a test";
        int number = 42;
        
        if (number > 0) {
            System.out.println("Number is positive: " + number);
        }
    }
}
EOF

# Create a simple build file
cat > "$TEST_DIR/build.gradle" << 'EOF'
plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation 'junit:junit:4.13.2'
}
EOF

echo "📁 Created test project at: $TEST_DIR"
echo "📄 Files created:"
ls -la "$TEST_DIR"

echo ""
echo "🚀 Running CLI with improvements..."
echo "This should demonstrate:"
echo "1. ✅ No <devin> blocks in output"
echo "2. ✅ Human-readable tool descriptions"
echo "3. ✅ Proper code formatting with line numbers"
echo "4. ✅ Duplicate tool call detection"
echo ""

# Run the CLI tool
cd /Volumes/source/ai/autocrud/mpp-ui
node dist/index.js code --path "$TEST_DIR" --task "Review the Hello.java file and suggest improvements" --max-iterations 5

echo ""
echo "🧹 Cleaning up test directory..."
rm -rf "$TEST_DIR"
echo "✅ Test completed!"
