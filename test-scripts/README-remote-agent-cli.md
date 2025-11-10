# RemoteAgentCli - Kotlin CLI for Testing RemoteAgentClient

This directory contains a Kotlin/JVM CLI that mirrors the TypeScript CLI functionality for connecting to `mpp-server` and executing remote coding agent tasks.

## Purpose

This Kotlin CLI was created to:
1. Validate that the Kotlin `RemoteAgentClient` works identically to the TypeScript version
2. Provide a way to compare rendering and behavior between both implementations
3. Test the `mpp-server` integration from the JVM platform

## Files

- **RemoteAgentCli.kt** - Main CLI implementation (located in `mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/cli/`)
- **run-kotlin-cli.sh** - Convenience script to run the CLI
- **run-remote-agent-cli.sh** - Alternative build script (for standalone compilation)

## Usage

### Method 1: Via Gradle (Recommended)

```bash
cd /Volumes/source/ai/autocrud

# Build and run
./gradlew :mpp-ui:run --args="--task 'Write BlogService tests' --project-id https://github.com/unit-mesh/untitled --server http://localhost:8080"
```

### Method 2: Via Convenience Script

```bash
cd /Volumes/source/ai/autocrud/docs/test-scripts

./run-kotlin-cli.sh \
  --task "编写 BlogService 测试" \
  --project-id https://github.com/unit-mesh/untitled \
  --server http://localhost:8080
```

### Method 3: Using Environment Variables

```bash
# Set environment variables for LLM config
export AUTODEV_PROVIDER=deepseek
export AUTODEV_MODEL=deepseek-chat
export AUTODEV_API_KEY=sk-xxx

# Run without explicit config
./gradlew :mpp-ui:run --args="--task 'Fix bug' --project-id my-project"
```

## Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-s, --server-url <url>` | Server URL | `http://localhost:8080` |
| `-p, --project-id <id>` | Project ID or Git URL | *Required* |
| `-t, --task <task>` | Development task to execute | *Required* |
| `-q, --quiet` | Quiet mode - minimal output | `false` |
| `--use-server-config` | Use server's LLM config | `false` |
| `--provider <provider>` | LLM provider (e.g., deepseek, openai) | From env or `deepseek` |
| `--model <model>` | Model name | From env or `deepseek-chat` |
| `--api-key <key>` | API key for LLM provider | From env |
| `--base-url <url>` | Base URL for LLM provider | From env |
| `-h, --help` | Show help message | - |

## Examples

### 1. Clone and Execute on Git Repository

```bash
./gradlew :mpp-ui:run --args="--task '编写 BlogService 测试' --project-id https://github.com/unit-mesh/untitled --server http://localhost:8080"
```

### 2. Execute on Existing Project

```bash
./gradlew :mpp-ui:run --args="--task 'Fix authentication bug' --project-id my-project"
```

### 3. Use Custom LLM Config

```bash
./gradlew :mpp-ui:run --args="--task 'Refactor UserService' --project-id my-project --provider openai --model gpt-4 --api-key sk-xxx"
```

### 4. Use Server's LLM Configuration

```bash
./gradlew :mpp-ui:run --args="--task 'Add tests' --project-id my-project --use-server-config"
```

## Comparison with TypeScript CLI

The Kotlin CLI is designed to be functionally identical to the TypeScript version:

### TypeScript CLI
```bash
node dist/jsMain/typescript/index.js server \
  --task "编写 BlogService 测试" \
  --project-id https://github.com/unit-mesh/untitled \
  -s http://localhost:8080
```

### Kotlin CLI (Equivalent)
```bash
./gradlew :mpp-ui:run --args="--task '编写 BlogService 测试' --project-id https://github.com/unit-mesh/untitled --server http://localhost:8080"
```

## Expected Output

Both CLIs should produce identical output:

```
🔍 Connecting to server: http://localhost:8080

✅ Server is ok

🚀 AutoDev Remote Coding Agent

🌐 Server: http://localhost:8080
📦 Project: https://github.com/unit-mesh/untitled
📦 Provider: deepseek (from client)
🤖 Model: deepseek-chat

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Cloning repository...

[███░░░░░░░░░░░░░░░░░░░░░░░░░░░] 10% - Cloning repository
  ✓ Git command completed successfully

[██████████████████████████████] 100% - Clone completed successfully

✓ Clone completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ Repository ready at: /tmp/autodev-clone-xxx/untitled

💭 I'll help you write tests for the BlogService...

● src/test/kotlin/BlogServiceTest.kt - edit file
  ⎿ Creating file: src/test/kotlin/BlogServiceTest.kt
  ⎿ File created successfully

✅ Task completed successfully
Task completed after 3 iterations

📝 File Changes:
  ➕ src/test/kotlin/BlogServiceTest.kt
```

## Prerequisites

1. **Build mpp-ui**:
   ```bash
   ./gradlew :mpp-ui:assemble
   ```

2. **Start mpp-server**:
   ```bash
   cd mpp-server
   ./gradlew run
   ```

3. **Configure LLM** (either via env vars or command line args):
   ```bash
   export AUTODEV_API_KEY=sk-xxx
   ```

## Troubleshooting

### Error: "Server health check failed"
- Make sure `mpp-server` is running: `./gradlew :mpp-server:run`
- Check that the server URL is correct (default: `http://localhost:8080`)

### Error: "No API key provided"
- Set the `AUTODEV_API_KEY` environment variable
- Or pass `--api-key` on the command line
- Or use `--use-server-config` to use the server's configuration

### Compilation Errors
```bash
# Clean and rebuild
./gradlew :mpp-ui:clean :mpp-ui:assemble
```

## Development

The CLI implementation is located at:
```
mpp-ui/src/jvmMain/kotlin/cc/unitmesh/devins/cli/RemoteAgentCli.kt
```

Key components:
- **RemoteAgentRenderer** - Renders SSE events with ANSI colors
- **parseArgs()** - Command line argument parser
- **main()** - Entry point using RemoteAgentClient

## Testing

To test the implementation:

1. Start the server:
   ```bash
   ./gradlew :mpp-server:run
   ```

2. Run the Kotlin CLI:
   ```bash
   ./gradlew :mpp-ui:run --args="--task 'test' --project-id https://github.com/unit-mesh/untitled"
   ```

3. Run the TypeScript CLI for comparison:
   ```bash
   cd mpp-ui
   npm run build
   node dist/jsMain/typescript/index.js server --task "test" --project-id https://github.com/unit-mesh/untitled
   ```

4. Compare outputs - they should be functionally identical!

## Architecture

```
┌─────────────────┐
│  Kotlin CLI     │
│  (JVM)          │
└────────┬────────┘
         │
         │ HTTP/SSE
         │
┌────────▼────────┐
│ RemoteAgent     │
│ Client          │
│ (Ktor)          │
└────────┬────────┘
         │
         │ SSE Stream
         │
┌────────▼────────┐
│  mpp-server     │
│  (Ktor Server)  │
└────────┬────────┘
         │
         │ Executes
         │
┌────────▼────────┐
│  CodingAgent    │
│  (mpp-core)     │
└─────────────────┘
```

## Notes

- The Kotlin CLI uses the same `RemoteAgentClient` that will be used in Compose UI
- Rendering is simplified compared to the TypeScript version (no devin block filtering in test version)
- Both CLIs should produce functionally equivalent output
- This validates the cross-platform nature of the AutoDev architecture

