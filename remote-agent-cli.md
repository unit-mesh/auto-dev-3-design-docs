# Remote Agent CLI - Kotlin 实现

基于 `RemoteAgentClient.kt` 的 Kotlin CLI 实现，功能与 TypeScript 版本一致。

## 快速开始

### 1. 查看帮助信息

```bash
./gradlew :mpp-ui:runRemoteAgentCli --args="--help"
```

### 2. 运行 CLI (使用服务器配置)

```bash
./gradlew :mpp-ui:runRemoteAgentCli --args="--server http://localhost:8080 --project-id autocrud --task '列出所有 Kotlin 文件' --use-server-config"
```

### 3. 使用客户端 LLM 配置

```bash
./gradlew :mpp-ui:runRemoteAgentCli --args="--server http://localhost:8080 --project-id autocrud --task '编写 BlogService 测试' --provider deepseek --model deepseek-chat --api-key sk-xxx"
```

### 4. 使用 Git URL (需要服务器支持)

```bash
./gradlew :mpp-ui:runRemoteAgentCli --args="--server http://localhost:8080 --project-id https://github.com/unit-mesh/untitled --task '编写测试' --use-server-config"
```

## 命令行参数

### 必需参数

- `-s, --server <URL>` - 服务器地址 (默认: http://localhost:8080)
- `-p, --project-id <ID>` - 项目 ID 或 Git URL
- `-t, --task <TASK>` - 开发任务描述

### 可选参数

**LLM 配置:**
- `--use-server-config` - 使用服务器端 LLM 配置
- `--provider <PROVIDER>` - LLM 提供商 (默认: deepseek)
- `--model <MODEL>` - 模型名称 (默认: deepseek-chat)
- `--api-key <KEY>` - API 密钥
- `--base-url <URL>` - LLM API 基础 URL

**Git 配置:**
- `--git-url <URL>` - Git 仓库 URL (用于自动克隆)
- `--branch <BRANCH>` - Git 分支 (默认: main)
- `--username <USER>` - Git 用户名 (私有仓库)
- `--password <PASS>` - Git 密码或 Token

**其他:**
- `-h, --help` - 显示帮助信息

## 输出示例

```
🔍 Connecting to server: http://localhost:8080
✅ Server is ok

🚀 AutoDev Remote Coding Agent
🌐 Server: http://localhost:8080
📦 Project: https://github.com/unit-mesh/untitled
📦 Provider: deepseek (from client)
🤖 Model: deepseek-chat

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Cloning repository...

[██████████████████████████████] 100% - Clone completed successfully
✓ Clone completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ Repository ready at: /tmp/autodev-clone-xxx/untitled

💭 I'll help you write tests for the BlogService. First, let me explore the project structure...

● read-file - file reader
  ⎿ Read 45 lines

● write-file - file editor
  ⎿ File operation completed

✅ Task completed successfully
Task completed after 3 iterations

📝 File Changes:
  ➕ src/test/kotlin/BlogServiceTest.kt
```

## 与 TypeScript 版本对比

| 特性 | TypeScript | Kotlin |
|------|-----------|--------|
| **运行环境** | Node.js | JVM |
| **启动方式** | `node dist/jsMain/typescript/index.js server` | `./gradlew :mpp-ui:runRemoteAgentCli` |
| **HTTP 客户端** | node-fetch | Ktor HttpClient |
| **异步模型** | AsyncGenerator | Kotlin Flow |
| **类型系统** | TypeScript | Kotlin (更强类型安全) |
| **代码复用** | 独立实现 | 复用 `RemoteAgentClient.kt` |

## 实现细节

### 核心组件

1. **RemoteAgentCli** - 主入口类
   - 命令行参数解析
   - 健康检查
   - 流式事件处理

2. **CliRenderer** - 事件渲染器
   - 克隆进度显示
   - LLM 输出流式显示
   - 工具调用格式化
   - 完成状态总结

3. **RemoteAgentClient** (复用 common 模块)
   - HTTP/SSE 通信
   - 事件流解析
   - 跨平台支持

### 关键特性

- ✅ 实时流式输出 (SSE)
- ✅ 进度条显示
- ✅ ANSI 颜色支持
- ✅ Git 自动克隆
- ✅ 错误处理
- ✅ 类型安全

## 测试

使用提供的测试脚本:

```bash
chmod +x docs/test-scripts/test-remote-agent-cli.sh
./docs/test-scripts/test-remote-agent-cli.sh
```

或手动测试:

```bash
# 1. 启动 mpp-server
cd mpp-server
./gradlew bootRun

# 2. 在另一个终端运行 CLI
./gradlew :mpp-ui:runRemoteAgentCli --args="--server http://localhost:8080 --project-id autocrud --task '编写测试'"
```

## 开发说明

### 文件位置

- **CLI 实现**: `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/cli/RemoteAgentCli.kt`
- **共享客户端**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/remote/RemoteAgentClient.kt`
- **Gradle 任务**: `mpp-ui/build.gradle.kts` (runRemoteAgentCli)

### 扩展建议

1. **配置文件支持** - 集成 `ConfigManager` 读取 `~/.autodev/config.yaml`
2. **更好的参数解析** - 使用 kotlinx-cli 或 clikt 库
3. **交互模式** - 支持用户输入和确认
4. **Native 编译** - 使用 GraalVM 生成独立可执行文件
5. **单元测试** - 为 CliRenderer 添加测试

## 常见问题

**Q: 如何指定自定义 LLM 配置?**

A: 使用 `--provider`, `--model`, `--api-key` 参数，或使用 `--use-server-config` 让服务器端处理。

**Q: 如何克隆私有仓库?**

A: 使用 `--username` 和 `--password` 参数提供认证信息。

**Q: 输出乱码怎么办?**

A: 确保终端支持 UTF-8 和 ANSI 转义码。

**Q: 如何调试?**

A: 查看日志文件 `~/.autodev/logs/autodev-app.log`

