# AutoDev mpp-web Setup

## Problem

The Kotlin/JS compiler generates UMD (Universal Module Definition) format code, which uses `module.exports` and `require()`. These are Node.js/CommonJS constructs that don't work natively in the browser.

## Solution

We use a **local npm package approach** where Vite automatically handles UMD → ESM conversion:

### 1. **Local Package Dependency** (`package.json`)

Install mpp-core as a local file: dependency:

```json
{
  "dependencies": {
    "@autodev/mpp-core": "file:../mpp-core/build/packages/js"
  }
}
```

### 2. **Node.js Module Polyfills** (`vite.config.ts`)

Provide browser polyfills for Node.js-specific modules (like `ws`):

```typescript
resolve: {
  alias: {
    'ws': path.resolve(__dirname, 'src/polyfills/ws-polyfill.ts'),
  },
}
```

### 3. **Kotlin/JS Configuration** (`mpp-core/build.gradle.kts`)

- **Module Kind**: Set to `umd` for maximum compatibility
- **Targets**: Both `browser()` and `nodejs()` to support both mpp-web and mpp-ui
- Vite automatically converts UMD to ESM during bundling

## Build and Run

```bash
# 1. Build mpp-core (generates npm package)
cd /path/to/autocrud
./gradlew :mpp-core:assembleJsPackage

# 2. Install dependencies (first time or after mpp-core rebuild)
cd mpp-web
npm install

# 3. Start dev server
npm run dev
# Opens at http://localhost:3000

# 4. Production build
npm run build
```

## Development Workflow

### When mpp-core changes:

```bash
# 1. Rebuild mpp-core
./gradlew :mpp-core:assembleJsPackage

# 2. Reinstall (links to new build)
cd mpp-web && npm install

# 3. Vite will automatically reload
```

### When mpp-web changes:

Vite's HMR (Hot Module Replacement) will automatically reload the page.

## Verification

✅ **Tested with Playwright** - No browser errors (except favicon.ico 404)
✅ **mpp-core loads successfully** - Confirmed in console
✅ **Full functionality** - Chat interface works correctly

## Architecture

```
mpp-web (Browser)
  ├── React + TypeScript
  ├── Vite (dev server + bundler)
  └── mpp-core (UMD modules)
       ├── autodev-mpp-core.js
       └── kotlin-stdlib + dependencies

mpp-ui (Node.js CLI)
  ├── React + Ink (terminal UI)
  ├── TypeScript
  └── mpp-core (UMD modules, works natively in Node.js)
```

## Known Limitations

1. **Bundle Size**: UMD format includes more boilerplate than pure ES modules (~722KB minified, 205KB gzipped)
2. **Node.js Module Polyfills**: Need to add polyfills for each Node.js-specific module used by Kotlin/JS dependencies

## Future Improvements

- [ ] Add favicon.ico
- [ ] Code splitting for better performance
- [ ] Consider Kotlin/Wasm when mature
- [ ] Publish dual-format npm package (UMD + ESM)

## Troubleshooting

### Error: "Could not resolve 'xxx'"

A Kotlin/JS dependency is trying to import a Node.js module. Add a polyfill:

```typescript
// vite.config.ts
resolve: {
  alias: {
    'xxx': path.resolve(__dirname, 'src/polyfills/xxx-polyfill.ts'),
  },
}
```

### mpp-core changes not reflected

```bash
# Rebuild and reinstall
./gradlew :mpp-core:assembleJsPackage
cd mpp-web && npm install
```

### Vite optimization errors

```bash
# Clear cache and restart
rm -rf node_modules/.vite
npm run dev
```

