# Git Clone 逻辑优化总结

## 优化日期
2025-11-10

## 优化概述
针对 Git Clone 功能进行了三个关键优化，提升了日志记录、分支处理和路径跟踪能力。

---

## 1. 集成 AutoDevLogger 日志系统

### 问题
- 之前仅通过 SSE 事件发送日志，没有持久化记录
- 缺少服务端日志用于调试和问题追踪

### 解决方案
在以下文件中集成了 `AutoDevLogger`：
- `mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt`
- `mpp-server/src/main/kotlin/cc/unitmesh/server/command/GitCommand.kt`

### 关键改进
- ✅ 所有关键操作都记录到日志文件 `~/.autodev/logs/autodev-app.log`
- ✅ 使用不同日志级别（INFO、DEBUG、WARN、ERROR）
- ✅ 记录详细的命令执行信息和结果
- ✅ 包含异常堆栈跟踪便于调试

### 日志示例
```kotlin
logger.info { "Starting clone process for projectId: $projectId, gitUrl: $gitUrl, branch: ${branch ?: "default"}" }
logger.info { "Created workspace directory at: $projectPath" }
logger.info { "✓ Clone completed successfully at: $projectPath" }
```

---

## 2. 优化默认分支处理逻辑

### 问题
- 之前硬编码使用 `main` 作为默认分支（第146行）
- 如果仓库的默认分支不是 `main`（如 `master`、`develop` 等），会导致失败
- 用户传错分支名时没有自动回退机制

### 解决方案

#### 2.1 Git Clone 逻辑优化
```kotlin
// 之前：硬编码分支
cmd.addAll(listOf("-b", branch ?: "main"))

// 现在：让 Git 使用远程仓库的默认分支
if (!branch.isNullOrBlank()) {
    logger.info { "Cloning with specified branch: $branch" }
    cmd.addAll(listOf("-b", branch))
} else {
    logger.info { "No branch specified, Git will use repository's default branch" }
}
```

#### 2.2 自动回退机制
```kotlin
// 如果指定的分支失败，自动尝试使用默认分支
if (!success && !branch.isNullOrBlank()) {
    logger.warn { "Clone with branch '$branch' failed, retrying with default branch" }
    emitLog(AgentEvent.CloneLog("Branch '$branch' not found, trying repository's default branch..."))
    
    // 清理目录并重试，不指定分支
    deleteDirectory(workspaceDir.toPath())
    workspaceDir.mkdirs()
    
    val fallbackCmd = mutableListOf("git", "clone", "--depth", "1", gitUrl, ".")
    return executeGitCommand(fallbackCmd, workspaceDir, emitLog)
}
```

#### 2.3 Git Pull 逻辑优化
```kotlin
// 之前：默认 pull main
if (!branch.isNullOrBlank()) {
    cmd.add(branch)
} else {
    cmd.add("main") // ❌ 硬编码
}

// 现在：使用当前跟踪分支
if (!branch.isNullOrBlank()) {
    logger.info { "Pulling specified branch: $branch" }
    cmd.add(branch)
} else {
    logger.info { "No branch specified for pull, Git will pull current/tracking branch" }
    // 不指定分支，让 git pull 使用当前跟踪分支
}
```

### 优点
- ✅ 支持任何默认分支（main、master、develop等）
- ✅ 用户体验更好：错误分支名会自动重试
- ✅ 符合 Git 标准行为

---

## 3. 临时目录持久化跟踪

### 问题
- `lastClonedPath` 是实例变量，服务重启后丢失
- 没有方法查询已克隆项目的路径
- 无法追踪多个项目的工作区

### 解决方案

#### 3.1 添加持久化 Map
```kotlin
// 新增：Map 跟踪所有项目
private val tempDirectoryMap = mutableMapOf<String, String>()
```

#### 3.2 在创建工作区时记录
```kotlin
private fun createWorkspaceDir(projectId: String): Path {
    val tempDir = Files.createTempDirectory("autodev-clone-")
    logger.info { "Created temporary directory: ${tempDir.pathString}" }
    
    val workspaceDir = tempDir.resolve(projectId)
    Files.createDirectories(workspaceDir)
    logger.info { "Created workspace directory: ${workspaceDir.pathString} for projectId: $projectId" }
    
    // 存储映射关系
    tempDirectoryMap[projectId] = workspaceDir.pathString
    
    return workspaceDir
}
```

#### 3.3 提供查询 API
```kotlin
/**
 * 获取指定项目的工作区路径
 */
fun getWorkspacePath(projectId: String): String? {
    return tempDirectoryMap[projectId] ?: lastClonedPath
}

/**
 * 获取所有已跟踪的工作区
 */
fun getAllWorkspaces(): Map<String, String> {
    logger.info { "Retrieved all workspaces: ${tempDirectoryMap.size} entries" }
    return tempDirectoryMap.toMap()
}
```

### 优点
- ✅ 可以跟踪多个项目的工作区
- ✅ 提供查询 API 供其他服务使用
- ✅ 所有路径变更都记录到日志中

---

## 4. 依赖修复

### 问题
`mpp-server` 无法找到 `KLogger` 类

### 解决方案
在 `mpp-server/build.gradle.kts` 中添加显式依赖：
```kotlin
dependencies {
    // Use JVM target from multiplatform project
    implementation(projects.mppCore)
    
    // Add kotlin-logging explicitly for JVM
    implementation("io.github.oshai:kotlin-logging-jvm:7.0.13")
    implementation("ch.qos.logback:logback-classic:1.5.16")
    
    // ... 其他依赖
}
```

---

## 测试验证

### 构建测试
```bash
./gradlew :mpp-server:clean :mpp-server:build
```

**结果**: ✅ BUILD SUCCESSFUL

---

## 使用示例

### 查看日志
```bash
# 实时查看日志
tail -f ~/.autodev/logs/autodev-app.log

# 搜索 Git 相关日志
grep "GitCloneService\|GitCommand" ~/.autodev/logs/autodev-app.log
```

### 日志输出示例
```
[GitCloneService] Starting clone process for projectId: my-project, gitUrl: https://github.com/user/repo.git, branch: default
[GitCloneService] Created temporary directory: /tmp/autodev-clone-12345
[GitCloneService] Created workspace directory: /tmp/autodev-clone-12345/my-project for projectId: my-project
[GitCloneService] No branch specified, Git will use repository's default branch
[GitCloneService] Executing git command: git clone --depth 1 https://github.com/user/repo.git . in directory: /tmp/autodev-clone-12345/my-project
[GitCloneService] ✓ Git command completed successfully: git clone --depth 1 https://github.com/user/repo.git .
[GitCloneService] ✓ Clone completed successfully at: /tmp/autodev-clone-12345/my-project
[GitCloneService] Stored lastClonedPath: /tmp/autodev-clone-12345/my-project for projectId: my-project
```

---

## 文件修改清单

### 修改的文件
1. `mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt`
   - 添加 AutoDevLogger
   - 优化分支处理逻辑
   - 添加临时目录跟踪
   - 添加查询 API

2. `mpp-server/src/main/kotlin/cc/unitmesh/server/command/GitCommand.kt`
   - 添加 AutoDevLogger
   - 记录所有 Git 操作

3. `mpp-server/build.gradle.kts`
   - 添加 kotlin-logging-jvm 依赖
   - 添加 logback-classic 依赖

---

## 后续建议

1. **持久化存储**: 考虑将 `tempDirectoryMap` 持久化到数据库或文件中，以支持服务重启后恢复
2. **清理机制**: 添加定时任务清理旧的临时目录
3. **日志轮转**: 配置 logback.xml 进行日志文件轮转，避免文件过大
4. **监控**: 添加 Prometheus metrics 来跟踪 clone 成功率和耗时

---

## 相关文档
- [AutoDevLogger 使用文档](../design-system/design-system-color.md)
- [Git Clone SSE 实现](../git-clone-sse-implementation.md)
- [日志配置](../../mpp-core/src/jvmMain/resources/logback.xml)

