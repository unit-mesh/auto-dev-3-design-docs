# TUI 模式切换功能实现

## 概述

成功实现了 TUI 中的模式切换功能，现在 TUI 默认使用 AI Agent 模式，并支持通过 slash 命令切换到聊天模式。

## 架构设计

### 1. 模式接口 (`Mode.ts`)
- `Mode` 接口：定义统一的模式接口
- `ModeContext` 接口：模式执行上下文
- `ModeFactory` 接口：模式工厂接口

### 2. 模式管理器 (`ModeManager.ts`)
- 管理模式注册和切换
- 支持模式切换事件监听
- 提供模式状态查询

### 3. 具体模式实现

#### Agent 模式 (`AgentMode.ts`)
- 集成现有的 CodingAgent 逻辑
- 类似于 CLI 中的 `runCodingAgent`
- 用户输入被视为开发任务，由 AI 代理自主完成
- 使用 `TuiRenderer` 适配 TUI 环境

#### Chat 模式 (`ChatMode.ts`)
- 封装现有的聊天逻辑
- 支持与 LLM 的对话交互
- 包含 DevIns 命令编译和处理器路由

### 4. 模式切换命令 (`ModeCommandProcessor.ts`)
- 处理 `/chat`、`/agent`、`/mode` 等命令
- 高优先级处理器，在其他处理器之前执行

### 5. TUI 渲染器 (`TuiRenderer.ts`)
- 实现 `JsCodingAgentRenderer` 接口
- 适配 CodingAgent 的渲染需求到 TUI 环境
- 支持迭代显示、工具调用、错误处理等

## 使用方式

### 默认模式
- TUI 启动时默认进入 **AI Agent 模式**
- 显示欢迎消息和当前模式状态

### 模式切换命令
- `/chat` - 切换到聊天模式
- `/agent` - 切换到代理模式  
- `/mode` - 显示当前模式和可用模式信息
- `/mode <type>` - 切换到指定模式

### 界面显示
- 头部显示当前模式图标、名称和状态
- 模式切换时显示确认消息

## 测试结果

通过 `docs/test-scripts/test-mode-switching.mjs` 测试验证：

✅ 模式注册成功  
✅ Agent 模式初始化成功  
✅ Chat 模式初始化成功  
✅ 模式切换功能正常  
✅ 无效模式处理正确  
✅ 资源清理正常  

## 技术细节

### 依赖关系
- Agent 模式依赖 `@autodev/mpp-core` 的 `JsCodingAgent`
- Chat 模式依赖现有的 `LLMService` 和处理器系统
- 渲染器实现 Kotlin/JS 导出的 `JsCodingAgentRenderer` 接口

### 构建输出
- 编译后的文件位于 `mpp-ui/dist/jsMain/typescript/modes/`
- 支持 ES 模块导入

### 兼容性
- 保持与现有 CLI 功能的一致性
- 支持所有现有的 DevIns 命令和处理器
- 向后兼容现有配置系统

## 未来扩展

架构设计支持轻松添加新的交互模式：
1. 实现 `Mode` 接口
2. 创建对应的 `ModeFactory`
3. 在 `ModeManager` 中注册
4. 添加相应的切换命令

例如：可以添加 Debug 模式、Review 模式等。
