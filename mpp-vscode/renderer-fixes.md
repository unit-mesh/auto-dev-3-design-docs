# mpp-vscode Renderer 问题修复

## 修复日期
2025-12-04

## 问题描述

1. **显示 "AutoDev" 标题问题** - AI 返回的结果显示了不必要的 "AutoDev" 标题
2. **ToolCall 显示两次问题** - 工具调用在界面上重复显示两次，第一次显示无用且没有细节
3. **ToolCall 展开后的问题** - 展开后不需要 "Rerun" 按钮，且 output 的主题样式不对

## 根本原因

1. **AutoDev 标题**: 在 `Timeline.tsx` 中，流式渲染和消息渲染都显示了 header，包含角色名称
2. **重复显示**: 
   - 第一次显示：通过 `renderToolCall` 在 timeline 中创建 `tool_call` 类型的项，由 `ToolCallRenderer` 渲染
   - 第二次显示：LLM 响应中包含 `devin` 代码块，被 `DevInRenderer` 在消息内容中再次渲染
3. **Rerun 按钮和主题**: `ToolCallRenderer` 包含了不需要的 rerun 功能，且 output 使用了终端主题而非编辑器主题

## 解决方案

### 1. 移除 "AutoDev" 标题

**文件**: `mpp-vscode/webview/src/components/Timeline.tsx`

- 从流式内容渲染中移除了 `timeline-item-header` 部分
- 从 `MessageItemRenderer` 中移除了 assistant 和 system 角色的 header 显示
- 只保留用户消息的 "You" 标题

**修改前**:
```typescript
<div className="timeline-item-header">
  <span className="timeline-role">
    {isUser ? 'You' : isSystem ? 'System' : 'AutoDev'}
  </span>
  ...
</div>
```

**修改后**:
```typescript
{isUser && (
  <div className="timeline-item-header">
    <span className="timeline-role">You</span>
  </div>
)}
```

### 2. 禁用 DevIn 块渲染以避免重复

**文件**: `mpp-vscode/webview/src/components/sketch/SketchRenderer.tsx`

- 在 `SketchRenderer` 中禁用了 `devin` 语言块的渲染
- 移除了 `DevInRenderer` 的 import
- 工具调用现在只通过 `ToolCallRenderer` 在 timeline 中显示一次

**修改前**:
```typescript
case 'devin':
  return (
    <DevInRenderer
      content={block.text}
      isComplete={isComplete}
      onAction={onAction}
    />
  );
```

**修改后**:
```typescript
case 'devin':
  // DevIn blocks are handled by ToolCallRenderer in timeline
  // Don't render them here to avoid duplication
  return null;
```

### 3. 移除 Rerun 按钮并修复 Output 主题

**文件**: `mpp-vscode/webview/src/components/sketch/ToolCallRenderer.tsx`

- 移除了 `handleRerun` 函数和 rerun 按钮
- 移除了未使用的 `onAction` 参数

**文件**: `mpp-vscode/webview/src/components/sketch/ToolCallRenderer.css`

- 将 output 的 `background-color` 从 `--vscode-terminal-background` 改为 `--vscode-editor-background`
- 将 output 的 `color` 从 `--vscode-terminal-foreground` 改为 `--vscode-editor-foreground`
- 添加了边框以提供更好的视觉分隔

**修改前**:
```css
.tool-call-output pre {
  background-color: var(--vscode-terminal-background, #1e1e1e);
  color: var(--vscode-terminal-foreground, #cccccc);
  ...
}
```

**修改后**:
```css
.tool-call-output pre {
  background-color: var(--vscode-editor-background);
  color: var(--vscode-editor-foreground);
  border: 1px solid var(--vscode-panel-border);
  ...
}
```

## 影响范围

### 修改的文件
1. `mpp-vscode/webview/src/components/Timeline.tsx`
2. `mpp-vscode/webview/src/components/sketch/SketchRenderer.tsx`
3. `mpp-vscode/webview/src/components/sketch/ToolCallRenderer.tsx`
4. `mpp-vscode/webview/src/components/sketch/ToolCallRenderer.css`

### 构建验证
- ✅ TypeScript 编译通过
- ✅ Vite 构建成功
- ✅ 无 linter 错误

## 测试建议

1. **测试场景 1**: 发送消息并观察 AI 响应
   - 验证：不应该显示 "AutoDev" 标题
   - 只有用户消息应该显示 "You" 标题

2. **测试场景 2**: 触发工具调用（如 read-file）
   - 验证：工具调用应该只显示一次
   - 应该显示工具名称、参数和状态图标

3. **测试场景 3**: 展开工具调用详情
   - 验证：不应该有 "Rerun" 按钮
   - output 应该使用编辑器主题（与编辑器背景色一致）

## 架构说明

### Timeline 架构
mpp-vscode 使用 Timeline 架构来管理消息流：

```
Timeline
├── MessageTimelineItem (用户/助手消息)
│   └── SketchRenderer (渲染 markdown、code、diff 等)
├── ToolCallTimelineItem (工具调用)
│   └── ToolCallRenderer (显示工具名称、参数、结果)
├── TerminalTimelineItem (终端输出)
└── ErrorTimelineItem (错误消息)
```

### 工具调用流程
1. LLM 返回包含工具调用的响应
2. `CodingAgentExecutor` 解析工具调用
3. `renderToolCall` 被调用，发送 `toolCall` 消息
4. Webview 接收消息，创建 `ToolCallTimelineItem`
5. `ToolCallRenderer` 渲染工具调用
6. 工具执行完成后，`renderToolResult` 更新同一个 item

### DevIn 块处理
- DevIn 是一种自定义语言格式，用于表示工具调用
- 之前在 LLM 响应中渲染，导致重复显示
- 现在禁用了在 SketchRenderer 中的渲染
- 工具调用信息通过 Timeline 的 ToolCallRenderer 统一展示

## 相关文档
- [mpp-vscode Migration Analysis](../mpp-vscode-migration-analysis.md)
- [Timeline Types](../../mpp-vscode/webview/src/types/timeline.ts)

