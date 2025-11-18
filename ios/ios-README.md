# AutoDev iOS 支持

AutoDev 现已支持 iOS 平台!🎉

## 概述

AutoDev 是一个基于 Kotlin Multiplatform 和 Compose Multiplatform 的 AI 开发助手。现在您可以在 iOS 设备上运行完整的 AutoDev UI!

### 支持的平台

- ✅ **JVM (Desktop)** - Windows, macOS, Linux
- ✅ **Android** - Android 7.0+ (API 24+)
- ✅ **JavaScript/Node.js** - CLI 和 Web
- ✅ **iOS** - iOS 14.0+ (新增)

## 快速开始

### 1. 编译 iOS Framework

```bash
# 编译用于模拟器的 Debug Framework
./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64

# 编译用于真机的 Debug Framework
./gradlew :mpp-ui:linkDebugFrameworkIosArm64

# 编译 Release Framework
./gradlew :mpp-ui:linkReleaseFrameworkIosArm64
```

Framework 位置:
```
mpp-ui/build/bin/iosSimulatorArm64/debugFramework/AutoDevUI.framework
mpp-ui/build/bin/iosArm64/debugFramework/AutoDevUI.framework
```

### 2. 在 Xcode 中使用

#### 创建 SwiftUI 视图

```swift
import SwiftUI
import AutoDevUI

struct ContentView: View {
    var body: some View {
        ComposeView()
            .ignoresSafeArea()
    }
}

struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return MainKt.MainViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 不需要更新
    }
}
```

#### 添加 Framework 到项目

1. 将 `AutoDevUI.framework` 拖入 Xcode 项目
2. 在 Target -> General -> Frameworks, Libraries, and Embedded Content 中设置为 "Embed & Sign"
3. 在 Build Settings 中禁用 Bitcode
4. 运行应用!

## 功能特性

### ✅ 完整支持

- **Compose UI** - 完整的 Compose Multiplatform UI
- **文件系统** - 使用 Foundation 框架的文件操作
- **HTTP 客户端** - Ktor Darwin 引擎
- **数据库** - SQLDelight Native Driver
- **配置管理** - YAML 和 JSON 配置
- **Markdown 渲染** - 富文本显示
- **主题切换** - 亮色/暗色主题

### ⚠️ 受限功能

由于 iOS 平台限制,以下功能提供简化实现:

- **MCP (Model Context Protocol)** - 不支持进程执行
- **Git 操作** - 不支持 shell 命令
- **Shell 执行** - iOS 安全限制
- **终端功能** - 简化的文本显示
- **文件选择器** - 需要额外实现

## 文档

- **[ios-support-summary.md](ios-support-summary.md)** - 详细的实现总结
- **[ios-quick-start.md](ios-quick-start.md)** - 快速开始指南
- **[ios-app-integration.md](ios-app-integration.md)** - 完整的集成指南
- **[ios-example-app.md](ios-example-app.md)** - 示例应用代码

## 技术栈

- **Kotlin Multiplatform** - 跨平台代码共享
- **Compose Multiplatform** - 声明式 UI 框架
- **Ktor** - HTTP 客户端 (Darwin 引擎)
- **SQLDelight** - 跨平台数据库
- **Foundation** - iOS 原生框架集成

## 架构

```
┌─────────────────────────────────────┐
│         iOS Application             │
│         (Swift/SwiftUI)             │
└──────────────┬──────────────────────┘
               │
               │ MainViewController()
               ▼
┌─────────────────────────────────────┐
│      AutoDevUI.framework            │
│   (Compose Multiplatform UI)        │
├─────────────────────────────────────┤
│  • AutoDevApp (Compose UI)          │
│  • ConfigManager                    │
│  • DatabaseDriverFactory            │
│  • MarkdownRenderer                 │
└──────────────┬──────────────────────┘
               │
               │ depends on
               ▼
┌─────────────────────────────────────┐
│      AutoDevCore.framework          │
│    (Business Logic & Tools)         │
├─────────────────────────────────────┤
│  • CodingAgent                      │
│  • LLM Service                      │
│  • File System                      │
│  • HTTP Client                      │
└─────────────────────────────────────┘
```

## 编译目标

支持三个 iOS 目标:

- **iosX64** - Intel Mac 模拟器
- **iosArm64** - 真机 (iPhone/iPad)
- **iosSimulatorArm64** - Apple Silicon Mac 模拟器

## 系统要求

### 开发环境

- macOS 14.0+
- Xcode 15.0+
- Kotlin 2.2.0+
- Gradle 8.14+

### 运行环境

- iOS 14.0+
- iPadOS 14.0+

## 示例代码

### 最小化应用

```swift
import SwiftUI
import AutoDevUI

@main
struct AutoDevApp: App {
    var body: some Scene {
        WindowGroup {
            ComposeView()
        }
    }
}

struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MainKt.MainViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

### 带配置的应用

```swift
import SwiftUI
import AutoDevUI

@main
struct AutoDevApp: App {
    init() {
        // 初始化配置
        setupAutoDevConfig()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupAutoDevConfig() {
        // 设置日志级别、主题等
        print("🚀 AutoDev iOS App starting...")
    }
}
```

## 常见问题

### Q: 如何在模拟器上运行?

**A:** 使用 `iosSimulatorArm64` (Apple Silicon) 或 `iosX64` (Intel) 目标编译 framework。

### Q: Framework 太大怎么办?

**A:** 使用 Release 配置并启用优化:
```bash
./gradlew :mpp-ui:linkReleaseFrameworkIosArm64 -Pkotlin.native.binary.optimizationMode=FULL
```

### Q: 如何调试?

**A:** 在 Xcode 中设置断点,或在 Kotlin 代码中使用 `println()` 输出到 Xcode 控制台。

### Q: 支持 SwiftUI 预览吗?

**A:** 目前不支持。需要在真机或模拟器上运行。

## 性能优化

- 使用 Release 配置编译
- 启用代码优化
- 使用静态 framework (已配置)
- 按需加载资源

## 贡献

欢迎贡献 iOS 平台的改进!

- 实现文件选择器
- 优化 UI 性能
- 添加 iOS 特定功能
- 改进文档

## 许可证

与 AutoDev 主项目相同的许可证。

## 联系方式

- GitHub Issues: https://github.com/unit-mesh/auto-dev
- 文档: 查看 `docs/` 目录

---

**享受在 iOS 上使用 AutoDev!** 🚀📱

