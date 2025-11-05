# 测试新的 TUI 模式切换功能

## 测试步骤

### 1. 构建项目
```bash
cd mpp-ui
npm run build:ts
```

### 2. 测试 CLI 帮助信息
```bash
node dist/index.js --help
node dist/index.js code --help
```

### 3. 测试 Agent 模式（非交互式）
```bash
# 创建一个测试目录
mkdir -p /tmp/test-autodev
cd /tmp/test-autodev

# 测试 Agent 模式
node /Volumes/source/ai/autocrud/mpp-ui/dist/index.js code \
  --path . \
  --task "Create a simple hello.txt file with 'Hello World' content" \
  --quiet
```

### 4. 测试交互式模式（需要真实终端）
```bash
# 在真实终端中运行
node dist/index.js
```

应该看到：
- 模式选择界面
- 可以选择 Chat 模式或 Agent 模式
- 支持键盘快捷键（1 for Chat, 2 for Agent）
- 支持 Esc 键返回模式选择

### 5. 测试 Agent 模式 TUI
在交互式模式中：
1. 选择 Agent 模式
2. 输入项目路径
3. 输入任务描述
4. 确认并执行

### 6. 测试模式切换
- 在 Chat 模式中按 Esc 返回模式选择
- 在 Agent 模式中按 Esc 返回模式选择

## 新增功能：Slash Command 模式切换

### 6. 测试 `/agent` 命令
在 Chat 模式中：
```bash
# 在交互式模式中输入
/help
# 应该看到 /agent 命令在帮助列表中

/agent
# 应该切换到 Agent 模式
```

### 7. 测试其他 slash 命令
```bash
/help    # 显示帮助（包含新的 /agent 命令）
/clear   # 清空聊天历史
/config  # 显示配置信息
/agent   # 切换到 Agent 模式
```

## 预期结果

1. **CLI 命令正常工作**：
   - `autodev --help` 显示帮助信息
   - `autodev code --help` 显示 Agent 模式帮助
   - 默认命令进入交互式模式

2. **模式选择界面**：
   - 显示两个选项：Chat 模式和 Agent 模式
   - 支持箭头键选择和回车确认
   - 支持数字快捷键（1, 2）

3. **Agent 模式 TUI**：
   - 逐步引导用户输入项目路径和任务
   - 显示执行进度和日志
   - 显示最终结果

4. **模式切换**：
   - 可以从任何模式返回到模式选择界面
   - 状态正确重置
   - 支持 `/agent` 命令从 Chat 模式切换到 Agent 模式

5. **Slash 命令功能**：
   - `/help` 显示更新的帮助信息（包含 `/agent` 命令）
   - `/agent` 命令可以从 Chat 模式切换到 Agent 模式
   - 所有原有命令正常工作

## 已知限制

1. 在非交互式终端中运行会出现 "Raw mode is not supported" 错误，这是正常的
2. 需要先配置 LLM 提供商才能使用 Agent 功能
3. Agent 模式需要有效的项目路径
