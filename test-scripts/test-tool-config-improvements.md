# Tool Config Dialog Improvements - Test Script

## 改进内容

### 1. 布局优化 - 更加紧凑
- 对话框尺寸从 900x700 减小到 850x650
- 减少了各处的 padding 和 spacer 间距
- 图标大小从 24dp 减小到 20dp
- 优化了文本间距和组件间距

### 2. MCP Server 自动加载工具
- ✅ 在打开对话框时，如果配置了 MCP servers，会自动加载所有工具
- ✅ 如果加载失败，会显示红色错误提示框
- ✅ 添加了 `mcpLoadError` 状态来跟踪加载错误

### 3. JSON 实时校验
- ✅ 在 `onMcpConfigChange` 中实时校验 JSON 格式
- ✅ 实时显示错误信息
- ✅ 只有 JSON 有效时，"Save & Reload" 按钮才可点击
- ✅ 加载时禁用文本编辑框

### 4. 配置管理集成
- ✅ 打开时从 `ConfigManager.loadToolConfig()` 加载配置
- ✅ Reload 时先校验 JSON
- ✅ 校验通过后调用 `ConfigManager.saveToolConfig()` 保存配置
- ✅ 然后再加载 MCP 工具
- ✅ 添加了 `isReloading` 状态显示加载进度

### 5. 改进的 UI 反馈
- ✅ "Save & Reload" 按钮在加载时显示 spinner 和 "Loading..." 文字
- ✅ 按钮在 JSON 错误或正在加载时禁用
- ✅ TextField 在加载时禁用
- ✅ 统一的错误提示样式

## 测试步骤

### 测试 1: 自动加载 MCP 工具
1. 打开 Tool Configuration 对话框
2. 切换到 "MCP Servers" 标签
3. 配置有效的 MCP 服务器 JSON
4. 预期：应该看到工具自动加载

### 测试 2: JSON 实时校验
1. 打开 Tool Configuration 对话框
2. 切换到 "MCP Servers" 标签
3. 输入无效的 JSON（例如缺少引号）
4. 预期：立即看到红色错误提示
5. 修复 JSON 错误
6. 预期：错误提示消失，按钮可点击

### 测试 3: 配置保存和重新加载
1. 打开 Tool Configuration 对话框
2. 切换到 "MCP Servers" 标签
3. 编辑 MCP 配置
4. 点击 "Save & Reload"
5. 预期：
   - 按钮显示 "Loading..." 和 spinner
   - 配置保存到 ~/.autodev/mcp.json
   - MCP 工具重新加载
   - 加载完成后按钮恢复正常

### 测试 4: 错误处理
1. 打开 Tool Configuration 对话框
2. 配置一个无效的 MCP 服务器（例如错误的命令）
3. 点击 "Save & Reload"
4. 预期：显示红色错误提示，说明加载失败

### 测试 5: 紧凑布局
1. 打开 Tool Configuration 对话框
2. 检查布局
3. 预期：
   - 对话框大小适中（850x650）
   - 各元素间距紧凑但不拥挤
   - 工具列表可以显示更多内容

## 构建测试

```bash
# 1. Build MPP Core
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:assembleJsPackage

# 2. Build MPP UI
cd mpp-ui
npm run build:ts

# 3. Run (if needed)
node dist/index.js
```

## 代码改进总结

### 新增状态变量
- `mcpLoadError: String?` - MCP 工具加载错误
- `isReloading: Boolean` - 重新加载状态

### 关键逻辑改进

#### 1. 自动加载 MCP 工具（初始化时）
```kotlin
// Auto-load MCP tools if any servers are configured
if (toolConfig.mcpServers.isNotEmpty()) {
    try {
        mcpTools = ToolConfigManager.discoverMcpTools(
            toolConfig.mcpServers,
            toolConfig.enabledMcpTools.toSet()
        )
        mcpLoadError = null
    } catch (e: Exception) {
        mcpLoadError = "Failed to load MCP tools: ${e.message}"
    }
}
```

#### 2. JSON 实时校验
```kotlin
onMcpConfigChange = { newJson ->
    mcpConfigJson = newJson
    // Real-time JSON validation
    val result = deserializeMcpConfig(newJson)
    mcpConfigError = if (result.isFailure) {
        result.exceptionOrNull()?.message
    } else {
        null
    }
}
```

#### 3. Reload 时保存配置
```kotlin
// Validate JSON first
val result = deserializeMcpConfig(mcpConfigJson)
if (result.isFailure) {
    mcpConfigError = result.exceptionOrNull()?.message ?: "Invalid JSON format"
    return@launch
}

val newMcpServers = result.getOrThrow()

// Save configuration to ConfigManager
val updatedConfig = toolConfig.copy(mcpServers = newMcpServers)
ConfigManager.saveToolConfig(updatedConfig)
toolConfig = updatedConfig

// Discover MCP tools
try {
    mcpTools = ToolConfigManager.discoverMcpTools(...)
} catch (e: Exception) {
    mcpLoadError = "Failed to load MCP tools: ${e.message}"
}
```

## 测试结果

✅ Build successful for mpp-core
✅ Build successful for mpp-ui  
✅ No linter errors

## 注意事项

1. MCP 服务器需要正确配置才能加载工具
2. JSON 校验是实时的，提供即时反馈
3. 配置会立即保存到 ConfigManager
4. 错误信息会清晰地显示给用户

