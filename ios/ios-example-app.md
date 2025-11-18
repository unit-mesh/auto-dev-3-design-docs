# iOS 示例应用

这是一个最小化的 iOS 应用示例,展示如何集成 AutoDev Compose Multiplatform UI。

## 项目结构

```
AutoDevIOSApp/
├── AutoDevIOSApp/
│   ├── AutoDevIOSApp.swift          # 应用入口
│   ├── ContentView.swift            # 主视图
│   ├── ComposeView.swift            # Compose UI 包装器
│   └── Info.plist                   # 应用配置
├── Frameworks/
│   └── AutoDevUI.framework          # Kotlin framework
└── AutoDevIOSApp.xcodeproj          # Xcode 项目
```

## 文件内容

### 1. AutoDevIOSApp.swift

```swift
import SwiftUI

@main
struct AutoDevIOSApp: App {
    init() {
        print("🚀 AutoDev iOS App starting...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // 背景色
            Color.black.ignoresSafeArea()
            
            // Compose UI
            ComposeView()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
```

### 3. ComposeView.swift

```swift
import SwiftUI
import AutoDevUI

struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // 调用 Kotlin 的 MainViewController 函数
        // 这个函数在 mpp-ui/src/iosMain/kotlin/cc/unitmesh/devins/ui/Main.kt 中定义
        return MainKt.MainViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Compose UI 是声明式的,不需要手动更新
    }
}
```

### 4. Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>AutoDev</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- 文件访问权限 -->
    <key>NSDocumentsFolderUsageDescription</key>
    <string>AutoDev 需要访问文档以管理项目文件</string>
    
    <!-- 网络访问权限 -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
```

## 创建步骤

### 使用 Xcode 创建

1. **创建新项目**
   - 打开 Xcode
   - File -> New -> Project
   - 选择 "iOS" -> "App"
   - 点击 Next

2. **配置项目**
   - Product Name: `AutoDevIOSApp`
   - Team: 选择您的开发团队
   - Organization Identifier: `cc.unitmesh`
   - Bundle Identifier: `cc.unitmesh.AutoDevIOSApp`
   - Interface: SwiftUI
   - Language: Swift
   - 点击 Next 并选择保存位置

3. **添加 Framework**
   - 编译 AutoDev framework:
     ```bash
     ./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64
     ```
   - 将 `mpp-ui/build/bin/iosSimulatorArm64/debugFramework/AutoDevUI.framework` 拖入 Xcode 项目
   - 在弹出的对话框中:
     - ✅ Copy items if needed
     - ✅ Create groups
     - ✅ Add to targets: AutoDevIOSApp
   - 在项目设置中,选择 Target -> General
   - 在 "Frameworks, Libraries, and Embedded Content" 中:
     - 找到 AutoDevUI.framework
     - 设置 Embed 为 "Embed & Sign"

4. **创建 ComposeView.swift**
   - File -> New -> File
   - 选择 "Swift File"
   - 命名为 `ComposeView.swift`
   - 复制上面的代码

5. **修改 ContentView.swift**
   - 打开 `ContentView.swift`
   - 替换为上面的代码

6. **配置 Build Settings**
   - 选择项目 -> Target -> Build Settings
   - 搜索 "Enable Bitcode"
   - 设置为 "No"
   - 搜索 "Deployment Target"
   - 设置为 "iOS 14.0" 或更高

7. **运行应用**
   - 选择模拟器 (iPhone 15 Pro 或更新)
   - 点击 Run (⌘R)

## 常见问题

### Q: Framework 找不到

**A:** 确保:
1. Framework 已正确添加到项目
2. Framework 的 Embed 设置为 "Embed & Sign"
3. Framework 的架构与目标设备匹配 (模拟器用 Simulator, 真机用 Arm64)

### Q: 编译错误 "Module 'AutoDevUI' not found"

**A:** 
1. 清理项目: Product -> Clean Build Folder (⇧⌘K)
2. 重新编译 framework
3. 确保 framework 路径正确

### Q: 运行时崩溃

**A:** 检查:
1. Bitcode 是否已禁用
2. Deployment Target 是否正确
3. Framework 是否正确嵌入
4. 查看 Xcode 控制台的详细错误信息

### Q: UI 显示空白

**A:**
1. 确保 `ComposeView` 使用了 `ignoresSafeArea()`
2. 检查背景色设置
3. 查看 Xcode 控制台是否有 Kotlin 错误

## 自动化脚本

创建一个脚本来自动构建和复制 framework:

### build-framework.sh

```bash
#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building AutoDev iOS Framework...${NC}"

# 进入项目根目录
cd "$(dirname "$0")/.."

# 编译 framework
./gradlew :mpp-ui:linkDebugFrameworkIosSimulatorArm64

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Framework built successfully!${NC}"
    
    # 复制到 iOS 项目
    FRAMEWORK_PATH="mpp-ui/build/bin/iosSimulatorArm64/debugFramework/AutoDevUI.framework"
    IOS_PROJECT_PATH="ios-app/Frameworks"
    
    if [ -d "$IOS_PROJECT_PATH" ]; then
        echo -e "${BLUE}📦 Copying framework to iOS project...${NC}"
        rm -rf "$IOS_PROJECT_PATH/AutoDevUI.framework"
        cp -R "$FRAMEWORK_PATH" "$IOS_PROJECT_PATH/"
        echo -e "${GREEN}✅ Framework copied!${NC}"
    else
        echo -e "${BLUE}ℹ️  iOS project not found at $IOS_PROJECT_PATH${NC}"
    fi
else
    echo -e "${RED}❌ Framework build failed!${NC}"
    exit 1
fi
```

使用:
```bash
chmod +x build-framework.sh
./build-framework.sh
```

## 下一步

- 添加自定义配置和主题
- 集成文件选择器
- 添加网络请求功能
- 实现数据持久化

查看 [ios-app-integration.md](ios-app-integration.md) 了解更多高级集成选项。

