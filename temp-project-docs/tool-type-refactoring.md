# ToolType 重构文档

## 概述

本次重构将原有的基于字符串的工具名称系统重构为类型安全的 `ToolType` sealed class 系统，提供了更好的类型安全性、IDE 支持和可维护性。

## 重构内容

### 1. 新增文件

#### `ToolType.kt` - 核心 sealed class
```kotlin
sealed class ToolType(
    val name: String,           // 工具名称（向后兼容）
    val displayName: String,    // 显示名称（人类可读）
    val tuiEmoji: String,      // TUI 渲染的 emoji
    val composeIcon: String,   // Compose UI 的图标
    val category: ToolCategory  // 工具分类
)
```

**特性：**
- 类型安全的工具定义
- 包含渲染所需的所有元数据
- 支持分类管理
- 提供便捷的查询方法

#### `ToolCategory.kt` - 工具分类枚举
```kotlin
enum class ToolCategory(
    val displayName: String,
    val description: String,
    val tuiEmoji: String,
    val composeIcon: String
)
```

**分类包括：**
- `FileSystem` - 文件系统操作
- `Search` - 搜索工具
- `Execution` - 执行工具
- `Information` - 信息工具
- `Utility` - 实用工具
- `SubAgent` - 子代理工具

### 2. 工具定义

#### 文件系统工具
- `ReadFile` - 读取文件 📄
- `WriteFile` - 写入文件 ✏️
- `ListFiles` - 列出文件 📁
- `EditFile` - 编辑文件 📝
- `PatchFile` - 补丁文件 🔧

#### 搜索工具
- `Grep` - 内容搜索 🔍
- `Glob` - 文件查找 🌐

#### 执行工具
- `Shell` - Shell 命令 💻
- `Exec` - 执行程序 ⚡

#### 信息工具
- `FileInfo` - 文件信息 ℹ️
- `DirInfo` - 目录信息 📊

#### 实用工具
- `Help` - 帮助 ❓
- `Version` - 版本 🏷️

#### 子代理工具
- `ErrorRecovery` - 错误恢复 🚑
- `LogSummary` - 日志摘要 📋
- `CodebaseInvestigator` - 代码库调查 🔬

### 3. 向后兼容性

#### 保留 `ToolNames` 对象
- 标记为 `@Deprecated`
- 所有常量仍然可用
- 内部委托给新的 `ToolType` 系统

#### 扩展函数支持迁移
```kotlin
fun String.toToolType(): ToolType?           // 字符串转 ToolType
fun String.isValidToolName(): Boolean        // 验证工具名称
fun String.getToolCategory(): ToolCategory?  // 获取工具分类
```

### 4. 更新的组件

#### `ToolOrchestrator`
- 使用 `ToolType` 进行工具匹配
- 保留字符串匹配作为后备

#### `CodingAgentExecutor`
- 使用 `ToolType` 进行重复检测配置
- 使用 `ToolType` 进行文件编辑记录

#### `ComposeRenderer`
- 使用 `ToolType` 进行工具显示格式化
- 支持新的图标和显示名称

#### `CliRenderer`
- 支持 `cmd` 和 `command` 参数
- 使用 `ToolType` 的 emoji 显示

#### `ToolBasedCommandCompletionProvider`
- 使用 `ToolType` 的 emoji 作为图标

## 使用示例

### 旧方式（已弃用）
```kotlin
when (toolName) {
    ToolNames.READ_FILE -> println("📄 Reading file")
    ToolNames.WRITE_FILE -> println("✏️ Writing file")
    else -> println("🔧 Unknown tool")
}
```

### 新方式（推荐）
```kotlin
when (toolType) {
    ToolType.ReadFile -> println("${toolType.tuiEmoji} ${toolType.displayName}")
    ToolType.WriteFile -> println("${toolType.tuiEmoji} ${toolType.displayName}")
    else -> println("${toolType.tuiEmoji} ${toolType.displayName}")
}
```

### 分类操作
```kotlin
// 获取所有文件系统工具
val fileSystemTools = ToolType.byCategory(ToolCategory.FileSystem)

// 检查工具能力
if (ToolType.requiresFileSystem(toolType)) {
    // 需要文件系统访问
}

if (ToolType.isExecutionTool(toolType)) {
    // 执行外部命令
}
```

## 迁移指南

### 1. 立即可用
- 所有现有代码继续工作
- 编译时会显示弃用警告

### 2. 逐步迁移
1. 将字符串工具名称替换为 `ToolType` 对象
2. 使用 `toolName.toToolType()` 进行转换
3. 利用新的分类和元数据功能

### 3. 完全迁移后
- 移除 `@Suppress("DEPRECATION")` 注解
- 删除对 `ToolNames` 的引用
- 享受完整的类型安全

## 优势

### 1. 类型安全
- 编译时检查工具名称
- 避免字符串拼写错误
- IDE 自动完成支持

### 2. 元数据丰富
- 统一的图标和显示名称
- 分类管理
- 渲染信息集中管理

### 3. 可维护性
- 单一真实来源
- 易于添加新工具
- 清晰的工具组织

### 4. 向后兼容
- 现有代码无需立即修改
- 渐进式迁移
- 平滑过渡

## 测试验证

✅ 编译成功 - 所有现有代码正常编译  
✅ 功能测试 - CodingAgent 正常工作  
✅ 工具显示 - 正确显示工具信息和图标  
✅ 向后兼容 - 旧代码继续工作  

## 下一步

1. 逐步迁移现有代码使用新的 `ToolType` 系统
2. 添加更多工具类型和分类
3. 利用分类信息改进工具管理
4. 在 UI 中使用新的图标和显示名称
