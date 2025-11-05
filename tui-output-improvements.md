# TUI 输出优化改进

## 问题分析

通过运行测试发现了 TUI 中的几个关键问题：

1. **工具输出过长** - list-files 和 read-file 输出了100-200行，完全淹没了屏幕
2. **没有输出限制** - 所有内容都完整显示，没有截断
3. **缺乏视觉分隔** - 不同工具调用之间没有清晰的分隔
4. **迭代头部重复** - 每次迭代都显示相同的头部信息
5. **冗余的 JSON 参数显示** - 工具调用参数以完整 JSON 格式显示

## 解决方案

### 1. 智能输出截断

- **默认限制**：工具输出限制为 20 行
- **智能摘要**：根据工具类型提供不同的摘要格式
- **剩余行数提示**：显示 "... (N more lines)" 提示

### 2. 工具特定格式化

#### list-files
```
✅ **list-files** found 100 files
```
file1.java
file2.java
...
... (80 more files)
```
```

#### read-file
```
✅ **read-file** (200 lines)
```
line 1 content
line 2 content
...
... (180 more lines)
```
```

#### shell
```
✅ **shell** completed
```
command output...
... (N more lines)
```
```

#### write-file
```
✅ **write-file** completed
```

### 3. 简化工具调用显示

**之前**：
```
🔧 **Calling tool**: `list-files`
```json
{"path": ".", "recursive": true}
```
```

**现在**：
```
🔧 **list-files** `.` (recursive)
```

### 4. 减少冗余信息

- **迭代头部**：默认隐藏，只在必要时显示
- **警告消息**：简化格式
- **最终结果**：只在多次迭代时显示迭代数

### 5. 环境变量配置

用户可以通过环境变量调整输出详细程度：

```bash
# 调整最大输出行数（默认 20）
export AUTODEV_MAX_OUTPUT_LINES=30

# 调整最大行长度（默认 120）
export AUTODEV_MAX_LINE_LENGTH=100

# 显示迭代头部（默认 false）
export AUTODEV_SHOW_ITERATIONS=true

# 详细模式 - 显示更多信息（默认 false）
export AUTODEV_VERBOSE=true
```

## 改进效果

### 屏幕空间节省
- **list-files**：从 100+ 行减少到 ~25 行
- **read-file**：从 200+ 行减少到 ~25 行
- **shell**：从 150+ 行减少到 ~25 行

### 信息密度提升
- 工具调用参数一行显示
- 结果摘要包含关键信息（文件数量、行数等）
- 减少重复和冗余信息

### 用户体验改善
- 更清晰的视觉层次
- 重要信息突出显示
- 可配置的详细程度

## 测试验证

通过 `docs/test-scripts/test-tool-output.mjs` 验证：

✅ 工具输出正确截断  
✅ 摘要信息准确显示  
✅ 视觉格式清晰易读  
✅ 配置选项正常工作  

## 技术实现

### 核心文件
- `mpp-ui/src/jsMain/typescript/agents/render/TuiRenderer.ts`

### 关键方法
- `formatToolParams()` - 格式化工具参数显示
- `formatToolResult()` - 智能格式化工具结果
- `truncateText()` - 文本截断处理

### 配置系统
- 环境变量驱动的配置
- 运行时可调整的输出详细程度
