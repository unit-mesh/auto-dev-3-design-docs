#!/bin/bash

# Test Review CLI with multiple commits
# This script tests the CodeReviewAgent.generateFixes flow with different commits

set -e

PROJECT_PATH="${1:-$(pwd)}"
COMMITS=("${@:2}")

if [ ${#COMMITS[@]} -eq 0 ]; then
    # Default commits to test
    COMMITS=(
        "e7462cb0b"
        "28371cf2e"
        "21e22e6fe"
        "55bc5b4d9"
    )
fi

echo "=========================================="
echo "Testing Review CLI with Multiple Commits"
echo "=========================================="
echo "Project Path: $PROJECT_PATH"
echo "Commits to test: ${COMMITS[*]}"
echo ""

# Check if config exists
CONFIG_FILE="$HOME/.autodev/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "   Please create ~/.autodev/config.yaml with your LLM configuration"
    exit 1
fi

echo "✅ Found config file: $CONFIG_FILE"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL=${#COMMITS[@]}

for i in "${!COMMITS[@]}"; do
    COMMIT="${COMMITS[$i]}"
    COMMIT_NUM=$((i + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test $COMMIT_NUM/$TOTAL: Commit $COMMIT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Get commit message
    COMMIT_MSG=$(git -C "$PROJECT_PATH" log -1 --pretty=format:"%s" "$COMMIT" 2>/dev/null || echo "Unknown")
    echo "📝 Commit: $COMMIT_MSG"
    echo ""
    
    # Get git diff
    echo "📥 Getting git diff..."
    PATCH=$(git -C "$PROJECT_PATH" show "$COMMIT" 2>/dev/null || echo "")
    
    if [ -z "$PATCH" ]; then
        echo "⚠️  No git diff found for commit $COMMIT, skipping..."
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo ""
        continue
    fi
    
    PATCH_SIZE=${#PATCH}
    echo "✅ Got patch (${PATCH_SIZE} chars)"
    
    # Extract file paths
    FILE_COUNT=$(echo "$PATCH" | grep -E "^diff --git|^--- a/|^\+\+\+ b/" | grep -v "^+++ b/dev/null" | sed 's|^--- a/||;s|^\+\+\+ b/||' | sort -u | wc -l | tr -d ' ')
    echo "📁 Changed files: $FILE_COUNT"
    echo ""
    
    # Create a simple analysis output
    ANALYSIS_OUTPUT="## Walkthrough

This is a test code review analysis for commit $COMMIT.

## Changes

| Module | File | Summary |
|--------|------|---------|
| Test | \`Various files\` | Testing Review CLI with commit $COMMIT |

## Issues Found

1. Testing fix generation flow
2. Verifying CodingAgent integration
3. Checking lint results processing"

    echo "🚀 Running Review CLI..."
    echo ""
    
    # Run the CLI with timeout (5 minutes)
    if timeout 300 ./gradlew :mpp-ui:runReviewCli \
        -PreviewProjectPath="$PROJECT_PATH" \
        -PreviewCommitHash="$COMMIT" \
        -PreviewAnalysis="$ANALYSIS_OUTPUT" \
        -PreviewLanguage="EN" \
        --no-daemon \
        --quiet 2>&1 | tee "/tmp/review-cli-test-$COMMIT.log"; then
        
        # Check if the output indicates success
        if grep -q "✅ Fix generation completed successfully" "/tmp/review-cli-test-$COMMIT.log" 2>/dev/null; then
            echo ""
            echo "✅ Test $COMMIT_NUM PASSED: Commit $COMMIT"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        elif grep -q "❌ Fix generation failed\|Error:" "/tmp/review-cli-test-$COMMIT.log" 2>/dev/null; then
            echo ""
            echo "❌ Test $COMMIT_NUM FAILED: Commit $COMMIT (Error detected)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        else
            echo ""
            echo "⚠️  Test $COMMIT_NUM INCOMPLETE: Commit $COMMIT (No clear success/failure indicator)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            echo ""
            echo "⏱️  Test $COMMIT_NUM TIMEOUT: Commit $COMMIT (exceeded 5 minutes)"
        else
            echo ""
            echo "❌ Test $COMMIT_NUM FAILED: Commit $COMMIT (exit code: $EXIT_CODE)"
        fi
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Small delay between tests
    sleep 2
done

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total commits tested: $TOTAL"
echo "✅ Successful: $SUCCESS_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Check logs in /tmp/review-cli-test-*.log"
    exit 1
fi

