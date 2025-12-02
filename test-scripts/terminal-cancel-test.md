# Terminal Cancel 功能测试指南

## 测试环境

- **IDEA 插件**: mpp-idea
- **测试项目**: /Users/phodal/IdeaProjects/untitled (Spring Boot 项目)
- **功能**: Terminal Cancel with proper AI feedback

## 测试步骤

### 1. 启动 IDEA 插件

```bash
cd /Volumes/source/ai/autocrud/mpp-idea
../gradlew runIde
```

### 2. 在 IDEA 中打开测试项目

打开项目：`/Users/phodal/IdeaProjects/untitled`

### 3. 打开 AutoDev Tool Window

- 点击右侧的 AutoDev 工具窗口
- 或使用快捷键打开

### 4. 执行长时间运行的命令

在 AutoDev 聊天框中输入以下任务：

```
请运行 Spring Boot 项目：./gradlew bootRun
```

或者直接使用 DevIns 命令：

```devins
/run ./gradlew bootRun
```

### 5. 等待命令开始执行

观察终端输出，等待看到类似：
```
> Task :bootRun
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::
```

### 6. 点击 Cancel 按钮

在终端输出区域找到 Cancel 按钮并点击

### 7. 验证预期行为

#### ✅ 预期结果：

1. **进程被终止**
   - Spring Boot 应用停止运行
   - 终端显示进程已终止

2. **AI 收到清晰的取消消息**
   - 应该看到类似：
     ```
     ⚠️ Command cancelled by user
     
     Command: ./gradlew bootRun
     Output before cancellation:
     [显示取消前的所有输出]
     ```

3. **AI 收到完整的输出日志**
   - 消息中应包含 Spring Boot 启动时的所有输出
   - 包括 Spring Boot banner、日志等

4. **元数据正确**
   - `exit_code: 137`
   - `cancelled: true`

5. **没有重复的错误消息**
   - 不应该看到两条关于 exit code 137 的消息
   - 只有一条清晰的用户取消消息

#### ❌ 错误的行为（修复前）：

1. AI 只收到：`Command failed with exit code: 137`
2. AI 看不到取消前的输出日志
3. AI 不知道是用户主动取消的
4. 可能出现重复的错误消息

## 测试场景

### 场景 1: 快速取消
1. 运行 `./gradlew bootRun`
2. 在 Spring Boot 启动过程中（看到 banner 后）立即点击 Cancel
3. 验证 AI 收到的消息包含 Spring Boot banner

### 场景 2: 延迟取消
1. 运行 `./gradlew bootRun`
2. 等待 Spring Boot 完全启动（看到 "Started Application"）
3. 点击 Cancel
4. 验证 AI 收到的消息包含完整的启动日志

### 场景 3: 其他命令
测试其他长时间运行的命令：

```devins
/run sleep 30
```

```devins
/run ./gradlew build
```

## 验证清单

- [ ] 进程被正确终止（exit code 137）
- [ ] AI 收到明确的"用户取消"消息
- [ ] AI 收到取消前的完整输出日志
- [ ] 没有重复的错误消息
- [ ] 元数据包含 `cancelled: true`
- [ ] 错误消息友好且易于理解

## 调试

如果遇到问题，检查日志：

```bash
tail -f ~/.autodev/logs/autodev-app.log
```

查找以下关键日志：
- `Session was cancelled by user`
- `markCancelledByUser`
- `handleProcessCancel`

## 代码位置

相关代码文件：
- `mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/toolwindow/IdeaAgentViewModel.kt`
- `mpp-idea/src/main/kotlin/cc/unitmesh/devins/idea/renderer/JewelRenderer.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/orchestrator/ToolOrchestrator.kt`
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/shell/ShellSessionManager.kt`

