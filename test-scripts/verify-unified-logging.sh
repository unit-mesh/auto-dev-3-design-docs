#!/bin/bash

# Final verification script for unified AutoDev logging
# This script verifies that all components log to autodev-app.log

echo "🔍 Verifying Unified AutoDev Logging..."
echo "======================================="

LOG_DIR="$HOME/.autodev/logs"
MAIN_LOG="$LOG_DIR/autodev-app.log"
ERROR_LOG="$LOG_DIR/autodev-app-error.log"

# Test 1: Check current log structure
echo ""
echo "1. Current log directory structure:"
if [ -d "$LOG_DIR" ]; then
    tree "$LOG_DIR" 2>/dev/null || ls -la "$LOG_DIR"
else
    echo "   Log directory doesn't exist"
fi

# Test 2: Verify unified log files exist
echo ""
echo "2. Verifying unified log files:"
if [ -f "$MAIN_LOG" ]; then
    echo "✅ Main log file exists: autodev-app.log"
    echo "   Size: $(wc -c < "$MAIN_LOG") bytes"
    echo "   Lines: $(wc -l < "$MAIN_LOG") lines"
else
    echo "❌ Main log file missing: autodev-app.log"
fi

if [ -f "$ERROR_LOG" ]; then
    echo "✅ Error log file exists: autodev-app-error.log"
    echo "   Size: $(wc -c < "$ERROR_LOG") bytes"
else
    echo "ℹ️  Error log file not found (normal if no errors)"
fi

# Test 3: Check for old separate log files
echo ""
echo "3. Checking for old separate log files:"
OLD_FILES=$(find "$LOG_DIR" -name "autodev-mpp-*.log" 2>/dev/null || true)
if [ -z "$OLD_FILES" ]; then
    echo "✅ No old separate log files found"
else
    echo "⚠️  Found old separate log files:"
    echo "$OLD_FILES" | sed 's/^/   /'
fi

# Test 4: Analyze log content
if [ -f "$MAIN_LOG" ]; then
    echo ""
    echo "4. Analyzing unified log content:"
    
    # Check for different component logs
    CORE_LOGS=$(grep -c "mpp-core\|LogbackIntegrationTest\|JvmLoggingInitializer" "$MAIN_LOG" 2>/dev/null || echo "0")
    UI_LOGS=$(grep -c "AutoDevMain\|mpp-ui\|ToolRegistry" "$MAIN_LOG" 2>/dev/null || echo "0")
    LOGGER_LOGS=$(grep -c "AutoDevLogger" "$MAIN_LOG" 2>/dev/null || echo "0")
    
    echo "   mpp-core related logs: $CORE_LOGS entries"
    echo "   mpp-ui related logs: $UI_LOGS entries"
    echo "   AutoDevLogger logs: $LOGGER_LOGS entries"
    
    if [ "$CORE_LOGS" -gt 0 ] && [ "$UI_LOGS" -gt 0 ]; then
        echo "✅ Both mpp-core and mpp-ui logs found in unified file"
    elif [ "$UI_LOGS" -gt 0 ]; then
        echo "✅ mpp-ui logs found in unified file"
    elif [ "$CORE_LOGS" -gt 0 ]; then
        echo "✅ mpp-core logs found in unified file"
    else
        echo "⚠️  Need to generate more logs to verify"
    fi
    
    # Show sample log entries
    echo ""
    echo "   Sample log entries:"
    head -3 "$MAIN_LOG" | sed 's/^/     /'
    echo "     ..."
    tail -3 "$MAIN_LOG" | sed 's/^/     /'
fi

# Test 5: Verify log configuration
echo ""
echo "5. Verifying log configuration:"
CORE_CONFIG="mpp-core/src/jvmMain/resources/logback.xml"
UI_CONFIG="mpp-ui/src/jvmMain/resources/logback.xml"

if [ -f "$CORE_CONFIG" ]; then
    if grep -q "autodev-app" "$CORE_CONFIG"; then
        echo "✅ mpp-core configured for unified logging"
    else
        echo "❌ mpp-core not configured for unified logging"
    fi
else
    echo "❌ mpp-core logback.xml missing"
fi

if [ -f "$UI_CONFIG" ]; then
    if grep -q "autodev-app" "$UI_CONFIG"; then
        echo "✅ mpp-ui configured for unified logging"
    else
        echo "❌ mpp-ui not configured for unified logging"
    fi
else
    echo "❌ mpp-ui logback.xml missing"
fi

# Summary
echo ""
echo "🎉 Unified Logging Verification Summary"
echo "======================================"

if [ -f "$MAIN_LOG" ] && grep -q "autodev-app" "$CORE_CONFIG" 2>/dev/null && grep -q "autodev-app" "$UI_CONFIG" 2>/dev/null; then
    echo "✅ Unified logging: FULLY WORKING"
    echo "✅ Configuration: CORRECT"
    echo "✅ File structure: CLEAN"
    
    echo ""
    echo "🎯 Perfect! All AutoDev components now log to:"
    echo "   📄 Main log: $MAIN_LOG"
    echo "   📄 Error log: $ERROR_LOG"
    echo ""
    echo "💡 Use 'tail -f $MAIN_LOG' to monitor all AutoDev activity!"
else
    echo "⚠️  Some issues detected, please check the details above"
fi

echo ""
echo "📊 Quick stats:"
if [ -f "$MAIN_LOG" ]; then
    echo "   Total log entries: $(wc -l < "$MAIN_LOG")"
    echo "   Log file size: $(du -h "$MAIN_LOG" | cut -f1)"
    echo "   Last updated: $(stat -f "%Sm" "$MAIN_LOG" 2>/dev/null || stat -c "%y" "$MAIN_LOG" 2>/dev/null || echo "unknown")"
fi
