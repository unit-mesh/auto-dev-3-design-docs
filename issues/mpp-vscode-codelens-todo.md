# mpp-vscode CodeLens 功能待完成清单

## 已完成 ✅

### CodeLens Provider
- [x] Tree-sitter 代码解析 (TypeScript, JavaScript, Python, Java, Kotlin, Go, Rust)
- [x] 正则表达式 fallback
- [x] 类/方法/函数识别
- [x] CodeLens 显示

### Auto Actions
- [x] AutoComment - 生成文档注释
- [x] AutoTest - 生成单元测试  
- [x] AutoMethod - 生成方法实现
- [x] Diff 预览和应用

### 提示词模板
- [x] auto-doc 模板
- [x] test-gen 模板
- [x] auto-method 模板

---

## 待完成 🔲

### P0 - 核心功能

#### InlineCompletion (代码补全)
- [ ] 实现 `vscode.InlineCompletionItemProvider`
- [ ] FIM (Fill-in-the-Middle) 支持
- [ ] 触发条件配置
- [ ] 性能优化 (debounce, cache)

参考文件:
- `Samples/autodev-vscode/src/action/providers/AutoDevCodeInlineCompletionProvider.ts`
- `Samples/autodev-vscode/src/code-context/chunk/ChunkItem.ts`

### P1 - 重要功能

#### QuickFix Provider
- [ ] 实现 `vscode.CodeActionProvider`
- [ ] 错误诊断分析
- [ ] 修复建议生成
- [ ] 一键应用修复

参考文件:
- `Samples/autodev-vscode/src/action/providers/AutoDevQuickFixProvider.ts`

#### Custom Actions
- [ ] 自定义操作配置
- [ ] Frontmatter 解析
- [ ] 变量替换
- [ ] 操作执行

参考文件:
- `Samples/autodev-vscode/src/prompt-manage/custom-action/CustomActionContextBuilder.ts`
- `Samples/autodev-vscode/src/prompt-manage/custom-action/CustomActionExecutor.ts`

### P2 - 增强功能

#### Git 集成
- [ ] 提交消息生成
- [ ] Diff 分析
- [ ] Issue 关联

参考文件:
- `Samples/autodev-vscode/src/action/devops/CommitMessageGenAction.ts`

#### Terminal 集成
- [ ] 错误捕获
- [ ] 错误解释
- [ ] 修复建议

参考文件:
- `Samples/autodev-vscode/src/action/terminal/TerminalService.ts`

#### Rename 建议
- [ ] 变量重命名
- [ ] 函数重命名
- [ ] 批量重命名

参考文件:
- `Samples/autodev-vscode/src/action/refactor/RenameLookupExecutor.ts`

#### 国际化
- [ ] 中文支持
- [ ] 英文支持
- [ ] 语言切换

参考文件:
- `Samples/autodev-vscode/l10n/`

---

## 技术债务

- [ ] 添加单元测试
- [ ] 添加集成测试
- [ ] 性能优化
- [ ] 错误处理完善
- [ ] 日志记录完善

---

## 相关文件

- `mpp-vscode/src/providers/codelens-provider.ts` - CodeLens Provider
- `mpp-vscode/src/providers/code-element-parser.ts` - 代码解析器
- `mpp-vscode/src/actions/auto-actions.ts` - Auto Actions
- `mpp-vscode/src/prompts/prompt-templates.ts` - 提示词模板
- `mpp-vscode/src/commands/codelens-commands.ts` - CodeLens 命令

---

**创建日期**: 2025-12-04

