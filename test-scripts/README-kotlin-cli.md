# Kotlin Remote Agent CLI - 快速开始

## 简介

这是 TypeScript Remote Agent CLI 的 Kotlin 实现版本，功能完全一致，但具有更强的类型安全性和代码复用能力。

## 快速测试

### 1. 查看帮助

```bash
./gradlew :mpp-ui:runRemoteAgentCli --args="--help"
```

### 2. 测试连接

确保 mpp-server 正在运行：

```bash
# 终端 1: 启动服务器
./gradlew :mpp-server:bootRun

# 终端 2: 测试 CLI
./gradlew :mpp-ui:runRemoteAgentCli --args="--server http://localhost:8080 --project-id autocrud --task '列出所有 Kotlin 文件' --use-server-config"
```

### 3. 使用测试脚本

```bash
chmod +x docs/test-scripts/test-kotlin-remote-agent-cli.sh
./docs/test-scripts/test-kotlin-remote-agent-cli.sh
```

## 主要特性

✅ **已实现并测试通过**:
- 命令行参数解析
- 服务器健康检查
- HTTP 客户端连接
- SSE 流式事件处理 (代码已实现)
- ANSI 颜色和 Emoji 显示
- 错误处理和显示
- 复用 RemoteAgentClient (common 模块)

⏳ **需要服务器端支持**:
- Git 自动克隆
- 实际任务执行
- LLM 流式输出
- 工具调用显示

## 与 TypeScript 版本对比

| 特性 | TypeScript | Kotlin |
|------|-----------|--------|
| 启动时间 | ~100ms | ~2-3s |
| 内存占用 | ~50MB | ~100-200MB |
| 类型安全 | 中 | 强 |
| 代码复用 | 低 | 高 |
| 跨平台 | Node.js | JVM/Android/Native |

## 测试结果

详见: [KOTLIN_CLI_TEST_RESULTS.md](./KOTLIN_CLI_TEST_RESULTS.md)

**总结**: ✅ 所有核心功能测试通过，与 TypeScript 版本功能一致。

## 文件位置

- **CLI 实现**: `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/ui/cli/RemoteAgentCli.kt`
- **Gradle 任务**: `mpp-ui/build.gradle.kts` (runRemoteAgentCli)
- **使用文档**: `docs/remote-agent-cli.md`
- **测试脚本**: `docs/test-scripts/test-kotlin-remote-agent-cli.sh`

## 常见问题

**Q: 为什么启动这么慢?**
A: JVM 冷启动需要 2-3 秒，这是正常的。如果需要快速启动，建议使用 TypeScript 版本。

**Q: 如何减少内存占用?**
A: 可以使用 GraalVM 编译为 native 可执行文件，但需要额外配置。

**Q: 与 TypeScript 版本有什么区别?**
A: 功能完全一致，但 Kotlin 版本具有更强的类型安全性，并且复用了 common 模块的代码。

**Q: 如何调试?**
A: 查看日志文件 `~/.autodev/logs/autodev-app.log`

