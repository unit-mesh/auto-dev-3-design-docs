# mpp-web 浏览器集成解决方案

## 问题诊断

原始错误：`Uncaught ReferenceError: module is not defined`

**根本原因：** Kotlin/JS 编译器生成的是 UMD（Universal Module Definition）格式代码，使用 `module.exports` 和 `require()`，这些是 Node.js/CommonJS 的特性，在浏览器中不可用。

## 最终解决方案

### 1. 使用本地 npm 包依赖（✅ 推荐）

将 mpp-core 作为本地 file: 依赖引入，让 Vite 自动处理模块格式转换。

**mpp-web/package.json:**
```json
{
  "dependencies": {
    "@autodev/mpp-core": "file:../mpp-core/build/packages/js"
  }
}
```

**优点：**
- Vite 的 Rollup 插件会自动将 UMD/CommonJS 转换为 ESM
- 不需要手动编写 shim 或 polyfill（除了 Node.js 特定模块）
- 维护成本低，升级依赖时不易出错
- 与标准 npm 工作流一致

### 2. Node.js 模块 Polyfill

Kotlin/JS 的依赖（如 ktor-client）会尝试导入 Node.js 专用模块（如 `ws`），需要提供浏览器 polyfill。

**mpp-web/vite.config.ts:**
```typescript
resolve: {
  alias: {
    'ws': path.resolve(__dirname, 'src/polyfills/ws-polyfill.ts'),
  },
}
```

**mpp-web/src/polyfills/ws-polyfill.ts:**
```typescript
// 在浏览器中使用原生 WebSocket
export default typeof window !== 'undefined' ? window.WebSocket : class {};
export const WebSocket = typeof window !== 'undefined' ? window.WebSocket : class {};
```

### 3. Kotlin/JS 配置（mpp-core）

保持 UMD 格式以兼容 Node.js (mpp-ui) 和浏览器（mpp-web）：

**mpp-core/build.gradle.kts:**
```kotlin
js(IR) {
    moduleName = "autodev-mpp-core"
    browser()
    nodejs()
    binaries.library()
    generateTypeScriptDefinitions()

    compilations.all {
        kotlinOptions {
            moduleKind = "umd"  // UMD 最兼容
            sourceMap = true
            sourceMapEmbedSources = "always"
        }
    }
}
```

## 验证结果

### ✅ 测试通过

使用 Playwright MCP 进行的浏览器测试：

1. **页面加载成功**
   - URL: http://localhost:3000
   - 显示 "✅ mpp-core loaded successfully"

2. **无 JavaScript 错误**
   - 唯一的 404 是 favicon.ico（无关紧要）
   - mpp-core 模块正确加载
   - 所有功能正常工作

3. **功能测试**
   - 输入测试消息："Hello, testing mpp-core integration!"
   - 收到正确回应："Echo: Hello, testing mpp-core integration!"

4. **控制台日志**
   ```
   [LOG] mpp-core loaded: {cc: Object, kotlin: Object, io: Object, default: Object}
   ```

### 📊 性能指标

- **构建时间：** ~880ms (vite build)
- **打包大小：** 722.54 kB (gzip: 205.09 kB)
- **开发服务器启动：** ~129ms

## 构建和运行

```bash
# 1. 构建 mpp-core
./gradlew :mpp-core:assembleJsPackage

# 2. 安装依赖（首次或 mpp-core 更新后）
cd mpp-web && npm install

# 3. 开发模式
npm run dev

# 4. 生产构建
npm run build
```

## 架构优势

```
mpp-web (浏览器)
  ├── React + TypeScript (DOM)
  ├── Vite (dev + bundler)
  │   └── 自动处理 UMD → ESM 转换
  └── @autodev/mpp-core (file: 依赖)
       ├── autodev-mpp-core.js (UMD)
       └── kotlin-stdlib + 依赖

mpp-ui (Node.js CLI)
  ├── React + Ink (TUI)
  ├── TypeScript
  └── @autodev/mpp-core (同一个包)
       └── UMD 在 Node.js 中原生支持
```

## 替代方案对比

| 方案 | 优点 | 缺点 | 采用 |
|------|------|------|------|
| **file: 依赖 + Vite 转换** | 自动化、标准、易维护 | 需要 polyfill Node.js 模块 | ✅ 当前 |
| HTML shim (module/require) | 简单快速 | 不可靠、依赖链复杂时失败 | ❌ |
| Vite alias 到 .js 文件 | 直接 | UMD 在浏览器原样执行，报错 | ❌ |
| Kotlin/JS ES 模块输出 | 完美兼容浏览器 | IR 编译器尚不支持纯 ESM | 🔮 未来 |
| 双构建（UMD + ESM） | 两端优化 | 复杂、需要维护两套构建 | 🔮 可选 |

## 未来改进

### 短期（可选）
- [ ] 添加 favicon.ico
- [ ] 优化打包大小（代码分割）
- [ ] 添加更多 Node.js 模块的 polyfill（按需）

### 长期（Kotlin 生态成熟后）
- [ ] 使用 Kotlin/Wasm 替代 Kotlin/JS
- [ ] 等待 Kotlin/JS 支持原生 ES 模块
- [ ] 发布双格式 npm 包（UMD + ESM）

## 总结

✅ **问题已完全解决**

- mpp-web 成功在浏览器中加载和运行 mpp-core
- 使用标准 npm 工作流和 Vite 的自动转换能力
- 无需手动 shim，维护成本低
- 同时支持 mpp-ui (CLI) 和 mpp-web (浏览器)

**推荐：** 这是当前最佳方案，平衡了兼容性、性能和可维护性。

