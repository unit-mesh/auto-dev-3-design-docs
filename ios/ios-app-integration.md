# iOS 应用集成指南

本指南介绍如何将 AutoDev Compose Multiplatform UI 集成到 iOS 应用中。

## 前提条件

- Xcode 15.0 或更高版本
- macOS 14.0 或更高版本
- CocoaPods (可选,用于依赖管理)

## 步骤 1: 编译 iOS Framework

首先,编译 AutoDev 的 iOS framework:

```bash
# 编译 Debug Framework (用于开发)
./gradlew :mpp-ui:linkDebugFrameworkIosArm64        # 真机
./gradlew :mpp-ui:linkDebugFrameworkIosX64          # Intel 模拟器
./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64  # Apple Silicon 模拟器

# 编译 Release Framework (用于发布)
./gradlew :mpp-ui:linkReleaseFrameworkIosArm64
```

编译后的 framework 位于:
```
mpp-ui/build/bin/iosArm64/debugFramework/AutoDevUI.framework
mpp-ui/build/bin/iosArm64/releaseFramework/AutoDevUI.framework
```

## 步骤 2: 创建 Xcode 项目

1. 打开 Xcode,创建新的 iOS App 项目
2. 选择 SwiftUI 作为界面框架
3. 设置项目名称为 "AutoDevApp" (或您喜欢的名称)

## 步骤 3: 添加 Framework 到项目

### 方法 1: 手动添加

1. 将编译好的 `AutoDevUI.framework` 拖入 Xcode 项目
2. 在项目设置中,选择 Target -> General
3. 在 "Frameworks, Libraries, and Embedded Content" 中添加 framework
4. 设置 Embed 为 "Embed & Sign"

### 方法 2: 使用 CocoaPods (推荐)

创建 `Podfile`:

```ruby
platform :ios, '14.0'

target 'AutoDevApp' do
  use_frameworks!
  
  pod 'AutoDevUI', :path => '../mpp-ui/build/cocoapods/publish/debug'
end
```

然后运行:
```bash
pod install
```

## 步骤 4: 在 Swift 中使用

### 基本集成

在 SwiftUI 中使用 Compose UI:

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
        // 调用 Kotlin 的 MainViewController 函数
        return MainKt.MainViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 不需要更新
    }
}

#Preview {
    ContentView()
}
```

### 完整示例

创建一个完整的 iOS 应用:

```swift
import SwiftUI
import AutoDevUI

@main
struct AutoDevApp: App {
    init() {
        // 初始化 AutoDev (如果需要)
        // 例如: 设置日志、配置等
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ComposeView()
                .ignoresSafeArea()
        }
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

#Preview {
    ContentView()
}
```

## 步骤 5: 配置项目设置

### Info.plist 配置

如果需要访问文件系统或网络,添加相应的权限:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问照片库以选择文件</string>

<key>NSDocumentsFolderUsageDescription</key>
<string>需要访问文档以管理项目文件</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Build Settings

确保以下设置正确:

- **Deployment Target**: iOS 14.0 或更高
- **Swift Language Version**: Swift 5.0 或更高
- **Enable Bitcode**: No (Kotlin/Native 不支持 Bitcode)

## 步骤 6: 运行应用

1. 选择目标设备或模拟器
2. 点击 Run (⌘R)
3. 应用应该启动并显示 AutoDev Compose UI

## 高级配置

### 自定义启动参数

如果需要传递参数给 Compose UI:

```swift
// 在 Kotlin 中添加参数支持
// Main.kt
fun MainViewController(projectPath: String? = null): UIViewController {
    return ComposeUIViewController {
        AutoDevApp(initialProjectPath = projectPath)
    }
}

// 在 Swift 中使用
let viewController = MainKt.MainViewController(projectPath: "/path/to/project")
```

### 与 Swift 代码交互

创建一个桥接层来在 Swift 和 Kotlin 之间通信:

```kotlin
// Kotlin 侧
object IOSBridge {
    var onProjectSelected: ((String) -> Unit)? = null
    
    fun selectProject(path: String) {
        onProjectSelected?.invoke(path)
    }
}
```

```swift
// Swift 侧
import AutoDevUI

class ProjectManager {
    init() {
        IOSBridge.shared.onProjectSelected = { path in
            print("Project selected: \(path)")
        }
    }
    
    func selectProject(at path: String) {
        IOSBridge.shared.selectProject(path: path)
    }
}
```

## 故障排除

### Framework 找不到

确保 framework 路径正确,并且已经编译了对应架构的 framework。

### 运行时崩溃

检查:
1. Framework 是否正确嵌入 (Embed & Sign)
2. Deployment Target 是否匹配
3. 是否禁用了 Bitcode

### UI 不显示

确保:
1. `ComposeView` 正确设置了 `ignoresSafeArea()`
2. 没有其他视图遮挡 Compose UI
3. 检查 Xcode 控制台的错误信息

## 自动化构建

### 使用 Gradle 任务

创建一个 Gradle 任务来自动构建和复制 framework:

```kotlin
// build.gradle.kts
tasks.register("buildIOSFramework") {
    dependsOn(
        ":mpp-ui:linkDebugFrameworkIosArm64",
        ":mpp-ui:linkDebugFrameworkIosSimulatorArm64"
    )
    
    doLast {
        // 复制 framework 到 iOS 项目
        copy {
            from("mpp-ui/build/bin/iosArm64/debugFramework")
            into("ios-app/Frameworks")
        }
    }
}
```

### 使用 Xcode Build Phase

在 Xcode 中添加 Run Script Phase:

```bash
cd "$SRCROOT/.."
./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64
```

## 下一步

- 查看 [ios-support-summary.md](ios-support-summary.md) 了解 iOS 平台的功能和限制
- 查看 [ios-quick-start.md](ios-quick-start.md) 了解快速开始指南
- 探索 Compose Multiplatform 文档: https://www.jetbrains.com/lp/compose-multiplatform/

## 示例项目

完整的示例项目即将推出,敬请期待!

