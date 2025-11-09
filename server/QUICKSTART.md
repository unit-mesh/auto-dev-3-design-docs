# MPP-Server Quick Start Guide

## 🚀 快速开始（5分钟）

### 前置要求

- JDK 17 或更高版本
- Gradle 8.x（项目自带 wrapper）
- OpenAI API Key（或其他 LLM 提供商的 API Key）

### 步骤 1: 设置环境变量

```bash
# 必需：设置 LLM API Key
export LLM_API_KEY="sk-your-openai-api-key"

# 可选：自定义配置
export SERVER_PORT=8080
export PROJECTS_ROOT="$HOME/projects"
export LLM_PROVIDER="openai"
export LLM_MODEL="gpt-4"
```

### 步骤 2: 构建项目

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-server:build
```

### 步骤 3: 启动服务器

**方式 1: 使用启动脚本**
```bash
./mpp-server/scripts/start.sh
```

**方式 2: 使用 Gradle**
```bash
./gradlew :mpp-server:run
```

**方式 3: 使用环境变量**
```bash
LLM_API_KEY="sk-xxx" SERVER_PORT=8080 ./gradlew :mpp-server:run
```

### 步骤 4: 验证服务器

在另一个终端窗口：

```bash
# 健康检查
curl http://localhost:8080/health

# 预期输出:
# {"status":"ok","version":"1.0.0"}
```

### 步骤 5: 测试 API

```bash
# 运行测试脚本
./mpp-server/scripts/test-api.sh

# 或手动测试
curl http://localhost:8080/api/projects | jq .
```

## 📝 基本使用示例

### 1. 获取项目列表

```bash
curl http://localhost:8080/api/projects
```

**响应示例:**
```json
{
  "projects": [
    {
      "id": "autocrud",
      "name": "autocrud",
      "path": "/Volumes/source/ai/autocrud",
      "description": "AI Coding Agent for development tasks"
    }
  ]
}
```

### 2. 执行 Agent 任务（同步）

```bash
curl -X POST http://localhost:8080/api/agent/run \
  -H "Content-Type: application/json" \
  -d '{
    "projectId": "autocrud",
    "task": "List all Kotlin files in the mpp-core module"
  }'
```

### 3. 执行 Agent 任务（流式）

```bash
curl -N -X POST http://localhost:8080/api/agent/stream \
  -H "Content-Type: application/json" \
  -d '{
    "projectId": "autocrud",
    "task": "Show me the main application structure"
  }'
```

**SSE 输出示例:**
```
event: message
data: {"role":"assistant","content":"I'll help you explore the project structure..."}

event: tool_call
data: {"toolName":"glob","description":"pattern matcher","details":"Searching for files..."}

event: tool_result
data: {"toolName":"glob","success":true,"summary":"Found 42 files","output":"..."}

event: complete
data: {"success":true,"message":"Task completed successfully"}
```

## 🔧 配置选项

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SERVER_HOST` | `0.0.0.0` | 服务器监听地址 |
| `SERVER_PORT` | `8080` | 服务器端口 |
| `PROJECTS_ROOT` | `$HOME` | 项目根目录 |
| `LLM_PROVIDER` | `openai` | LLM 提供商 |
| `LLM_MODEL` | `gpt-4` | LLM 模型名称 |
| `LLM_API_KEY` | - | LLM API Key（必需） |
| `LLM_BASE_URL` | - | 自定义 LLM API 地址（可选） |

### 使用自定义 LLM 提供商

```bash
# 使用 Azure OpenAI
export LLM_PROVIDER="azure"
export LLM_MODEL="gpt-4"
export LLM_API_KEY="your-azure-key"
export LLM_BASE_URL="https://your-resource.openai.azure.com"

# 使用本地 LLM (如 Ollama)
export LLM_PROVIDER="ollama"
export LLM_MODEL="llama2"
export LLM_BASE_URL="http://localhost:11434"
```

## 🐛 故障排查

### 问题 1: 服务器无法启动

**错误**: `Address already in use`

**解决方案**:
```bash
# 更改端口
export SERVER_PORT=8081
./gradlew :mpp-server:run
```

### 问题 2: 找不到项目

**错误**: `Project not found`

**解决方案**:
```bash
# 检查项目根目录
export PROJECTS_ROOT="/path/to/your/projects"

# 或者使用绝对路径的项目 ID
curl http://localhost:8080/api/projects
```

### 问题 3: LLM API 错误

**错误**: `Invalid API key` 或 `Connection refused`

**解决方案**:
```bash
# 检查 API Key
echo $LLM_API_KEY

# 测试 API 连接
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $LLM_API_KEY"
```

### 问题 4: 查看日志

```bash
# 启用详细日志
./gradlew :mpp-server:run --info

# 或查看应用日志
tail -f ~/.autodev/logs/autodev-app.log
```

## 📱 Android 客户端连接

在 Android 应用中连接到服务器：

```kotlin
// 配置服务器地址
val serverUrl = "http://your-server-ip:8080"

// 创建 HTTP 客户端
val client = HttpClient {
    install(ContentNegotiation) {
        json()
    }
}

// 获取项目列表
val projects = client.get("$serverUrl/api/projects")
    .body<ProjectListResponse>()

// 执行 Agent 任务（流式）
client.preparePost("$serverUrl/api/agent/stream") {
    contentType(ContentType.Application.Json)
    setBody(AgentRequest(
        projectId = "autocrud",
        task = "Add logging to the main function"
    ))
}.execute { response ->
    response.bodyAsChannel().consumeEachLine { line ->
        if (line.startsWith("data: ")) {
            val event = Json.decodeFromString<TimelineEventData>(
                line.substring(6)
            )
            // 使用 ComposeRenderer 渲染事件
            renderer.handleEvent(event)
        }
    }
}
```

## 🧪 运行测试

```bash
# 运行所有测试
./gradlew :mpp-server:test

# 运行特定测试
./gradlew :mpp-server:test --tests ServerApplicationTest

# 查看测试报告
open mpp-server/build/reports/tests/test/index.html
```

## 📊 性能建议

### MVP 阶段限制

- 单个请求处理（无并发）
- 简单的轮询机制（SSE）
- 无请求队列
- 无速率限制

### 生产环境建议

1. **使用反向代理**: Nginx 或 Caddy
2. **启用 HTTPS**: Let's Encrypt
3. **添加认证**: JWT 或 API Key
4. **监控**: Prometheus + Grafana
5. **日志**: ELK Stack
6. **容器化**: Docker + Docker Compose

## 🔗 相关资源

- [完整 README](../../mpp-server/README.md)
- [mpp-core 文档](../../mpp-core/README.md)
- [ComposeRenderer 源码](../../mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ComposeRenderer.kt)
- [Ktor 文档](https://ktor.io/docs/)

## 💡 下一步

1. ✅ 启动服务器并测试基本功能
2. 📱 在 Android 应用中集成客户端
3. 🎨 使用 ComposeRenderer 渲染 Timeline
4. 🔒 添加认证和授权
5. 🚀 部署到生产环境

## 📄 License

Apache License 2.0

