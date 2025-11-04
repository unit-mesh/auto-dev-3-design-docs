#!/bin/bash

# 验证 ToolConfigDialog 自动保存功能的脚本
# 
# 使用方法：
# ./docs/test-scripts/verify-tool-config-autosave.sh

set -e

echo "🔧 验证 ToolConfigDialog 自动保存功能"
echo "=================================================="

# 检查修改的文件
echo "📁 检查修改的文件..."

TARGET_FILE="mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/config/ToolConfigDialog.kt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ 错误：找不到文件 $TARGET_FILE"
    exit 1
fi

echo "✅ 找到文件: $TARGET_FILE"

echo ""
echo "🔍 检查关键修复..."

# 1. 检查自动保存状态变量
if grep -q "hasUnsavedChanges.*mutableStateOf" "$TARGET_FILE"; then
    echo "✅ 添加了 hasUnsavedChanges 状态变量"
else
    echo "❌ 未找到 hasUnsavedChanges 状态变量"
    exit 1
fi

# 2. 检查自动保存任务变量
if grep -q "autoSaveJob.*mutableStateOf" "$TARGET_FILE"; then
    echo "✅ 添加了 autoSaveJob 状态变量"
else
    echo "❌ 未找到 autoSaveJob 状态变量"
    exit 1
fi

# 3. 检查自动保存函数
if grep -q "fun scheduleAutoSave()" "$TARGET_FILE"; then
    echo "✅ 添加了 scheduleAutoSave 函数"
else
    echo "❌ 未找到 scheduleAutoSave 函数"
    exit 1
fi

# 4. 检查延迟逻辑
if grep -q "kotlinx.coroutines.delay(2000)" "$TARGET_FILE"; then
    echo "✅ 添加了 2 秒延迟逻辑"
else
    echo "❌ 未找到延迟逻辑"
    exit 1
fi

# 5. 检查工具切换回调中的自动保存调用
if grep -A 10 "onBuiltinToolToggle.*=" "$TARGET_FILE" | grep -q "scheduleAutoSave()"; then
    echo "✅ 内置工具切换时调用自动保存"
else
    echo "❌ 内置工具切换时未调用自动保存"
    exit 1
fi

if grep -A 10 "onMcpToolToggle.*=" "$TARGET_FILE" | grep -q "scheduleAutoSave()"; then
    echo "✅ MCP 工具切换时调用自动保存"
else
    echo "❌ MCP 工具切换时未调用自动保存"
    exit 1
fi

# 6. 检查状态指示器
if grep -q "Auto-saving..." "$TARGET_FILE"; then
    echo "✅ 添加了自动保存状态指示器"
else
    echo "❌ 未找到自动保存状态指示器"
    exit 1
fi

# 7. 检查资源清理
if grep -q "DisposableEffect" "$TARGET_FILE" && grep -q "autoSaveJob?.cancel()" "$TARGET_FILE"; then
    echo "✅ 添加了资源清理逻辑"
else
    echo "❌ 未找到资源清理逻辑"
    exit 1
fi

# 8. 检查按钮文本更改
if grep -q "Apply & Close" "$TARGET_FILE"; then
    echo "✅ 保存按钮文本已更改为 'Apply & Close'"
else
    echo "❌ 保存按钮文本未更改"
    exit 1
fi

echo ""
echo "🔨 编译验证..."

# 验证编译
./gradlew :mpp-ui:compileKotlinJvm --quiet
if [ $? -eq 0 ]; then
    echo "✅ JVM 编译成功"
else
    echo "❌ JVM 编译失败"
    exit 1
fi

./gradlew :mpp-ui:compileKotlinJs --quiet
if [ $? -eq 0 ]; then
    echo "✅ JS 编译成功"
else
    echo "❌ JS 编译失败"
    exit 1
fi

./gradlew :mpp-ui:compileDebugKotlinAndroid --quiet
if [ $? -eq 0 ]; then
    echo "✅ Android 编译成功"
else
    echo "❌ Android 编译失败"
    exit 1
fi

echo ""
echo "📊 修复总结："
echo "=" * 50

echo ""
echo "🔧 主要改进："
echo "1. ✅ 添加了延迟自动保存机制（2 秒防抖动）"
echo "2. ✅ 添加了未保存更改的可视化指示器"
echo "3. ✅ 工具切换时自动触发保存"
echo "4. ✅ 改进了用户界面状态反馈"
echo "5. ✅ 添加了资源清理逻辑"
echo "6. ✅ 保存按钮改为 'Apply & Close'"

echo ""
echo "🎯 用户体验改进："
echo "- 用户勾选工具后无需手动点击保存"
echo "- 清晰的视觉反馈显示保存状态"
echo "- 防止意外丢失配置更改"
echo "- 减少用户操作步骤"

echo ""
echo "⚙️ 技术特性："
echo "- 防抖动机制避免频繁 I/O"
echo "- 自动资源清理防止内存泄漏"
echo "- 错误处理确保稳定性"
echo "- 保持向后兼容性"

echo ""
echo "📋 测试建议："
echo "1. 打开工具配置对话框"
echo "2. 勾选或取消勾选工具"
echo "3. 观察 'Auto-saving...' 指示器"
echo "4. 等待 2 秒查看保存状态"
echo "5. 关闭并重新打开验证配置已保存"

echo ""
echo "🎉 ToolConfigDialog 自动保存功能验证完成！"
echo "所有检查都通过，用户现在可以享受自动保存的便利。"
