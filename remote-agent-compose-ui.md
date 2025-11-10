# Remote Agent Integration for Compose UI

## 概述

为 AutoDev Compose UI 添加了远程 AI Agent 支持，允许用户在本地 Agent 和远程 mpp-server 之间切换。

## 实现的功能

### 1. 远程服务器配置对话框 (`RemoteServerConfigDialog.kt`)

创建了一个新的配置对话框，允许用户：
- **输入远程 mpp-server 的 URL**：支持 http/https 协议
- **选择 LLM 配置来源**：使用服务器配置或本地配置
- **高级选项**：可选的 Git URL 预设
- **URL 格式验证**：自动检查 URL 合法性

**位置**: `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/config/RemoteServerConfigDialog.kt`

#### 高级功能

点击 "Show Advanced" 可以预设一个 Git URL，连接后会自动填充到项目选择器中。

### 2. 本地/远程模式切换

在 `AutoDevApp.kt` 中添加了：
- `useRemoteMode` 状态：追踪当前是本地还是远程模式
- `remoteServerConfig` 状态：保存远程服务器配置
- `selectedProjectId` 状态：保存选中的项目 ID
- 根据模式渲染 `AgentChatInterface` 或 `RemoteAgentChatInterface`

### 3. TopBar 集成

在所有 TopBar 组件中添加了远程模式切换：

#### TopBarMenuDesktop（桌面端）
- 添加了远程模式切换按钮（云图标/电脑图标）
- 点击切换本地/远程模式
- 远程模式时显示蓝色云图标，本地模式显示灰色电脑图标

#### TopBarMenuMobile（移动端）
- 在下拉菜单中添加 "Agent Location" 选项
- 显示当前模式（Local / Remote Server）
- 点击可配置远程服务器或切换回本地模式

### 4. 图标支持

在 `AutoDevComposeIcons.kt` 中添加：
- `Computer` 图标：表示本地模式

已有图标：
- `Cloud` 图标：表示远程模式

## 使用流程

### 配置远程模式

1. 在 Agent 模式下点击远程模式按钮（电脑图标）
2. 在弹出的配置对话框中：
   - 输入服务器 URL（例如：`http://localhost:8080`）
   - 选择是否使用服务器的 LLM 配置
   - 点击 "Connect" 连接
3. 连接成功后，界面会切换到 `RemoteAgentChatInterface`

### 使用远程 Agent

远程模式启用后，会显示灵活的项目选择器，支持三种方式：

#### 方式 1：从服务器选择项目
1. 点击项目选择器的下拉箭头
2. 从列表中选择一个已有项目
3. 输入任务描述并提交

#### 方式 2：手动输入项目 ID
1. 点击项目选择器旁边的代码图标（`<>`）
2. 输入项目 ID（例如：`autocrud`）
3. 点击确认图标（✓）

#### 方式 3：直接输入 Git URL
1. 点击项目选择器旁边的代码图标（`<>`）
2. 粘贴完整的 Git URL（例如：`https://github.com/user/repo.git`）
3. 点击确认图标（✓）
4. 服务器会自动克隆仓库并执行任务

所有方式下，任务执行结果都会流式返回到 UI。

### 切换回本地模式

点击云图标即可切换回本地模式。

## 技术细节

### 组件层次结构

```
AutoDevApp
├── TopBarMenu (显示模式切换按钮)
├── RemoteAgentChatInterface (远程模式)
│   ├── RemoteCodingAgentViewModel
│   │   ├── RemoteAgentClient (HTTP 客户端)
│   │   └── ComposeRenderer (UI 渲染)
│   ├── ProjectSelector (项目选择器)
│   ├── AgentMessageList (消息列表)
│   └── DevInEditorInput (输入框)
└── AgentChatInterface (本地模式)
    └── CodingAgentViewModel
```

### 状态管理

- `useRemoteMode`: Boolean - 是否使用远程模式
- `remoteServerConfig`: RemoteServerConfig - 远程服务器配置
  - `serverUrl`: String - 服务器 URL（必填）
  - `useServerConfig`: Boolean - 是否使用服务器配置
  - `selectedProjectId`: String - 当前项目 ID 或 Git URL
  - `defaultGitUrl`: String - 预设的 Git URL（可选）

### 连接检查

`RemoteCodingAgentViewModel` 在初始化时会：
1. 检查服务器健康状态
2. 获取可用项目列表
3. 显示连接状态

如果连接失败，会显示错误界面并提供重试选项。

## 参考实现

CLI 版本的远程 Agent 实现：
- **文件**: `mpp-ui/src/jsMain/typescript/index.tsx`
- **函数**: `runServerAgent()`
- **说明**: Compose UI 的远程模式与 CLI 的 `server` 命令功能相同

## 测试

### 手动测试步骤

1. **启动 mpp-server**:
   ```bash
   cd mpp-server
   ./gradlew run
   ```

2. **启动 Compose UI**:
   ```bash
   cd mpp-ui
   ./gradlew :mpp-ui:run
   ```

3. **配置远程模式**:
   - 点击远程模式按钮
   - 输入 `http://localhost:8080`
   - 测试连接

4. **选择项目并执行任务**:
   - 从下拉菜单选择项目
   - 输入任务描述
   - 观察流式输出

### CLI 测试（参考）

```bash
# 使用本地配置连接远程服务器
autodev server -p autocrud -t "Fix the bug in UserService"

# 使用服务器配置
autodev server -p autocrud -t "Add logging" --use-server-config

# 使用 Git URL 克隆并执行
autodev server -p https://github.com/user/repo -t "Analyze code"
```

## 文件变更清单

### 新增文件
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/config/RemoteServerConfigDialog.kt`

### 修改文件
- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/AutoDevApp.kt`
  - 添加远程模式状态和配置
  - 添加 RemoteAgentChatInterface 渲染逻辑
  - 添加远程配置对话框

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenu.kt`
  - 添加 `useRemoteMode`, `onToggleRemoteMode`, `onShowRemoteConfig` 参数

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenuDesktop.kt`
  - 添加远程模式切换按钮
  - 根据模式显示不同图标

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/chat/TopBarMenuMobile.kt`
  - 添加 "Agent Location" 菜单项
  - 显示当前模式并允许切换

- `mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/icons/AutoDevComposeIcons.kt`
  - 添加 `Computer` 图标

## 最新改进 (v2)

### ✅ 已实现

1. **Git URL 输入支持**: 项目选择器现在支持手动输入 Git URL
2. **高级配置选项**: 配置对话框支持预设 Git URL
3. **灵活的项目选择**: 三种方式选择项目（列表、ID、Git URL）
4. **更好的用户提示**: 详细的使用说明和状态提示

### 🔜 后续改进建议

1. **配置持久化**: 将远程服务器配置保存到 `config.yaml`
2. **多服务器支持**: 允许配置多个远程服务器并快速切换
3. **连接状态指示**: 在 UI 上显示更详细的连接状态和延迟
4. **离线缓存**: 缓存项目列表以支持离线浏览
5. **错误处理增强**: 更详细的错误信息和恢复建议
6. **性能监控**: 显示任务执行时间和资源使用情况
7. **克隆进度显示**: 显示 Git clone 的详细进度
8. **项目历史记录**: 记住最近使用的项目

## 相关文档

- [Remote Agent 实现总结](./remote-agent-implementation-summary.md)
- [Remote Agent 使用指南](./remote-agent-usage.md)
- [服务器端实现](./server/SUMMARY.md)

