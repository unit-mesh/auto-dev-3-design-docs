# MPP-UI 浏览器支持实施指南

## 概述

让 mpp-ui 支持浏览器运行需要解决两个核心问题：
1. **Node.js API 依赖** - fs, path, os, child_process 在浏览器中不可用
2. **打包体积优化** - 减少不必要的依赖

## 方案对比

### 方案 1: 快速方案（Webpack Fallbacks）⚡

**优点:**
- ✅ 改动最小，只需配置 webpack
- ✅ 可以快速验证

**缺点:**
- ⚠️ 文件系统操作无法工作
- ⚠️ 配置管理功能受限
- ⚠️ 打包体积较大（~5MB）

**适用场景:** 快速原型，只使用不依赖文件系统的功能

### 方案 2: 平台抽象层（推荐）🎯

**优点:**
- ✅ 完整功能支持
- ✅ 配置可持久化（LocalStorage）
- ✅ 更好的代码组织
- ✅ 可以进一步优化体积

**缺点:**
- ⚠️ 需要重构现有代码
- ⚠️ 开发工作量较大

**适用场景:** 生产环境，需要完整功能

### 方案 3: 独立 Web 模块（长期方案）🏗️

**优点:**
- ✅ 专为浏览器设计
- ✅ 体积最小
- ✅ 性能最优
- ✅ 易于维护

**缺点:**
- ⚠️ 需要创建新模块
- ⚠️ 工作量最大

**适用场景:** 长期维护，独立的 Web 应用

## 实施步骤

### 步骤 1: 启用浏览器构建（快速方案）

#### 1.1 安装浏览器 polyfills

```bash
cd /Volumes/source/ai/autocrud/mpp-ui

# 安装必要的 polyfills
npm install --save-dev \
  path-browserify \
  os-browserify \
  crypto-browserify \
  stream-browserify \
  buffer \
  process \
  util \
  assert \
  url
```

#### 1.2 启用浏览器构建

修改 `mpp-ui/build.gradle.kts`:

```kotlin
js(IR) {
    browser {
        commonWebpackConfig {
            outputFileName = "mpp-ui.js"
        }
    }
    nodejs {
        // Configure Node.js target for CLI
    }
    binaries.executable()
}
```

#### 1.3 验证构建

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-ui:jsBrowserProductionWebpack
```

**预期结果:**
- ✅ 编译成功（2-3分钟，启用缓存后更快）
- ⚠️ 文件系统操作会失败
- 输出文件: `mpp-ui/build/kotlin-webpack/js/productionExecutable/mpp-ui.js`

#### 1.4 测试浏览器版本

创建测试 HTML:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AutoDev Browser Test</title>
</head>
<body>
    <h1>AutoDev Browser Test</h1>
    <div id="root"></div>
    <script src="mpp-ui.js"></script>
    <script>
        // Test basic functionality
        console.log('AutoDev loaded:', typeof window['mpp-ui']);
    </script>
</body>
</html>
```

### 步骤 2: 实施平台抽象层（完整方案）

#### 2.1 使用提供的平台抽象

已创建的文件:
- `src/jsMain/typescript/platform/browser-fs.ts` - 浏览器文件系统模拟
- `src/jsMain/typescript/platform/index.ts` - 平台检测和导出

#### 2.2 重构现有代码

需要修改以下文件，将 Node.js 导入替换为平台抽象:

```typescript
// 原代码
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// 修改为
import { fs, path, os } from '../platform/index.js';
```

**需要修改的文件列表:**
1. `src/jsMain/typescript/i18n/index.ts`
2. `src/jsMain/typescript/config/ConfigManager.ts`
3. `src/jsMain/typescript/utils/domainDictUtils.ts`
4. `src/jsMain/typescript/modes/AgentMode.ts`
5. `src/jsMain/typescript/index.tsx`

#### 2.3 修改示例 - ConfigManager

```typescript
// Before
import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';

// After
import { fs: fsSync, path, os, fsPromises as fs } from '../platform/index.js';
```

#### 2.4 处理不支持的功能

某些功能在浏览器中无法实现:

```typescript
import { isBrowser, isNodeJs } from '../platform/index.js';

// 条件功能
if (isNodeJs) {
    // 只在 Node.js 中执行
    const { exec } = require('child_process');
    exec('some command');
} else {
    // 浏览器中提示用户
    console.warn('Command execution not supported in browser');
}
```

### 步骤 3: 体积优化

#### 3.1 配置 Tree-shaking

已创建 `webpack.config.d/browser-support.js`，包含:
- ✅ Tree-shaking 配置
- ✅ Code splitting
- ✅ Vendor bundles 分离

#### 3.2 分析打包体积

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-ui:jsBrowserProductionWebpack

# 分析输出
ls -lh mpp-ui/build/kotlin-webpack/js/productionExecutable/
```

#### 3.3 排除不必要的依赖

在 `webpack.config.d/browser-support.js` 中配置 externals:

```javascript
config.externals = {
    // 排除大型依赖
    'highlight.js': 'hljs',  // 使用 CDN
    'yaml': 'jsyaml',        // 使用 CDN
};
```

#### 3.4 使用 CDN

在 HTML 中引入大型库:

```html
<script src="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/lib/core.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js"></script>
<script src="mpp-ui.js"></script>
```

## 预期体积

| 方案 | 初始体积 | 优化后 | Gzip |
|-----|---------|--------|------|
| 快速方案 | ~5MB | ~3MB | ~800KB |
| 平台抽象 | ~4MB | ~2MB | ~600KB |
| 独立 Web | ~1MB | ~500KB | ~150KB |

## 功能支持对比

| 功能 | Node.js | 快速方案 | 平台抽象 | 独立 Web |
|-----|---------|---------|---------|----------|
| 配置管理 | ✅ | ⚠️ | ✅ | ✅ |
| 文件操作 | ✅ | ❌ | ✅* | ❌ |
| 语言切换 | ✅ | ⚠️ | ✅ | ✅ |
| Agent 模式 | ✅ | ⚠️ | ✅ | ✅ |
| Chat 模式 | ✅ | ✅ | ✅ | ✅ |
| 命令执行 | ✅ | ❌ | ❌ | ❌ |

*使用 LocalStorage 模拟

## 实施建议

### 短期（1-2天）- 快速方案

```bash
# 1. 安装依赖
cd mpp-ui
npm install --save-dev path-browserify os-browserify \
  crypto-browserify stream-browserify buffer process util assert url

# 2. 启用浏览器构建
# 编辑 build.gradle.kts 取消 browser 配置的注释

# 3. 配置 webpack
# webpack.config.d/browser-support.js 已创建

# 4. 构建测试
cd ..
./gradlew :mpp-ui:jsBrowserProductionWebpack
```

**优点:** 快速验证可行性
**缺点:** 功能受限

### 中期（1周）- 平台抽象

```bash
# 1. 应用快速方案的所有步骤

# 2. 重构代码使用平台抽象
# 修改 5 个核心文件的导入语句

# 3. 测试所有功能
npm test

# 4. 优化打包配置
```

**优点:** 完整功能
**缺点:** 需要重构

### 长期（2-4周）- 独立 Web 模块

```bash
# 1. 创建新模块 mpp-web
mkdir ../mpp-web

# 2. 设计浏览器专用架构
# - 使用 React/Vue
# - 依赖 mpp-core
# - 浏览器原生 API

# 3. 独立开发和维护
```

**优点:** 最佳性能和体验
**缺点:** 工作量最大

## 立即可用的代码

### 浏览器文件系统适配器

已创建:
- `src/jsMain/typescript/platform/browser-fs.ts`
- `src/jsMain/typescript/platform/index.ts`

### Webpack 配置

已创建:
- `webpack.config.d/browser-support.js`

### 依赖清单

已创建:
- `package-browser.json`

## 下一步行动

### 选项 A: 快速验证（推荐先尝试）

```bash
# 1. 合并浏览器依赖到 package.json
cd mpp-ui
cat package-browser.json >> package.json  # 手动合并

# 2. 安装依赖
npm install

# 3. 启用浏览器构建
# 编辑 build.gradle.kts

# 4. 测试编译
cd ..
./gradlew :mpp-ui:jsBrowserProductionWebpack
```

### 选项 B: 完整实施（生产就绪）

1. 执行选项 A
2. 重构 5 个核心文件使用平台抽象
3. 添加完整的浏览器测试
4. 优化打包配置
5. 部署测试

### 选项 C: 独立开发（最佳方案）

1. 创建 `mpp-web` 模块
2. 只依赖 `mpp-core`
3. 使用浏览器友好的框架
4. 独立维护

## 总结

- **最快方案**: 选项 A（1-2小时）
- **功能完整**: 选项 B（2-3天）
- **最佳长期**: 选项 C（2-4周）

**我的建议:**
1. 先用选项 A 验证可行性和性能
2. 如果满足需求，考虑选项 B 完善功能
3. 如果有长期规划，投资选项 C

## 需要帮助？

如果需要实施任何方案，我可以帮你：
1. ✅ 安装和配置依赖
2. ✅ 重构代码使用平台抽象
3. ✅ 优化打包配置
4. ✅ 创建测试和部署方案

