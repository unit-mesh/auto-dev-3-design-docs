# iOS 平台快速开始指南

## 编译 iOS Framework

### 编译所有 iOS 目标

```bash
# 编译 mpp-core 的所有 iOS 目标
./gradlew :mpp-core:iosArm64MainKlibrary \
          :mpp-core:iosX64MainKlibrary \
          :mpp-core:iosSimulatorArm64MainKlibrary

# 编译 mpp-ui 的所有 iOS 目标
./gradlew :mpp-ui:iosArm64MainKlibrary \
          :mpp-ui:iosX64MainKlibrary \
          :mpp-ui:iosSimulatorArm64MainKlibrary
```

### 链接 iOS Framework

```bash
# 链接 Debug Framework (ARM64 - 真机)
./gradlew :mpp-core:linkDebugFrameworkIosArm64
./gradlew :mpp-ui:linkDebugFrameworkIosArm64

# 链接 Debug Framework (X64 - Intel 模拟器)
./gradlew :mpp-core:linkDebugFrameworkIosX64
./gradlew :mpp-ui:linkDebugFrameworkIosX64

# 链接 Debug Framework (ARM64 - Apple Silicon 模拟器)
./gradlew :mpp-core:linkDebugFrameworkIosSimulatorArm64
./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64

# 链接 Release Framework
./gradlew :mpp-core:linkReleaseFrameworkIosArm64
./gradlew :mpp-ui:linkReleaseFrameworkIosArm64
```

### Framework 输出位置

编译后的 framework 位于:
```
mpp-core/build/bin/iosArm64/debugFramework/AutoDevCore.framework
mpp-core/build/bin/iosArm64/releaseFramework/AutoDevCore.framework

mpp-ui/build/bin/iosArm64/debugFramework/AutoDevUI.framework
mpp-ui/build/bin/iosArm64/releaseFramework/AutoDevUI.framework
```

## 在 Xcode 项目中使用

### 1. 添加 Framework 到 Xcode 项目

1. 将编译好的 `.framework` 文件拖入 Xcode 项目
2. 在 Target -> General -> Frameworks, Libraries, and Embedded Content 中添加
3. 设置 Embed 为 "Embed & Sign"

### 2. 在 Swift 代码中使用

```swift
import AutoDevCore
import AutoDevUI

// 使用 Platform 信息
let platform = Platform()
print("Platform: \(platform.name)")

// 使用配置管理器
let configManager = ConfigManager()
// ... 使用配置管理器的方法
```

## iOS 平台特性

### 支持的功能

✅ **文件系统操作**
- 使用 Foundation 框架的 NSFileManager
- 支持读写文件、创建目录等基本操作

✅ **HTTP 客户端**
- 使用 Ktor Darwin 引擎
- 支持 HTTP/HTTPS 请求

✅ **数据库**
- 使用 SQLDelight Native Driver
- 支持 SQLite 数据库操作

✅ **配置管理**
- 配置文件存储在 `~/.autodev/` 目录
- 支持 YAML 和 JSON 格式

✅ **UI 组件**
- 使用 Compose Multiplatform
- 支持 Markdown 渲染

### 受限的功能

⚠️ **MCP (Model Context Protocol)**
- 不支持,因为 iOS 限制进程执行
- 相关 API 返回空结果或抛出 UnsupportedOperationException

⚠️ **Git 操作**
- 不支持,因为 iOS 没有 git 命令行工具
- `GitOperations.isSupported()` 返回 `false`

⚠️ **Shell 执行**
- 不支持,因为 iOS 限制进程执行
- `ShellExecutor.isAvailable()` 返回 `false`

⚠️ **终端功能**
- 简化实现,无法提供完整的终端交互
- 仅显示命令和输出文本

⚠️ **文件选择器**
- Stub 实现,需要集成 UIDocumentPickerViewController

## 配置文件位置

iOS 平台的配置文件存储在:
```
NSHomeDirectory()/.autodev/config.yaml
NSHomeDirectory()/.autodev/mcp.json
```

## 日志

iOS 平台的日志输出到:
```
NSHomeDirectory()/.autodev/logs/
```

## 常见问题

### Q: 如何在 iOS 模拟器上测试?

A: 使用 `iosX64` (Intel Mac) 或 `iosSimulatorArm64` (Apple Silicon Mac) 目标编译 framework,然后在 Xcode 中运行模拟器。

### Q: 为什么某些功能不可用?

A: iOS 平台有严格的安全限制,不允许执行外部进程或访问 shell。这些功能在 iOS 上提供了简化或 stub 实现。

### Q: 如何调试 iOS framework?

A: 在 Xcode 中设置断点,或使用 `print()` 语句输出日志。Kotlin 代码中的 `println()` 会输出到 Xcode 控制台。

### Q: Framework 太大怎么办?

A: 使用 Release 配置编译,并启用代码优化:
```bash
./gradlew :mpp-core:linkReleaseFrameworkIosArm64 -Pkotlin.native.binary.optimizationMode=FULL
```

## 下一步

1. 查看 [ios-support-summary.md](ios-support-summary.md) 了解详细的实现细节
2. 参考 Android 和 JVM 实现了解完整功能
3. 根据需要扩展 iOS 平台特定功能

