#!/bin/bash

# Quick test for Review CLI with a single commit
# Usage: ./test-review-cli-single.sh [commit-hash]

set -e

PROJECT_PATH="$(pwd)"
COMMIT_HASH="${1:-e7462cb0b}"

echo "=========================================="
echo "Testing Review CLI - Single Commit"
echo "=========================================="
echo "Project Path: $PROJECT_PATH"
echo "Commit: $COMMIT_HASH"
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

# Get commit info
COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT_HASH" 2>/dev/null || echo "Unknown")
echo "📝 Commit: $COMMIT_MSG"
echo ""

# Get git diff
echo "📥 Getting git diff..."
PATCH=$(git show "$COMMIT_HASH" 2>/dev/null || echo "")

if [ -z "$PATCH" ]; then
    echo "❌ No git diff found for commit $COMMIT_HASH"
    exit 1
fi

PATCH_SIZE=${#PATCH}
FILE_COUNT=$(echo "$PATCH" | grep -E "^diff --git|^--- a/|^\+\+\+ b/" | grep -v "^+++ b/dev/null" | sed 's|^--- a/||;s|^\+\+\+ b/||' | sort -u | wc -l | tr -d ' ')

echo "✅ Got patch (${PATCH_SIZE} chars)"
echo "📁 Changed files: $FILE_COUNT"
echo ""

# Create analysis output
ANALYSIS_OUTPUT="## Walkthrough

This is a test code review analysis for commit $COMMIT_HASH.

## Changes

| Module | File | Summary |
|--------|------|---------|
| Code Review | \`Various files\` | Testing Review CLI with commit $COMMIT_HASH |

## Issues Found

1. Testing fix generation flow
2. Verifying CodingAgent integration"

echo "🚀 Running Review CLI..."
echo ""

# Run the CLI
cd "$(dirname "$0")/../.."

./gradlew :mpp-ui:runReviewCli \
    -PreviewProjectPath="$PROJECT_PATH" \
    -PreviewCommitHash="$COMMIT_HASH" \
    -PreviewAnalysis="$ANALYSIS_OUTPUT" \
    -PreviewLanguage="EN" \
    --no-daemon

echo ""
echo "✅ Review CLI test completed"

