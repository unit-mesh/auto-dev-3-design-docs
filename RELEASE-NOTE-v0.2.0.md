# AutoDev MPP v0.2.0 Release Notes

**发布日期**: 2025-11-10  
**版本**: v0.2.0  
**状态**: 🚀 Production Ready

---

## 🎯 版本亮点

本版本是 AutoDev MPP (Kotlin Multiplatform) 项目的重要里程碑版本，完成了**远程 AI Agent**、**渲染器统一**、**服务器模式**等核心功能的实现，并修复了多个关键问题。现在支持跨平台（Desktop/Android/Web/CLI）的统一 AI 编码助手体验。

---

## ✨ 新增功能

### 1. 远程 AI Agent 支持 🌐

实现了完整的远程 Agent 架构，支持客户端连接到 `mpp-server` 执行 AI 编码任务。

**核心特性:**
- ✅ **SSE (Server-Sent Events) 流式传输**: 实时获取 Agent 执行状态
- ✅ **跨平台客户端支持**: Desktop (Compose) / CLI (TypeScript) / Web
- ✅ **自动 Git 仓库克隆**: 支持公开和私有仓库
- ✅ **统一渲染接口**: 本地和远程模式共享相同的 UI 渲染逻辑

**使用场景:**
- 多用户共享同一个 AI 服务器
- 在云端执行大型项目分析
- 团队协作的代码审查和重构

**参考文档:**
- `remote-agent-implementation-summary.md`
- `remote-agent-usage.md`
- `remote-agent-compose-ui.md`

---

### 2. MPP Server MVP 完成 🎉

`mpp-server` 模块已完成 MVP 开发，提供了生产级别的 REST API 服务。

**核心 API:**
- `GET /health` - 健康检查
- `GET /api/projects` - 项目列表
- `GET /api/projects/{id}` - 项目详情
- `POST /api/agent/stream` - SSE 流式 Agent 执行
- `GET /api/agent/stream` - SSE 流式 Agent 执行 (查询参数)

**部署特性:**
- ✅ **Fat JAR 打包**: 单文件部署，包含所有依赖 (~46MB)
- ✅ **环境变量配置**: 支持 `SERVER_PORT`, `PROJECT_ROOT` 等
- ✅ **CORS 支持**: 跨域资源共享配置
- ✅ **自动 Git Clone**: 动态克隆远程仓库

**快速启动:**
```bash
java -jar mpp-server-0.2.0-all.jar
```

**参考文档:**
- `server/MVP-COMPLETE.md`
- `server/QUICKSTART.md`
- `server/SUMMARY.md`

---

### 3. CLI Server 模式优化 🖥️

CLI 工具新增 `server` 模式，优化了远程 Agent 的用户体验。

**改进内容:**
- ✅ **流式 LLM 输出**: 字符级实时显示，AI 思考过程可视化
- ✅ **简化工具输出**: 只显示关键信息摘要（如 "Found 1782 files"）
- ✅ **Git Clone 进度条**: 可视化仓库克隆进度
- ✅ **过滤噪音日志**: 自动过滤 Git 命令的冗余输出
- ✅ **迭代分隔符**: 清晰的迭代边界显示

**效果对比:**
```bash
# Before (原始 JSON 输出)
data: {"stage":"Cloning repository","progress":10}
data: {"toolName":"glob","output":"📄 file1\n📄 file2\n..."}

# After (优化后的体验)
[████████████████████] 100% - Clone completed
  ✓ Repository ready at: /tmp/project

━━━ Iteration 1/20 ━━━
Let me analyze the project structure...
● File search - Found 1782 files
```

**参考文档:**
- `cli-server-mode-guide.md`
- `cli-render-optimization.md`

---

### 4. 渲染器架构统一 🎨

统一了所有平台的渲染器接口规范，确保跨平台一致性。

**统一接口:**
- **Kotlin**: `CodingAgentRenderer` (mpp-core/commonMain)
- **TypeScript**: `JsCodingAgentRenderer` (从 Kotlin 导出)
- **基类**: `BaseRenderer` (Kotlin/TypeScript 双实现)

**渲染器实现:**
| 渲染器 | 平台 | 继承关系 | 状态 |
|--------|------|---------|------|
| **CliRenderer** | Node.js CLI | extends BaseRenderer | ✅ 已统一 |
| **ServerRenderer** | mpp-server | extends BaseRenderer | ✅ 已统一 |
| **TuiRenderer** | React/Ink TUI | implements Interface | ✅ 特殊架构 |
| **ComposeRenderer** | Desktop/Android | extends BaseRenderer | ✅ 已统一 |

**核心价值:**
- 统一方法签名，避免跨平台不一致
- 单一真相来源 (Single Source of Truth)
- 简化未来扩展和维护

**参考文档:**
- `renderer-unification-summary.md`
- `renderer-interface-spec.md`
- `renderer-architecture.md`

---

### 5. TreeView 文件浏览器 📁

在 Desktop 和 Android 平台集成了文件树视图，支持浏览工作空间。

**功能特性:**
- ✅ **目录树展示**: 使用 Bonsai 库实现
- ✅ **按需加载**: Lazy loading 子目录
- ✅ **智能过滤**: 自动过滤 `.git`, `node_modules`, `build` 等
- ✅ **文件打开**: 点击代码文件在 FileViewerPanel 中查看
- ✅ **可调整大小**: 拖动分隔条调整 TreeView 和 Chat UI 比例
- ✅ **文件类型图标**: 支持 30+ 种代码文件类型识别

**支持的文件类型:**
```
kt, java, js, ts, py, go, rs, c, cpp, cs, swift, rb, php,
html, css, json, xml, yaml, md, txt, sh, sql, gradle, ...
```

**参考文档:**
- `features/treeview-integration.md`
- `features/treeview-performance-improvements.md`

---

### 6. JediTerm 终端集成 💻

在 JVM 平台集成了 JediTerm，支持实时显示 Shell 命令输出。

**核心特性:**
- ✅ **实时终端输出**: PTY 连接到 JediTerm widget
- ✅ **LiveShellExecutor 接口**: 支持流式 Shell 执行
- ✅ **PtyShellExecutor 实现**: 使用 Pty4J 创建 PTY 进程
- ✅ **Timeline 集成**: 终端输出嵌入到 Agent 时间线中

**平台支持:**
- ✅ **JVM (Desktop)**: 完整 JediTerm 支持
- ⚠️ **Android/JS**: 显示 "not supported" 提示

**参考文档:**
- `shell/jediterm-integration.md`
- `shell/pty-handle-fix-summary.md`

---

### 7. 统一版本管理 📦

实现了 `mpp-core`, `mpp-ui`, `mpp-server` 三个模块的统一版本管理。

**改进内容:**
- ✅ **单一版本号**: 在 `gradle.properties` 中配置 `mppVersion`
- ✅ **所有模块同步**: 三个模块自动使用统一版本号
- ✅ **GitHub Actions 集成**: 自动构建和发布所有制品
- ✅ **测试脚本**: `test-mpp-release.sh` 自动化测试

**发布制品:**
| 制品 | 文件 | 说明 |
|------|------|------|
| **Server JAR** | `mpp-server-{version}-all.jar` | 可执行 fat JAR |
| **Android APKs** | `*.apk` | Debug & Release APK |
| **Linux DEB** | `*.deb` | Debian 安装包 |
| **Windows MSI** | `*.msi` | Windows 安装程序 |
| **macOS DMG** | `*.dmg` | macOS 磁盘镜像 |

**参考文档:**
- `mpp-version-management.md`
- `RELEASE-SUMMARY.md`

---

## 🐛 Bug 修复

### 1. 修复 Compose UI 流式显示问题 ✅

**问题**: RemoteAgentChatInterface 虽然使用了 SSE 流式读取，但在 UI 中仍然一次性显示完整内容。

**根本原因**: 使用了错误的协程调度器 (`Dispatchers.Default`)，导致状态更新在后台线程执行，Compose 重组被延迟。

**解决方案**: 将协程调度器改为 `Dispatchers.Main`，确保状态更新在主线程执行，触发实时重组。

```kotlin
// Before ❌
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

// After ✅
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
```

**参考文档:**
- `fix-compose-ui-streaming.md`

---

### 2. 修复 SSE API 问题 ✅

**问题**: 
- curl 测试没有任何输出或响应
- 服务器返回 406 Not Acceptable 错误
- Agent 不是以流式方式运行

**根本原因**:
1. 路由配置错误: 使用 `post("/stream")` + `respondTextWriter` 不兼容
2. 协程作用域问题: 使用独立的 `CoroutineScope` 导致时序错误
3. LLM 流式输出被禁用: `enableLLMStreaming = false`

**解决方案**:
1. 使用 Ktor SSE DSL: `sse("/stream")` + `ServerSentEvent`
2. 使用正确的协程作用域: `coroutineScope { launch { ... } }`
3. 启用 LLM 流式输出: `enableLLMStreaming = true`

**参考文档:**
- `sse-api-fix-summary.md`
- `sse-api-guide.md`

---

### 3. 修复终端重复显示问题 ✅

**问题**: 在 Compose UI 中，同一个终端命令输出被重复显示多次。

**根本原因**: TimelineItem 的 `key` 参数使用了不稳定的值，导致 Compose 无法正确识别和复用组件。

**解决方案**: 为每个 TimelineItem 生成唯一且稳定的 key。

**参考文档:**
- `fix-duplicate-terminal-summary.md`
- `fix-duplicate-terminal-widget.md`

---

### 4. 修复 macOS 打包 JNDI 缺失问题 ✅

**问题**: macOS 打包后的应用启动失败，报错 `NoClassDefFoundError: javax/naming/NamingException`

**根本原因**: JDK 17+ 中 `java.naming` 模块默认不包含在 jlink 创建的自定义运行时中，而 Logback 需要 JNDI API。

**解决方案**: 在 Compose Desktop 配置中添加 `java.naming` 模块。

```kotlin
compose.desktop {
    application {
        jvmArgs += listOf("--add-modules", "java.naming")
        nativeDistributions {
            modules("java.naming")
        }
    }
}
```

**参考文档:**
- `fix-macos-packaging-jndi.md`

---

### 5. 修复 PTY Handle 优化问题 ✅

优化了 PTY handle 的生命周期管理，避免内存泄漏和资源未释放。

**参考文档:**
- `shell/pty-handle-fix-summary.md`
- `shell/pty-handle-optimization-summary.md`
- `shell/live-terminal-pty-handle-fix.md`

---

## 📚 架构改进

### 1. 设计系统完善 🎨

- 统一了 Compose UI 的颜色系统
- 添加自定义图标支持
- SVG 到 ImageVector 转换工具

**参考文档:**
- `design-system/design-system-color.md`
- `design-system/design-system-compose.md`
- `design-system/custom-icons-usage.md`
- `design-system/icon-refactoring-summary.md`

---

### 2. 代码架构分析 📊

添加了多个架构分析文档，帮助理解项目结构：

- **Codex 架构**: Agent 框架核心逻辑
- **Kode 架构**: 代码分析和生成引擎
- **Gemini CLI 架构**: CLI 工具实现
- **Coding Agents 架构**: AI Agent 设计模式

**参考文档:**
- `architecture/codex-architecture-analysis.md`
- `architecture/kode-architecture-analysis.md`
- `architecture/gemini-cli-architecture.md`
- `architecture/coding-agents-architecture.md`

---

## 🚀 性能优化

1. **TreeView 性能优化**: 优化了文件树的加载和渲染性能
2. **CLI 渲染优化**: 减少不必要的输出，提升终端体验
3. **SSE 流式传输**: 降低内存占用，支持大型项目

**参考文档:**
- `features/treeview-performance-improvements.md`
- `cli-render-optimization.md`

---

## 📦 构建和部署

### 本地构建

```bash
# 构建所有模块
./gradlew build --no-daemon

# 构建 mpp-server fat JAR
./gradlew :mpp-server:fatJar

# 构建 Desktop 应用
./gradlew :mpp-ui:packageDistributionForCurrentOS

# 构建 Android APK
./gradlew :mpp-ui:assembleRelease
```

### 运行测试

```bash
# 运行所有测试
./gradlew test --no-daemon

# 测试 MPP 发布流程
./docs/test-scripts/test-mpp-release.sh
```

### GitHub Actions 自动发布

推送 tag 即可触发自动发布：

```bash
git tag compose-v0.2.0
git push origin compose-v0.2.0
```

---

## 📋 系统要求

### Desktop
- **操作系统**: macOS 10.15+, Windows 10+, Linux (Ubuntu 20.04+)
- **JDK**: 17 或更高版本
- **内存**: 最低 2GB RAM，推荐 4GB+

### Android
- **Android 版本**: 8.0 (API 26) 或更高
- **内存**: 最低 1GB RAM

### Server
- **操作系统**: Linux / macOS / Windows
- **JDK**: 17 或更高版本
- **内存**: 最低 512MB RAM，推荐 2GB+
- **磁盘**: 最低 100MB 可用空间

### CLI
- **Node.js**: 16.0 或更高版本
- **操作系统**: macOS, Linux, Windows

---

## 🔗 相关链接

- **GitHub Repository**: [unit-mesh/auto-dev-3-design-docs](https://github.com/unit-mesh/auto-dev-3-design-docs)
- **文档中心**: `/docs` 目录
- **快速开始**: `server/QUICKSTART.md`
- **使用指南**: `remote-agent-usage.md`

---

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

---

## 📝 已知问题

1. **TuiRenderer**: 由于 React/Ink 特殊架构，不使用 BaseRenderer
2. **Android/JS 平台**: JediTerm 终端功能不支持
3. **Git Clone**: 大型仓库克隆可能需要较长时间

---

## 🔜 下一步计划

1. **v0.3.0**: 增强 Agent 的上下文理解能力
2. **多 Agent 协作**: 支持多个 Agent 协同工作
3. **插件系统**: 支持自定义工具和扩展
4. **更多 LLM 支持**: 集成更多 AI 模型提供商

---

**完整更新日志**: 查看 `docs/` 目录下的所有文档

**反馈和问题**: 请在 GitHub Issues 中提交

---

🎉 **Enjoy AutoDev MPP v0.2.0!**
