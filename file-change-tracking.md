# File Change Tracking Feature

## 概述

实现了类似 AutoDev IDEA 版本 `PlannerResultSummary` 的文件变更追踪功能，可以记录、展示和管理 AI Agent 对文件的所有修改。

## 架构设计

### 跨平台核心逻辑 (mpp-core)

#### 1. FileChange 数据模型
- **位置**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/tracking/FileChange.kt`
- **功能**: 定义文件变更的数据结构
- **支持的变更类型**:
  - `CREATE`: 新建文件
  - `EDIT`: 编辑文件
  - `DELETE`: 删除文件
  - `OVERWRITE`: 覆盖文件

#### 2. FileChangeTracker 追踪器
- **位置**: `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/tracking/FileChangeTracker.kt`
- **功能**: 
  - 使用 `StateFlow` 管理文件变更列表
  - 支持添加监听器模式
  - 提供变更查询和管理 API
- **关键方法**:
  - `recordChange()`: 记录新的文件变更
  - `clearChanges()`: 清空所有变更
  - `removeChange()`: 移除特定变更
  - `getChangedFilePaths()`: 获取所有变更的文件路径

#### 3. 工具集成
已在以下工具中集成变更追踪：
- `WriteFileTool`: 自动记录文件写入操作
- `EditFileTool`: 自动记录文件编辑操作

### UI 层 (mpp-ui)

#### FileChangeSummary Compose 组件
- **位置**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/editor/FileChangeSummary.kt`
- **功能**:
  - 折叠/展开式变更列表展示
  - 显示变更统计（文件数、变更类型）
  - 支持单个/批量撤销操作
  - 支持单个/批量保留操作

#### 集成位置
已集成到 `DevInEditorInput` 输入框上方，作为独立的可折叠面板。

## 使用方式

### 对于开发者

#### 1. 在工具中自动记录变更

```kotlin
// 在 Tool 的 execute 方法中
FileChangeTracker.recordChange(
    FileChange(
        filePath = params.path,
        changeType = ChangeType.CREATE,
        originalContent = null,
        newContent = newContent,
        metadata = mapOf("tool" to "my-tool")
    )
)
```

#### 2. 监听变更

```kotlin
// 添加监听器
FileChangeTracker.addListener(object : FileChangeListener {
    override fun onFileChanged(change: FileChange) {
        println("File changed: ${change.filePath}")
    }
})

// 或使用 Flow
FileChangeTracker.changes.collectAsState()
```

### 对于用户

#### UI 操作
1. **查看变更**: 点击折叠栏展开查看所有文件变更
2. **撤销单个变更**: 点击文件项右侧的 ❌ 按钮
3. **保留单个变更**: 点击文件项右侧的 ✓ 按钮
4. **撤销所有变更**: 点击顶部的 "Undo All" 按钮
5. **保留所有变更**: 点击顶部的 "Keep All" 按钮

#### 变更类型图标
- 🟢 `CREATE`: 新建文件
- 🔵 `EDIT`: 编辑文件
- 🔴 `DELETE`: 删除文件
- 🟡 `OVERWRITE`: 覆盖文件

## 平台支持

### 完整支持
- ✅ **JVM/Desktop**: 完整功能支持
- ✅ **Android**: 完整功能支持
- ✅ **JS/CLI**: 完整功能支持

### 注意事项
- FileChangeTracker 是跨平台的，在所有目标上工作
- UI 组件使用 Compose Multiplatform，在 JVM/Android/JS 上都可用

## 技术细节

### 依赖变更
为了支持 JS 目标，将 `bonsai` 树形视图库从 `commonMain` 移到了平台特定源集：
- `jvmMain`: 使用完整的 Bonsai 树形视图
- `androidMain`: 使用完整的 Bonsai 树形视图
- `jsMain`: 使用简化的占位符实现

### 文件操作限制
由于 `ProjectFileSystem` 接口不支持文件删除操作，对于 `CREATE` 类型的文件，撤销操作会写入空内容而不是删除文件。

## 未来改进

1. **Diff 视图**: 添加文件内容对比功能
2. **批量操作**: 支持选择性批量操作
3. **变更历史**: 保存变更历史记录
4. **文件删除**: 完善 ProjectFileSystem API 以支持文件删除
5. **持久化**: 将变更记录持久化到数据库

## 测试

### 构建测试
```bash
# 测试 mpp-core
./gradlew :mpp-core:assembleJsPackage

# 测试 mpp-ui
./gradlew :mpp-ui:compileKotlinJvm :mpp-ui:compileKotlinJs
```

### 功能测试
1. 运行 AutoDev Desktop/CLI
2. 执行文件操作命令（如 `/write`, `/edit`）
3. 观察输入框上方的变更摘要面板
4. 测试展开/折叠、撤销/保留功能

## 参考

- IDEA 版本实现: `core/src/main/kotlin/cc/unitmesh/devti/gui/planner/PlannerResultSummary.kt`
- Koog Agents 实现: `Samples/koog/agents/agents-ext/src/commonMain/kotlin/ai/koog/agents/ext/tool/file/EditFileTool.kt`

