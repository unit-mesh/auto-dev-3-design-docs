# TreeView Integration in AutoCRUD

## 概述

在 MPP-UI 的 Desktop 和 Android 平台集成了基于 Bonsai 库的文件树视图功能，允许用户在 Chat UI 中浏览工作空间目录结构。

## 技术实现

### 使用的库

- **Bonsai**: v1.2.0
  - `cafe.adriel.bonsai:bonsai-core:1.2.0`
  - `cafe.adriel.bonsai:bonsai-file-system:1.2.0`
  - GitHub: https://github.com/adrielcafe/bonsai

### 核心组件

#### 1. FileSystemTreeView
- **位置**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/FileSystemTreeView.kt`
- **功能**:
  - 使用 Bonsai 的 FileSystemTree 展示目录结构
  - 支持按需加载子目录（lazy loading）
  - 自动过滤常见的忽略目录（.git, .idea, build, node_modules 等）
  - 点击代码文件可在 FileViewerPanel 中打开
  - 自定义图标显示不同文件类型

**支持的代码文件类型**:
```kotlin
kt, kts, java, js, ts, tsx, jsx, py, go, rs,
c, cpp, h, hpp, cs, swift, rb, php,
html, css, scss, sass, json, xml, yaml, yml,
md, txt, sh, bash, sql, gradle, properties
```

#### 2. ResizableSplitPane
- **位置**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/ResizableSplitPane.kt`
- **功能**:
  - 可拖动调整大小的分割面板
  - 支持水平分割（左右布局）
  - 最小/最大比例限制（默认 20%-80%）
  - 流畅的拖动体验

#### 3. CodingAgentViewModel 扩展
- **新增状态**:
  ```kotlin
  var isTreeViewVisible: Boolean  // TreeView 显示状态
  fun toggleTreeView()             // 切换 TreeView 显示
  fun closeTreeView()              // 关闭 TreeView
  ```

#### 4. AgentChatInterface 更新
- **新增功能**:
  - 状态栏添加文件夹图标按钮
  - 点击图标切换 TreeView 显示
  - TreeView 和 Chat UI 各占 50% 宽度
  - 支持拖动调整两者大小比例

## 使用方法

### 1. 打开/关闭 TreeView
- **桌面端 (Desktop)**: 在顶部工具栏点击文件夹图标 📁
- **移动端 (Android)**: 打开顶部菜单，选择 "File Explorer"
- 图标会高亮显示表示 TreeView 已打开
- 只在 Agent 模式下可用（Chat 模式不显示 TreeView）

### 2. 浏览目录
- 点击文件夹展开/折叠子目录
- 自动过滤隐藏文件和常见构建目录
- 目录和文件按字母顺序排序（文件夹在前）

### 3. 打开文件
- 点击代码文件会在右侧 FileViewerPanel 中打开
- 支持语法高亮显示

### 4. 调整大小
- 拖动 TreeView 和 Chat UI 之间的分隔条
- 可以调整为 30% - 70% 之间的任意比例

## 布局说明

### 三列布局模式

```
┌─────────────┬─────────────┬─────────────┐
│             │             │             │
│  Chat UI    │  TreeView   │  FileViewer │
│             │             │  (optional) │
│             │             │             │
└─────────────┴─────────────┴─────────────┘
```

- **左侧**: Chat UI（消息列表）
- **中间**: TreeView（可选，点击图标切换）
- **右侧**: FileViewerPanel（可选，点击文件后显示）

### 自适应宽度
- 仅 Chat UI: 100% 宽度
- Chat + TreeView: 各 50% 宽度（可拖动调整）
- Chat + TreeView + FileViewer: 25% + 25% + 50% 宽度（可拖动调整）

## 平台支持

### ✅ JVM (Desktop)
- 完全支持
- 使用 `java.io.File` API
- 测试通过

### ✅ Android
- 完全支持（理论上，Android 也支持 java.io.File）
- 需要相应的文件权限

### ❌ JavaScript (Web)
- 不支持（FileSystemTree 依赖 JVM/Android 文件系统）

## 性能优化

1. **按需加载**: 只在展开文件夹时加载子目录
2. **过滤优化**: 自动忽略 .git, build, node_modules 等大型目录
3. **状态管理**: 使用 Compose State 进行高效渲染

## 测试

运行测试脚本：
```bash
cd /Volumes/source/ai/autocrud
./docs/test-scripts/treeview-test.sh
```

或手动测试：
```bash
# 编译
./gradlew :mpp-ui:jvmJar

# 测试
./gradlew :mpp-ui:jvmTest
```

## 已知限制

1. TreeView 仅在 JVM 和 Android 平台可用
2. 大型目录（10000+ 文件）可能加载较慢
3. 文件监听（FileObserver/WatchService）尚未实现

## 未来改进

- [ ] iOS 平台支持
- [ ] 文件/文件夹拖拽功能
- [ ] 实时文件系统监听
- [ ] 搜索和过滤功能
- [ ] 自定义过滤规则配置

## 参考资料

- Bonsai GitHub: https://github.com/adrielcafe/bonsai
- Bonsai 文档: https://github.com/adrielcafe/bonsai#readme

