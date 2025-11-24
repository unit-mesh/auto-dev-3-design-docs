#!/bin/bash

# Test script for Review CLI
# This script tests the CodeReviewAgent.generateFixes flow using CodingAgent

set -e

PROJECT_PATH="${1:-$(pwd)}"
COMMIT_HASH="${2:-HEAD}"

echo "=========================================="
echo "Testing Review CLI"
echo "=========================================="
echo "Project Path: $PROJECT_PATH"
echo "Commit Hash: $COMMIT_HASH"
echo ""

# Get git diff
echo "📥 Getting git diff..."
PATCH=$(git -C "$PROJECT_PATH" show "$COMMIT_HASH" 2>/dev/null || git -C "$PROJECT_PATH" diff HEAD~1 HEAD 2>/dev/null || echo "")

if [ -z "$PATCH" ]; then
    echo "❌ No git diff found. Please provide a valid commit hash or ensure you have changes."
    exit 1
fi

echo "✅ Got patch (${#PATCH} chars)"
echo ""

# Create a simple analysis output
ANALYSIS_OUTPUT="## Walkthrough

This is a test code review analysis. The changes introduce new functionality.

## Changes

| Module | File | Summary |
|--------|------|---------|
| Core | \`src/main/kotlin/Example.kt\` | Added new function with potential issues |

## Issues Found

1. Missing null check
2. Potential resource leak
3. Code style violations"

echo "📊 Analysis Output:"
echo "$ANALYSIS_OUTPUT"
echo ""

# Run the CLI
echo "🚀 Running Review CLI..."
echo ""

cd "$(dirname "$0")/../.."

./gradlew :mpp-ui:runReviewCli \
    -PreviewProjectPath="$PROJECT_PATH" \
    -PreviewCommitHash="$COMMIT_HASH" \
    -PreviewAnalysis="$ANALYSIS_OUTPUT" \
    -PreviewLanguage="EN" \
    --no-daemon

echo ""
echo "✅ Review CLI test completed"

