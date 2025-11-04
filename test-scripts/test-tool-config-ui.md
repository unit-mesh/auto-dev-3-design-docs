# Tool Configuration UI 测试指南

## 测试内容

### 1. 紧凑布局测试
- ✅ 工具之间的间距已从 16dp 减少到 8dp
- 工具列表现在更紧凑，更易于浏览

### 2. MCP JSON 配置测试

#### 正确的 JSON 格式

在 "MCP Servers" 标签页中，输入以下格式的 JSON：

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
    "env": {}
  },
  "github": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_TOKEN": "your-token-here"
    }
  }
}
```

#### 错误处理测试

1. **无效的 JSON**：
   - 输入：`{ invalid json }`
   - 预期：显示红色错误框 "Failed to parse JSON: ..."

2. **缺少必要字段**：
   - 输入：`{ "test": {} }`
   - 预期：显示错误 "Invalid config for server 'test': must have either 'command' or 'url'"

3. **空 JSON**：
   - 输入：`{}`
   - 预期：成功保存，清空所有 MCP 服务器

#### 工作流程

1. 打开 Tool Configuration 对话框
2. 切换到 "MCP Servers" 标签页
3. 编辑 JSON 配置
4. 点击 "Reload Tools" 按钮
5. 如果 JSON 有效：
   - ✅ 成功加载，控制台输出 "✅ Reloaded MCP tools from N servers"
   - 切换到 "Tools" 标签页可以看到 MCP Tools 区域
6. 如果 JSON 无效：
   - ❌ 显示错误消息
   - 错误框显示在 JSON 编辑器上方
   - JSON 输入框显示红色边框

#### 验证序列化

运行以下命令验证配置文件格式：

```bash
cat ~/.autodev/mcp.json
```

期望看到：
```json
{
  "enabledBuiltinTools": [...],
  "enabledMcpTools": [...],
  "mcpServers": {
    "filesystem": { ... },
    "github": { ... }
  },
  "chatConfig": { ... }
}
```

## 已修复的问题

1. ✅ 工具之间间距过大 → 改为 8dp
2. ✅ JSON 序列化/反序列化 → 添加 Result<> 返回类型和完整错误处理
3. ✅ Reload 没有校验 → 添加配置验证和错误提示
4. ✅ 看不到 MCP 工具 → 成功 Reload 后会自动发现并显示工具


