#!/bin/bash

# Quick test script that tests multiple commits but with shorter output
# Usage: ./test-review-cli-quick.sh [commit1] [commit2] ...

set -e

PROJECT_PATH="$(pwd)"
COMMITS=("${@}")

if [ ${#COMMITS[@]} -eq 0 ]; then
    # Test a few different commits
    COMMITS=(
        "e7462cb0b"
        "28371cf2e"
        "21e22e6fe"
    )
fi

echo "=========================================="
echo "Quick Test: Review CLI with Multiple Commits"
echo "=========================================="
echo "Project: $PROJECT_PATH"
echo "Commits: ${COMMITS[*]}"
echo ""

CONFIG_FILE="$HOME/.autodev/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

SUCCESS=0
FAIL=0

for COMMIT in "${COMMITS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing commit: $COMMIT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if commit exists
    if ! git rev-parse --verify "$COMMIT" >/dev/null 2>&1; then
        echo "❌ Commit $COMMIT not found, skipping..."
        FAIL=$((FAIL + 1))
        echo ""
        continue
    fi
    
    COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT")
    echo "📝 $COMMIT_MSG"
    
    # Get file count
    FILE_COUNT=$(git show "$COMMIT" --stat --format="" | grep -E "^ .*\|" | wc -l | tr -d ' ')
    echo "📁 Files changed: $FILE_COUNT"
    echo ""
    
    # Simple analysis
    ANALYSIS="Test analysis for commit $COMMIT. Files: $FILE_COUNT"
    
    echo "🚀 Running CLI (timeout: 2 minutes)..."
    
    # Run with timeout and capture output
    if timeout 120 ./gradlew :mpp-ui:runReviewCli \
        -PreviewProjectPath="$PROJECT_PATH" \
        -PreviewCommitHash="$COMMIT" \
        -PreviewAnalysis="$ANALYSIS" \
        -PreviewLanguage="EN" \
        --no-daemon \
        --quiet 2>&1 | tee "/tmp/review-test-$COMMIT.log" | grep -E "(✅|❌|Error|Success|Failed|completed)" | tail -5; then
        
        # Check result
        if grep -q "✅ Fix generation completed successfully" "/tmp/review-test-$COMMIT.log" 2>/dev/null; then
            echo "✅ PASSED: $COMMIT"
            SUCCESS=$((SUCCESS + 1))
        elif grep -q "❌\|Error\|Failed" "/tmp/review-test-$COMMIT.log" 2>/dev/null; then
            echo "❌ FAILED: $COMMIT"
            FAIL=$((FAIL + 1))
        else
            echo "⚠️  UNCLEAR: $COMMIT (check /tmp/review-test-$COMMIT.log)"
            FAIL=$((FAIL + 1))
        fi
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            echo "⏱️  TIMEOUT: $COMMIT"
        else
            echo "❌ ERROR: $COMMIT (exit: $EXIT_CODE)"
        fi
        FAIL=$((FAIL + 1))
    fi
    
    echo ""
    sleep 1
done

echo "=========================================="
echo "Summary: ✅ $SUCCESS passed, ❌ $FAIL failed"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    exit 0
else
    exit 1
fi

