#!/bin/bash

# WASM 依赖修复验证脚本
# 用于验证 Kotlin/Wasm 依赖版本问题已解决

set -e

echo "========================================="
echo "Kotlin/Wasm 依赖修复验证"
echo "========================================="
echo ""

echo "1. 清理构建缓存..."
./gradlew :mpp-core:clean :mpp-ui:clean > /dev/null 2>&1
echo "✅ 清理完成"
echo ""

echo "2. 检查 mpp-core kotlin-stdlib 版本..."
CORE_STDLIB=$(./gradlew :mpp-core:dependencies --configuration wasmJsRuntimeClasspath 2>/dev/null | grep "kotlin-stdlib-wasm-js" | head -1)
if echo "$CORE_STDLIB" | grep -q "2.2.0"; then
    echo "✅ mpp-core: kotlin-stdlib-wasm-js 版本正确 (2.2.0)"
else
    echo "❌ mpp-core: kotlin-stdlib 版本不正确"
    echo "$CORE_STDLIB"
    exit 1
fi
echo ""

echo "3. 检查 mpp-ui kotlin-stdlib 版本..."
UI_STDLIB=$(./gradlew :mpp-ui:dependencies --configuration wasmJsRuntimeClasspath 2>/dev/null | grep "kotlin-stdlib-wasm-js" | head -1)
if echo "$UI_STDLIB" | grep -q "2.2.0"; then
    echo "✅ mpp-ui: kotlin-stdlib-wasm-js 版本正确 (2.2.0)"
else
    echo "❌ mpp-ui: kotlin-stdlib 版本不正确"
    echo "$UI_STDLIB"
    exit 1
fi
echo ""

echo "4. 编译 mpp-core WasmJs..."
if ./gradlew :mpp-core:compileKotlinWasmJs > /tmp/core-compile.log 2>&1; then
    if grep -q "version.*differs" /tmp/core-compile.log; then
        echo "❌ 编译成功但有版本警告"
        grep "version.*differs" /tmp/core-compile.log
        exit 1
    else
        echo "✅ mpp-core WasmJs 编译成功，无版本警告"
    fi
else
    echo "❌ mpp-core 编译失败"
    tail -20 /tmp/core-compile.log
    exit 1
fi
echo ""

echo "5. 编译 mpp-ui WasmJs..."
if ./gradlew :mpp-ui:compileKotlinWasmJs > /tmp/ui-compile.log 2>&1; then
    if grep -q "version.*differs" /tmp/ui-compile.log; then
        echo "❌ 编译成功但有版本警告"
        grep "version.*differs" /tmp/ui-compile.log
        exit 1
    else
        echo "✅ mpp-ui WasmJs 编译成功，无版本警告"
    fi
else
    echo "❌ mpp-ui 编译失败"
    tail -20 /tmp/ui-compile.log
    exit 1
fi
echo ""

echo "6. 编译 mpp-core 测试代码..."
if ./gradlew :mpp-core:compileTestKotlinWasmJs > /tmp/test-compile.log 2>&1; then
    echo "✅ 测试代码编译成功"
else
    echo "❌ 测试代码编译失败"
    tail -20 /tmp/test-compile.log
    exit 1
fi
echo ""

echo "7. 编译生产版本 (优化已禁用)..."
if ./gradlew :mpp-ui:compileProductionExecutableKotlinWasmJs > /tmp/prod-compile.log 2>&1; then
    if grep -q "compileProductionExecutableKotlinWasmJsOptimize SKIPPED" /tmp/prod-compile.log; then
        echo "✅ 生产构建成功，优化步骤已跳过（按预期）"
    else
        echo "⚠️  生产构建成功，但优化步骤未跳过（可能有问题）"
    fi
else
    echo "❌ 生产构建失败"
    tail -20 /tmp/prod-compile.log
    exit 1
fi
echo ""

echo "========================================="
echo "✅ 所有验证通过！"
echo "========================================="
echo ""
echo "修复总结:"
echo "- kotlin-stdlib 版本已固定为 2.2.0"
echo "- 无版本不匹配警告"
echo "- WasmJs 编译成功"
echo "- 测试代码编译成功"
echo "- 生产构建成功（优化已禁用）"
echo ""
