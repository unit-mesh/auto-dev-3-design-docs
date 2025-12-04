# CodeLens WASM Setup

## Overview

The CodeLens feature uses Tree-sitter for accurate code parsing. Tree-sitter requires WASM files to be available at runtime.

## WASM File Management

### Dependencies

- `web-tree-sitter`: Tree-sitter runtime for JavaScript
- `@unit-mesh/treesitter-artifacts`: Pre-compiled WASM grammars for various languages

### Build Process

The WASM files are automatically copied during the build process:

```bash
npm run build
```

This runs:
1. `npm run build:extension` - Bundles the extension code with esbuild
2. `npm run build:webview` - Builds the webview
3. `npm run copy:wasm` - Copies WASM files from node_modules to `dist/wasm/`

### Supported Languages

The following language grammars are bundled:

- TypeScript (`tree-sitter-typescript.wasm`)
- TSX/React (`tree-sitter-tsx.wasm`)
- JavaScript (`tree-sitter-javascript.wasm`)
- Python (`tree-sitter-python.wasm`)
- Java (`tree-sitter-java.wasm`)
- Kotlin (`tree-sitter-kotlin.wasm`)
- Go (`tree-sitter-go.wasm`)
- Rust (`tree-sitter-rust.wasm`)

## Path Resolution

The `CodeElementParser` uses a multi-strategy approach for WASM path resolution:

1. **Extension dist/wasm folder** (production): Used when the extension is packaged
   - Path: `{extensionPath}/dist/wasm/{grammar}.wasm`
   - This is the primary method for packaged extensions

2. **node_modules** (development): Fallback for development mode
   - Path: `node_modules/@unit-mesh/treesitter-artifacts/wasm/{grammar}.wasm`
   - Used during development with `npm run watch`

## Testing in Packaged Extension

To test CodeLens in a packaged extension:

```bash
# Build and package
npm run build
npm run package

# This creates autodev-vscode-{version}.vsix
# Install it in VSCode to test
code --install-extension autodev-vscode-*.vsix
```

## Troubleshooting

### WASM Files Not Found

If you see errors like "WASM file not found for {language}":

1. Check that `dist/wasm/` folder exists after build
2. Verify WASM files are present: `ls dist/wasm/`
3. Rebuild: `npm run build`

### CodeLens Not Showing

1. Check the AutoDev output channel in VSCode for errors
2. Verify the language is supported (see list above)
3. Check configuration: `autodev.codelens.enable` should be `true`
4. For large files (>10,000 lines), CodeLens is disabled by default

### Development Mode Issues

If CodeLens works in development but not in packaged extension:

1. Ensure `.vscodeignore` does NOT exclude `dist/` or `wasm/` folders
2. Check that `vscode:prepublish` script runs `npm run build`
3. Verify WASM files are included in the packaged `.vsix` file:
   ```bash
   unzip -l autodev-vscode-*.vsix | grep wasm
   ```

## Fallback Behavior

If Tree-sitter fails to load (e.g., WASM file missing), the parser falls back to regex-based parsing. This provides basic functionality but may be less accurate for complex code structures.

The fallback regex parser supports all the same languages but without the precision of Tree-sitter AST parsing.

## Configuration

CodeLens can be configured in VSCode settings:

```json
{
  "autodev.codelens.enable": true,
  "autodev.codelens.displayMode": "expand",
  "autodev.codelens.items": [
    "quickChat",
    "autoTest",
    "autoComment"
  ]
}
```

## References

- [Tree-sitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [web-tree-sitter](https://github.com/tree-sitter/tree-sitter/tree/master/lib/binding_web)
- [VSCode Extension Packaging](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)

