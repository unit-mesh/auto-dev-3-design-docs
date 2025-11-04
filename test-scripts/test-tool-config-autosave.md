# ToolConfigDialog 自动保存功能测试指南

## 问题描述

之前的 `ToolConfigDialog` 中，用户勾选工具后配置没有保存，只有点击 "Save" 按钮才会保存配置。这导致用户可能以为配置已经生效，但实际上没有保存到文件中。

## 修复方案

添加了**自动保存功能**，具有以下特性：

### 1. 延迟自动保存
- 用户勾选工具后，会在 **2 秒后自动保存**
- 如果用户在 2 秒内继续勾选其他工具，会重置计时器
- 这样避免了频繁的文件 I/O 操作

### 2. 可视化反馈
- **标题栏指示器**：显示 "Auto-saving..." 状态
- **底部状态文本**：显示保存状态和倒计时
- **实时更新**：用户可以看到配置的保存状态

### 3. 改进的用户体验
- 保存按钮改为 "Apply & Close"
- 自动取消待处理的保存任务
- 对话框关闭时清理资源

## 修复的关键代码

### 1. 自动保存逻辑

```kotlin
// Auto-save function with debouncing
fun scheduleAutoSave() {
    hasUnsavedChanges = true
    autoSaveJob?.cancel()
    autoSaveJob = scope.launch {
        kotlinx.coroutines.delay(2000) // Wait 2 seconds before auto-saving
        try {
            val enabledBuiltinTools = builtinToolsByCategory.values
                .flatten()
                .filter { it.enabled }
                .map { it.name }

            val enabledMcpTools = mcpTools.values
                .flatten()
                .filter { it.enabled }
                .map { it.name }

            // Parse MCP config from JSON
            val result = deserializeMcpConfig(mcpConfigJson)
            if (result.isSuccess) {
                val newMcpServers = result.getOrThrow()
                val updatedConfig = toolConfig.copy(
                    enabledBuiltinTools = enabledBuiltinTools,
                    enabledMcpTools = enabledMcpTools,
                    mcpServers = newMcpServers
                )

                ConfigManager.saveToolConfig(updatedConfig)
                toolConfig = updatedConfig
                hasUnsavedChanges = false
                println("✅ Auto-saved tool configuration")
            }
        } catch (e: Exception) {
            println("❌ Auto-save failed: ${e.message}")
        }
    }
}
```

### 2. 工具切换回调

```kotlin
onBuiltinToolToggle = { category, toolName, enabled ->
    builtinToolsByCategory = builtinToolsByCategory.mapValues { (cat, toolsList) ->
        if (cat == category) {
            toolsList.map {
                if (it.name == toolName) it.copy(enabled = enabled) else it
            }
        } else toolsList
    }
    scheduleAutoSave() // 触发自动保存
},
```

### 3. 状态指示器

```kotlin
// Unsaved changes indicator
if (hasUnsavedChanges) {
    Surface(
        color = MaterialTheme.colorScheme.primaryContainer,
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                Icons.Default.Schedule,
                contentDescription = "Auto-saving",
                modifier = Modifier.size(14.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "Auto-saving...",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}
```

## 测试步骤

### 1. 基本自动保存测试
1. 打开工具配置对话框
2. 勾选或取消勾选任意工具
3. 观察标题栏出现 "Auto-saving..." 指示器
4. 观察底部状态文本显示 "Changes will be auto-saved in 2 seconds..."
5. 等待 2 秒，观察状态变为 "All changes saved"
6. 关闭对话框并重新打开，验证配置已保存

### 2. 防抖动测试
1. 快速连续勾选多个工具
2. 观察每次勾选都会重置 2 秒计时器
3. 停止操作后等待 2 秒，验证只保存一次

### 3. 错误处理测试
1. 在 MCP 配置中输入无效的 JSON
2. 勾选工具，观察自动保存是否会跳过无效配置
3. 修复 JSON 后再次测试自动保存

### 4. 资源清理测试
1. 勾选工具触发自动保存
2. 在 2 秒内关闭对话框
3. 验证没有内存泄漏或后台任务继续运行

## 预期效果

### 用户体验改进
- ✅ 用户勾选工具后无需手动点击保存
- ✅ 清晰的视觉反馈显示保存状态
- ✅ 防止意外丢失配置更改
- ✅ 减少用户操作步骤

### 技术改进
- ✅ 防抖动机制避免频繁 I/O
- ✅ 自动资源清理防止内存泄漏
- ✅ 错误处理确保稳定性
- ✅ 保持向后兼容性

## 相关文件

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/config/ToolConfigDialog.kt`

这个修复解决了工具配置不保存的问题，提供了更好的用户体验和可靠的自动保存机制。
