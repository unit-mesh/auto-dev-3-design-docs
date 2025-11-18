# Kotlin/Wasm mpp-core 使用指南

## 构建 WASM 模块

### 1. 编译 WASM 库

```bash
cd /Volumes/source/ai/autocrud
./gradlew :mpp-core:wasmJsNodeProductionLibraryDistribution
```

这会生成以下文件：
- `mpp-core/build/dist/wasmJs/productionLibrary/AutoDev-Intellij-mpp-core.wasm` - WASM 二进制文件
- `mpp-core/build/dist/wasmJs/productionLibrary/AutoDev-Intellij-mpp-core.mjs` - ES Module 包装器
- `mpp-core/build/dist/wasmJs/productionLibrary/AutoDev-Intellij-mpp-core.uninstantiated.mjs` - 未实例化的模块

### 2. 浏览器版本

```bash
./gradlew :mpp-core:wasmJsBrowserProductionLibraryDistribution
```

## 在 Node.js 中使用 WASM

### 基本用法

```javascript
import wasmModule from './mpp-core/build/dist/wasmJs/productionLibrary/AutoDev-Intellij-mpp-core.mjs';

// 调用导出的函数
const platformName = wasmModule.wasmGetPlatformName();
console.log('Platform:', platformName);  // 输出: "WebAssembly"

const isWasm = wasmModule.wasmIsWasm();
console.log('Is WASM:', isWasm);  // 输出: true

const timestamp = wasmModule.wasmGetCurrentTimestamp();
console.log('Timestamp:', timestamp);  // 输出: ISO 8601 格式的时间戳
```

### 完整示例

参见 `docs/test-scripts/test-wasm-nodejs.mjs`：

```javascript
// 导入 WASM 模块
const wasmModule = await import('./path/to/AutoDev-Intellij-mpp-core.mjs');

// Platform API
console.log('Platform Name:', wasmModule.wasmGetPlatformName());
console.log('Is WASM:', wasmModule.wasmIsWasm());
console.log('OS Name:', wasmModule.wasmGetOSName());
console.log('Current Timestamp:', wasmModule.wasmGetCurrentTimestamp());
console.log('OS Info:', wasmModule.wasmGetOSInfo());
console.log('Default Shell:', wasmModule.wasmGetDefaultShell());
console.log('User Home Dir:', wasmModule.wasmGetUserHomeDir());
```

## 导出的 API

所有导出的函数都带有 `wasm` 前缀，以避免与 JavaScript 全局命名空间冲突：

### Platform Detection
- `wasmGetPlatformName(): String` - 返回 "WebAssembly"
- `wasmIsWasm(): Boolean` - 返回 true
- `wasmIsJvm(): Boolean` - 返回 false
- `wasmIsJs(): Boolean` - 返回 false
- `wasmIsAndroid(): Boolean` - 返回 false
- `wasmIsIOS(): Boolean` - 返回 false

### System Information
- `wasmGetOSName(): String` - 返回 "WebAssembly"
- `wasmGetOSInfo(): String` - 返回 "WebAssembly Runtime"
- `wasmGetOSVersion(): String` - 返回 "1.0"
- `wasmGetDefaultShell(): String` - 返回 "/bin/bash"（stub）
- `wasmGetUserHomeDir(): String` - 返回 "~"（stub）
- `wasmGetLogDir(): String` - 返回 ".autodev/logs"（stub）

### Utilities
- `wasmGetCurrentTimestamp(): String` - 返回当前 ISO 8601 格式的时间戳

## WASM vs JS 版本的区别

| 特性 | WASM 版本 | JS 版本 |
|------|-----------|---------|
| 文件扩展名 | `.wasm` + `.mjs` | `.js` |
| 模块格式 | ES Module (MJS) | UMD/ES Module |
| TypeScript 定义 | 不支持 | 支持 `.d.ts` |
| 性能 | 更快（接近原生） | 标准 JS 性能 |
| 文件大小 | ~1.5MB | ~500KB |
| 兼容性 | Node.js 16+, 现代浏览器 | Node.js 14+, 所有浏览器 |
| Git 操作 | 不支持（stub） | 不支持（stub） |
| MCP 客户端 | 不支持（stub） | 不支持（stub） |

## 限制

由于 WASM 环境的限制，以下功能只提供 stub 实现：

1. **文件系统访问** - WASM 无法直接访问文件系统
   - `getUserHomeDir()` 返回 "~"
   - `getLogDir()` 返回 ".autodev/logs"

2. **Git 操作** - WASM 无法执行系统命令
   - `GitOperations.isSupported()` 返回 false
   - 所有 git 方法返回空值或默认值

3. **MCP 客户端** - WASM 无法连接到 MCP 服务器
   - `McpClientManager` 返回 DISCONNECTED 状态
   - 工具发现返回空列表

4. **进程操作** - WASM 无法启动子进程或运行 shell 命令

## 测试

运行完整的 WASM 测试：

```bash
node docs/test-scripts/test-wasm-nodejs.mjs
```

预期输出：

```
🚀 Loading WASM module...
✅ WASM module loaded successfully!

Exported functions: [...]

--- Testing Platform API ---
Platform Name: WebAssembly
Is WASM: true
OS Name: WebAssembly
Current Timestamp: 2025-11-11T13:39:13.896Z
OS Info: WebAssembly Runtime
Default Shell: /bin/bash
User Home Dir: ~

✅ All WASM tests completed!
```

## 开发构建

开发过程中可以使用未优化的版本，构建速度更快：

```bash
# Node.js 开发版本
./gradlew :mpp-core:wasmJsNodeDevelopmentLibraryDistribution

# 浏览器开发版本
./gradlew :mpp-core:wasmJsBrowserDevelopmentLibraryDistribution
```

开发版本输出路径：
```
mpp-core/build/dist/wasmJs/developmentLibrary/
```

## 故障排查

### 错误：Cannot find module

确保使用正确的路径导入 `.mjs` 文件，不是 `.wasm` 文件：

```javascript
// ✅ 正确
import wasmModule from './AutoDev-Intellij-mpp-core.mjs';

// ❌ 错误
import wasmModule from './AutoDev-Intellij-mpp-core.wasm';
```

### 错误：WASM validation error

重新构建 WASM 模块：

```bash
./gradlew :mpp-core:clean :mpp-core:wasmJsNodeProductionLibraryDistribution
```

### 警告：standard library version differs

这是 Kotlin/Wasm 实验性功能的已知警告，不影响功能。可以在 `gradle.properties` 中设置匹配的版本。

## 相关文件

- WASM 源代码：`mpp-core/src/wasmJsMain/kotlin/cc/unitmesh/agent/`
- 平台导出：`mpp-core/src/wasmJsMain/kotlin/cc/unitmesh/agent/PlatformExports.wasmJs.kt`
- 构建配置：`mpp-core/build.gradle.kts`
- 测试脚本：`docs/test-scripts/test-wasm-nodejs.mjs`

## 下一步

- 根据需要添加更多导出的 API
- 为浏览器环境创建 HTML 示例
- 考虑使用 WASI 来访问文件系统（如果需要）
- 优化 WASM 文件大小（当前 ~1.5MB）
