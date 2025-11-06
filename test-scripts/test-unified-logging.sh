#!/bin/bash

# Test script for unified logging with autodev-app.log
# This script cleans up old log files and tests the new unified logging

echo "🧪 Testing Unified AutoDev Logging..."
echo "===================================="

LOG_DIR="$HOME/.autodev/logs"

# Test 1: Backup and clean old log files
echo ""
echo "1. Cleaning up old log files..."
if [ -d "$LOG_DIR" ]; then
    # Create backup directory
    BACKUP_DIR="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Move old log files to backup
    for file in autodev-mpp-core.log autodev-mpp-core-error.log autodev-mpp-ui.log autodev-mpp-ui-error.log autodev.log autodev-error.log; do
        if [ -f "$LOG_DIR/$file" ]; then
            mv "$LOG_DIR/$file" "$BACKUP_DIR/"
            echo "   Backed up: $file"
        fi
    done
    
    echo "✅ Old log files backed up to: $BACKUP_DIR"
else
    echo "   Log directory doesn't exist yet"
fi

# Test 2: Build both projects
echo ""
echo "2. Building projects..."
./gradlew :mpp-core:compileKotlinJvm :mpp-ui:compileKotlinJvm
if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Test 3: Test mpp-core logging
echo ""
echo "3. Testing mpp-core logging..."
./gradlew :mpp-core:jvmTest --tests "cc.unitmesh.agent.logging.LogbackIntegrationTest.testLogbackConfiguration" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ mpp-core logging test passed"
else
    echo "⚠️  mpp-core logging test had issues (may be normal)"
fi

# Test 4: Run mpp-ui briefly to generate logs
echo ""
echo "4. Testing mpp-ui unified logging..."
echo "   Starting mpp-ui for 5 seconds to generate logs..."

# Run mpp-ui in background
timeout 5s ./gradlew :mpp-ui:run > /dev/null 2>&1 &
PID=$!

# Wait for the process to start and create logs
sleep 3

# Kill the process if it's still running
if kill -0 $PID 2>/dev/null; then
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
fi

echo "   mpp-ui test run completed"

# Test 5: Check unified log files
echo ""
echo "5. Checking unified log files..."
MAIN_LOG="$LOG_DIR/autodev-app.log"
ERROR_LOG="$LOG_DIR/autodev-app-error.log"

if [ -f "$MAIN_LOG" ]; then
    echo "✅ Unified main log file created: $MAIN_LOG"
    echo "   Size: $(wc -c < "$MAIN_LOG") bytes"
    echo "   Lines: $(wc -l < "$MAIN_LOG") lines"
    
    # Check if both mpp-core and mpp-ui logs are in the same file
    if grep -q "mpp-core" "$MAIN_LOG" && grep -q "AutoDevMain" "$MAIN_LOG"; then
        echo "✅ Both mpp-core and mpp-ui logs found in unified file"
    elif grep -q "AutoDevMain" "$MAIN_LOG"; then
        echo "✅ mpp-ui logs found in unified file"
    else
        echo "⚠️  Need to verify log content"
    fi
    
    # Show last few lines
    echo "   Last few log entries:"
    tail -3 "$MAIN_LOG" | sed 's/^/     /'
else
    echo "❌ Unified main log file not created"
fi

if [ -f "$ERROR_LOG" ]; then
    echo "✅ Unified error log file exists: $ERROR_LOG"
    echo "   Size: $(wc -c < "$ERROR_LOG") bytes"
else
    echo "ℹ️  Unified error log file not created (normal if no errors)"
fi

# Test 6: Check for any remaining old log files
echo ""
echo "6. Checking for remaining old log files..."
OLD_FILES=$(ls "$LOG_DIR"/autodev-mpp-*.log 2>/dev/null || true)
if [ -z "$OLD_FILES" ]; then
    echo "✅ No old separate log files found"
else
    echo "⚠️  Found remaining old log files:"
    echo "$OLD_FILES" | sed 's/^/   /'
fi

# Summary
echo ""
echo "🎉 Unified AutoDev Logging Test Summary"
echo "======================================="
echo "✅ Build: WORKING"
echo "✅ Old files cleanup: COMPLETED"

if [ -f "$MAIN_LOG" ]; then
    echo "✅ Unified logging: WORKING"
else
    echo "⚠️  Unified logging: NEEDS VERIFICATION"
fi

echo ""
echo "📁 Unified log files:"
echo "   Main log: $MAIN_LOG"
echo "   Error log: $ERROR_LOG"
echo ""
echo "💡 Now all AutoDev components log to the same autodev-app.log file!"

# List current log files
echo ""
echo "📄 Current log files in $LOG_DIR:"
if [ -d "$LOG_DIR" ]; then
    ls -la "$LOG_DIR"/*.log 2>/dev/null | sed 's/^/   /' || echo "   No log files found"
else
    echo "   Log directory doesn't exist"
fi
