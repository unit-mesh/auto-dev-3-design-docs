# CLI Server Mode 使用指南

## 问题修复

### ❌ 原问题
客户端和服务器端 API 不一致：
- **客户端**: 使用 POST + JSON body
- **服务器端**: 使用 GET + 查询参数

### ✅ 解决方案
服务器端现在同时支持两种方式：
1. **POST + JSON body** (推荐，客户端使用)
2. **GET + 查询参数** (向后兼容)

## Server Mode vs Code Mode

### Code Mode (本地模式)
```bash
node dist/jsMain/typescript/index.js code \
  --task "你的任务" \
  -p /path/to/project \
  --max-iterations 100
```

**特点:**
- ✅ 直接在本地运行 Agent
- ✅ 完全控制（MCP servers, tools, configs）
- ✅ 无需网络连接
- ❌ 需要本地有项目代码
- ❌ 需要本地安装所有依赖

### Server Mode (远程模式)
```bash
node dist/jsMain/typescript/index.js server \
  --task "你的任务" \
  --project-id <project-id> \
  -s http://localhost:8080
```

**特点:**
- ✅ 连接到远程 mpp-server
- ✅ 可以自动 clone Git 仓库
- ✅ 服务器端管理资源和配置
- ✅ 多用户共享服务器
- ❌ 需要网络连接
- ❌ 依赖服务器配置的项目

## Server Mode 使用方式

### 方式 1: 使用服务器上已配置的项目

```bash
# 1. 查看可用项目
curl http://localhost:8080/api/projects | jq

# 输出示例:
# {
#   "projects": [
#     {"id": ".vim_runtime", "name": ".vim_runtime", "path": "/Users/phodal/.vim_runtime"},
#     {"id": ".oh-my-zsh", "name": ".oh-my-zsh", "path": "/Users/phodal/.oh-my-zsh"}
#   ]
# }

# 2. 使用 CLI 执行任务
node dist/jsMain/typescript/index.js server \
  --task "分析项目结构" \
  --project-id .vim_runtime \
  -s http://localhost:8080
```

### 方式 2: 使用 Git URL（自动 clone）

**⚠️ 注意**: 目前 CLI 客户端还不支持传递 `gitUrl` 参数，需要修改客户端代码。

直接使用 curl 测试：

```bash
# 公开仓库
curl -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "projectId": "test-project",
    "task": "分析代码结构",
    "gitUrl": "https://github.com/unit-mesh/auto-dev",
    "branch": "master"
  }'

# 私有仓库
curl -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "projectId": "private-project",
    "task": "代码审查",
    "gitUrl": "https://github.com/user/private-repo",
    "branch": "main",
    "username": "your-username",
    "password": "your-token"
  }'
```

## 命令行参数对比

### Code Mode 参数
```bash
-p, --path <path>              # ✅ 项目本地路径
-t, --task <task>              # 任务描述
-m, --max-iterations <number>  # 最大迭代次数
-q, --quiet                    # 安静模式
-v, --verbose                  # 详细模式
```

### Server Mode 参数
```bash
--project-id <projectId>       # ✅ 服务器上的项目ID（不是路径！）
-t, --task <task>              # 任务描述
-s, --server-url <url>         # 服务器地址（默认 http://localhost:8080）
-q, --quiet                    # 安静模式
--use-server-config            # 使用服务器的 LLM 配置
```

## ❌ 常见错误

### 错误 1: 使用路径而不是 projectId

```bash
# ❌ 错误示例
node dist/jsMain/typescript/index.js server \
  --task "任务" \
  -p /Users/phodal/IdeaProjects  # 错误：这是路径

# ✅ 正确示例
node dist/jsMain/typescript/index.js server \
  --task "任务" \
  --project-id my-project  # 正确：这是 projectId
```

### 错误 2: 项目未在服务器上配置

```bash
# 检查可用项目
curl http://localhost:8080/api/projects

# 如果项目不存在，会报错: "Project not found"
```

**解决方案:**
1. 在服务器的 `~/.autodev/projects.yaml` 中配置项目
2. 或者使用 Git URL 自动 clone

### 错误 3: Server 未运行

```bash
# ❌ 错误信息
❌ Server health check failed: fetch failed
Please make sure mpp-server is running.

# ✅ 启动服务器
cd /Volumes/source/ai/autocrud
./gradlew :mpp-server:run
```

## API 对比

### POST API (客户端使用)

**请求:**
```http
POST /api/agent/stream
Content-Type: application/json
Accept: text/event-stream

{
  "projectId": "test-project",
  "task": "任务描述",
  "gitUrl": "https://github.com/user/repo", // 可选
  "branch": "main",                          // 可选
  "username": "user",                        // 可选
  "password": "token"                        // 可选
}
```

**响应:** SSE 事件流

### GET API (向后兼容)

**请求:**
```http
GET /api/agent/stream?projectId=test&task=任务&gitUrl=...&branch=...
Accept: text/event-stream
```

**响应:** SSE 事件流

## 完整测试示例

### 1. 启动服务器

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-server:run

# 等待输出
# > Task :mpp-server:run
# INFO: [CodingAgent] Server is running at http://0.0.0.0:8080
```

### 2. 测试健康检查

```bash
curl http://localhost:8080/health
# {"status":"ok","version":"1.0.0"}
```

### 3. 使用 CLI 执行任务

```bash
cd mpp-ui

# 方式 A: 使用已配置的项目
node dist/jsMain/typescript/index.js server \
  --task "列出项目的主要文件" \
  --project-id .vim_runtime \
  -s http://localhost:8080

# 方式 B: 使用服务器配置（不传递本地 LLM config）
node dist/jsMain/typescript/index.js server \
  --task "分析代码" \
  --project-id .vim_runtime \
  -s http://localhost:8080 \
  --use-server-config
```

### 4. 查看实时输出

```bash
🔍 Connecting to server: http://localhost:8080
✅ Server is ok

🚀 AutoDev Remote Coding Agent
🌐 Server: http://localhost:8080
📦 Project: .vim_runtime
📦 Provider: DEEPSEEK (from client)
🤖 Model: deepseek-chat

[Iteration 1/20]
💭 I'll analyze the project structure...

[Tool: glob]
🔧 Searching for files...
...

✅ Task completed successfully!
```

## 事件类型

Server Mode 接收的 SSE 事件：

| 事件类型 | 说明 |
|---------|------|
| `iteration` | 迭代开始 |
| `llm_chunk` | LLM 流式输出 |
| `tool_call` | 工具调用 |
| `tool_result` | 工具结果 |
| `clone_log` | Git clone 日志 |
| `clone_progress` | Clone 进度 |
| `error` | 错误 |
| `complete` | 任务完成 |

## 配置优先级

### LLM 配置来源优先级

1. **Client 配置** (默认)
   - 从客户端的 `~/.autodev/config.yaml` 读取
   - 在请求中传递给服务器

2. **Server 配置** (使用 `--use-server-config`)
   - 从服务器的 `~/.autodev/config.yaml` 读取
   - 不传递客户端配置

3. **环境变量** (fallback)
   - 服务器的环境变量

### 项目路径来源

- **Code Mode**: 使用 `-p` 指定的本地路径
- **Server Mode**: 
  - 从服务器配置的项目读取路径
  - 或者通过 `gitUrl` 自动 clone

## TODO: CLI 增强

为了完全支持 Git Clone 功能，需要在 CLI 客户端添加参数：

```typescript
// index.tsx - server command 需要添加
program
  .command('server')
  .description('Connect to remote mpp-server and execute coding agent task')
  .requiredOption('--project-id <projectId>', 'Project ID on the server')
  .requiredOption('-t, --task <task>', 'Development task')
  .option('-s, --server-url <url>', 'Server URL', 'http://localhost:8080')
  .option('--git-url <url>', 'Git repository URL (auto clone)')     // 新增
  .option('--branch <branch>', 'Git branch', 'main')                 // 新增
  .option('--username <username>', 'Git username for private repos') // 新增
  .option('--password <password>', 'Git password or token')          // 新增
  .option('-q, --quiet', 'Quiet mode', false)
  .option('--use-server-config', 'Use server\'s LLM config', false)
  .action(async (options) => {
    await runServerAgent(
      options.serverUrl,
      options.projectId,
      options.task,
      options.quiet,
      options.useServerConfig,
      options.gitUrl,      // 传递
      options.branch,      // 传递
      options.username,    // 传递
      options.password     // 传递
    );
  });
```

## 总结

### ✅ 已修复
- POST API 支持（客户端兼容）
- GET API 支持（向后兼容）
- 完整的 SSE 事件流
- Git Clone 日志实时输出

### 🎯 关键区别
- **Code Mode**: `-p` = 本地路径
- **Server Mode**: `--project-id` = 服务器项目 ID（不是路径！）

### 📝 使用建议
1. 本地开发 → 使用 **Code Mode**
2. 团队协作/远程执行 → 使用 **Server Mode**
3. 需要自动 clone → 直接使用 curl + POST API（CLI 需增强）

