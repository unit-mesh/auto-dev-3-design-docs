# Logback 日志集成指南

## 概述

mpp-core 现在使用 Logback 作为 JVM 平台的日志后端，提供强大的文件日志存储功能。kotlin-logging 在 JVM 上通过 SLF4J 与 Logback 集成，在其他平台上使用相应的原生日志系统。

## 配置

### 依赖配置

在 `mpp-core/build.gradle.kts` 中已配置：

```kotlin
jvmMain {
    dependencies {
        // Logback for JVM logging backend with file storage
        implementation("ch.qos.logback:logback-classic:1.5.19")
    }
}
```

### Logback 配置文件

配置文件位于 `mpp-core/src/jvmMain/resources/logback.xml`，包含以下特性：

- **控制台输出**：INFO 级别及以上
- **文件输出**：所有级别的日志
- **错误日志**：单独的错误日志文件
- **日志轮转**：按天轮转，单文件最大 100MB
- **日志保留**：普通日志保留 30 天，错误日志保留 90 天

### 日志文件位置

```
~/.autodev/logs/
├── autodev-app.log               # 统一的主日志文件
├── autodev-app-error.log         # 统一的错误日志文件
└── autodev-app.2024-11-06.1.log  # 轮转的历史日志
```

**注意**：所有 AutoDev 组件（mpp-core、mpp-ui 等）都写入同一个日志文件，便于统一管理和查看。

## 使用方法

### 基本用法

```kotlin
import cc.unitmesh.agent.logging.getLogger

class MyClass {
    private val logger = getLogger("MyClass")
    
    fun doSomething() {
        logger.info { "开始执行操作" }
        logger.debug { "调试信息：参数值 = $param" }
        
        try {
            // 业务逻辑
        } catch (e: Exception) {
            logger.error(e) { "操作失败: ${e.message}" }
        }
    }
}
```

### 组件特定的日志级别

配置文件中已为不同组件设置了合适的日志级别：

```xml
<!-- 特定组件的日志级别配置 -->
<logger name="cc.unitmesh.agent" level="DEBUG" />
<logger name="cc.unitmesh.devins" level="DEBUG" />
<logger name="cc.unitmesh.llm" level="INFO" />
<logger name="cc.unitmesh.indexer" level="INFO" />

<!-- MCP 相关日志 -->
<logger name="cc.unitmesh.agent.mcp" level="DEBUG" />
<logger name="cc.unitmesh.agent.config" level="DEBUG" />
```

### 日志级别

- **TRACE**：最详细的调试信息
- **DEBUG**：调试信息，开发时使用
- **INFO**：一般信息，生产环境默认级别
- **WARN**：警告信息
- **ERROR**：错误信息

## 平台差异

### JVM 平台
- 使用 Logback 作为后端
- 支持文件存储和轮转
- 支持复杂的日志配置

### JavaScript 平台
- 使用浏览器/Node.js 控制台
- 不支持文件存储
- 配置相对简单

### Android 平台
- 使用 Android Log 系统
- 日志输出到 Logcat
- 支持标签过滤

## 高级配置

### 自定义日志目录

可以通过系统属性修改日志目录：

```kotlin
System.setProperty("autodev.log.dir", "/custom/log/path")
```

### 动态调整日志级别

```kotlin
import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.Level
import org.slf4j.LoggerFactory

val logger = LoggerFactory.getLogger("cc.unitmesh.agent") as Logger
logger.level = Level.TRACE
```

### 监控日志文件

```kotlin
import cc.unitmesh.agent.logging.JvmLoggingInitializer

// 获取统一日志文件路径
val logFile = JvmLoggingInitializer.getCurrentLogFile()        // ~/.autodev/logs/autodev-app.log
val errorLogFile = JvmLoggingInitializer.getErrorLogFile()    // ~/.autodev/logs/autodev-app-error.log

// 检查日志文件大小
val logSize = JvmLoggingInitializer.getLogFileSize()
```

## 最佳实践

1. **使用结构化日志**：
   ```kotlin
   logger.info { "用户操作: action=$action, userId=$userId, result=$result" }
   ```

2. **避免字符串拼接**：
   ```kotlin
   // ❌ 不推荐
   logger.info("User " + userId + " performed " + action)
   
   // ✅ 推荐
   logger.info { "User $userId performed $action" }
   ```

3. **合理使用日志级别**：
   - 生产环境使用 INFO 级别
   - 开发调试使用 DEBUG 级别
   - 错误处理必须使用 ERROR 级别

4. **异常日志包含堆栈**：
   ```kotlin
   logger.error(exception) { "操作失败: ${exception.message}" }
   ```

## 故障排除

### 日志文件未创建
1. 检查目录权限：`~/.autodev/logs/`
2. 确认 Logback 配置文件存在
3. 查看控制台是否有初始化错误

### 日志级别不生效
1. 检查 `logback.xml` 配置
2. 确认 logger 名称匹配
3. 重启应用程序

### 性能问题
1. 调整日志级别，减少 DEBUG 输出
2. 检查日志文件大小和轮转配置
3. 考虑异步日志记录（如需要）

## 测试

运行日志集成测试：

```bash
./gradlew :mpp-core:jvmTest --tests "cc.unitmesh.agent.logging.LogbackIntegrationTest"
```

查看测试日志：

```bash
tail -f ~/.autodev/logs/autodev-app.log
```
