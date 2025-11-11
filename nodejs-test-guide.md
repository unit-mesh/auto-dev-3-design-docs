# 在 Node.js 中测试 MPP-Core

## ✅ 测试结果

成功在 Node.js 环境中运行 AutoDev MPP-Core！

### 测试输出

```
=== AutoDev MPP-Core Test (JS) ===

📱 Platform Information:
  Name: JavaScript
  Is JVM: false
  Is JS: true
  Is WASM: false
  Is Android: false
  Is iOS: false

🖥️  System Information:
  OS Name: darwin
  OS Info: Node.js v24.4.1 on darwin (arm64)
  OS Version: 25.1.0
  Default Shell: /bin/zsh

📂 Paths:
  User Home: /Users/phodal
  Log Directory: /Users/phodal/.autodev/logs

⏰ Time:
  Current Timestamp: 2025-11-11T12:22:46.312Z

✅ FileSystem module accessible

=== Test Complete ===
```

## 🚀 如何测试

### 1. 构建 JS Package

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:assembleJsPackage
```

### 2. 运行测试脚本

```bash
node docs/test-scripts/test-mpp-core-node.mjs
```

## 📦 构建产物

- **位置**: `mpp-core/build/packages/js/`
- **主文件**: `autodev-mpp-core.js`
- **类型定义**: `autodev-mpp-core.d.ts`
- **配置**: `package.json`

## 💻 在 Node.js 项目中使用

### 方法 1: 直接导入（ESM）

```javascript
import('../../mpp-core/build/packages/js/autodev-mpp-core.js')
  .then(module => {
    const exports = module.default || module['module.exports'];
    
    // 使用 Platform API
    const Platform = exports.cc.unitmesh.agent.JsPlatform;
    console.log('Platform Name:', Platform.name);
    console.log('OS Info:', Platform.getOSInfo());
    console.log('User Home:', Platform.getUserHomeDir());
  });
```

### 方法 2: 作为 NPM 包使用

1. 将 `mpp-core/build/packages/js/` 目录发布到 NPM（或使用本地链接）

```bash
cd mpp-core/build/packages/js
npm link

# 在你的项目中
npm link @autodev/mpp-core
```

2. 在代码中使用：

```javascript
import autodev from '@autodev/mpp-core';

const Platform = autodev.cc.unitmesh.agent.JsPlatform;
console.log(Platform.getOSInfo());
```

## 🔧 API 示例

### Platform 信息

```javascript
const Platform = exports.cc.unitmesh.agent.JsPlatform;

// 平台检测
console.log('Running on:', Platform.name);  // "JavaScript"
console.log('Is Node.js:', Platform.isJs);  // true

// 系统信息
console.log('OS:', Platform.getOSName());
console.log('Shell:', Platform.getDefaultShell());

// 路径
console.log('Home:', Platform.getUserHomeDir());
console.log('Logs:', Platform.getLogDir());

// 时间
console.log('Now:', Platform.getCurrentTimestamp());
```

### 文件系统

```javascript
const FileSystem = exports.cc.unitmesh.devins.filesystem.DefaultFileSystem;

// 创建文件系统实例
const fs = new FileSystem('/path/to/project');

// 检查文件是否存在
const exists = fs.exists('src/index.js');

// 读取文件内容
const content = fs.readFile('README.md');
```

### CodingAgent

```javascript
const CodingAgent = exports.cc.unitmesh.agent.JsCodingAgent;
const AgentContext = exports.cc.unitmesh.agent.JsCodingAgentContext;

// 创建 Agent 上下文
const context = new AgentContext(
  /* projectRoot */ '/path/to/project',
  /* toolRegistry */ toolRegistry,
  /* llmProvider */ llmProvider
);

// 创建并使用 Agent
const agent = new CodingAgent(context);
```

## 📋 可用的 JS 导出

mpp-core 导出了以下模块到 JavaScript：

### 核心模块
- `cc.unitmesh.agent.JsPlatform` - 平台信息
- `cc.unitmesh.agent.JsCodingAgent` - Coding Agent
- `cc.unitmesh.agent.JsCodingAgentContext` - Agent 上下文
- `cc.unitmesh.agent.JsCodingAgentPromptRenderer` - Prompt 渲染器

### 文件系统
- `cc.unitmesh.devins.filesystem.DefaultFileSystem` - 文件系统操作

### UI 系统
- `cc.unitmesh.agent.ui.*` - 颜色系统和 UI 工具

### 配置
- `cc.unitmesh.agent.config.*` - 工具配置

### LLM
- `cc.unitmesh.llm.*` - LLM 提供者接口

## 🧪 测试脚本

项目包含以下测试脚本：

1. **test-mpp-core-node.mjs** - 完整功能测试
2. **inspect-module.mjs** - 模块结构检查
3. **inspect-platform.mjs** - Platform API 检查

运行任意测试：
```bash
node docs/test-scripts/<script-name>
```

## ⚠️ 注意事项

### Module System
- 使用 ESM (ES Modules) 导入
- 模块通过 `module.default` 或 `module['module.exports']` 访问
- 命名空间结构：`cc.unitmesh.agent.*`

### TypeScript 支持
- 已生成 `.d.ts` 类型定义文件
- 可在 TypeScript 项目中使用类型提示

### 依赖项
检查 `package.json` 中的依赖：
- `@js-joda/core` - 日期时间处理
- `format-util` - 格式化工具
- `ws` - WebSocket 支持

## 🔗 相关文档

- [MPP-Core README](../../mpp-core/README.md)
- [WASM 构建指南](./wasm-build-guide.md)
- [Kotlin/JS 文档](https://kotlinlang.org/docs/js-overview.html)

## 📝 已知问题

1. **WASM Package 构建**
   - `assembleWasmJsPackage` 任务目前有配置问题
   - WASM 可以编译为 `.klib`，但不能直接打包为 npm 包
   - 建议先使用 JS 构建进行测试

2. **导出注解**
   - 需要在 jsMain 中创建 `@JsExport` 包装类
   - 不是所有 commonMain 的类都自动导出到 JS

3. **性能考虑**
   - 大型操作可能需要异步处理
   - 建议使用 Kotlin 协程（在 JS 中会编译为 Promise）
