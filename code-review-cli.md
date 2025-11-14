# AutoDev Code Review CLI

Automated code review tool with linting and AI analysis.

## Features

- 🔍 **Automated Linting**: Detects and runs appropriate linters based on file types
- 🤖 **AI-Powered Analysis**: Uses LLM to analyze code quality, security, and best practices
- 📊 **Diff-Based Review**: Reviews only changed code from git diffs
- 🎯 **Multiple Review Types**: Comprehensive, Security, Performance, or Style-focused reviews
- 🛠️ **Multi-Language Support**: Supports Kotlin, Java, JavaScript, TypeScript, Python, and more

## Installation

```bash
cd mpp-ui
npm install
npm run build
```

## Usage

### Basic Usage

Review uncommitted changes in current directory:

```bash
autodev review -p .
```

Review specific commit:

```bash
autodev review -p /path/to/project -c abc123
```

### Review Types

**Comprehensive Review** (default):
```bash
autodev review -p . -t COMPREHENSIVE
```

**Security-Focused Review**:
```bash
autodev review -p . -t SECURITY
```

**Performance Review**:
```bash
autodev review -p . -t PERFORMANCE
```

**Style Review**:
```bash
autodev review -p . -t STYLE
```

### Compare Branches

Review changes between branches:

```bash
autodev review -p . -b main --compare feature-branch
```

### Options

- `-p, --path <path>`: Project path (required)
- `-c, --commit <hash>`: Review specific commit
- `-b, --base <branch>`: Base branch for comparison
- `--compare <branch>`: Branch to compare with base
- `-t, --type <type>`: Review type (COMPREHENSIVE, SECURITY, PERFORMANCE, STYLE)
- `--skip-lint`: Skip linting phase
- `-q, --quiet`: Quiet mode - only show important messages

## Examples

### Example 1: Review Last Commit

```bash
cd /path/to/your/project
autodev review -p . -c HEAD
```

### Example 2: Review PR Changes

```bash
# Review changes from main to current branch
autodev review -p . -b main --compare HEAD
```

### Example 3: Security Review

```bash
autodev review -p . -t SECURITY
```

### Example 4: Quick Review (Skip Linting)

```bash
autodev review -p . --skip-lint
```

## Supported Linters

The tool automatically detects and uses appropriate linters based on file types:

| Language       | Linters                    |
|----------------|----------------------------|
| Kotlin         | detekt                     |
| Java           | PMD                        |
| JavaScript/TS  | Biome, oxlint              |
| Python         | Ruff, Pylint, Flake8       |
| Rust           | Clippy                     |
| Go             | golangci-lint              |
| Ruby           | RuboCop, Brakeman          |
| PHP            | PHPStan, PHPMD, PHPCS      |
| Shell          | ShellCheck                 |
| Markdown       | markdownlint               |
| YAML           | yamllint                   |
| Docker         | Hadolint                   |
| SQL            | SQLFluff                   |
| Swift          | SwiftLint                  |
| HTML           | HTMLHint                   |
| CSS            | Biome                      |

**Note**: Linters must be installed separately. The tool will provide installation instructions if a linter is not found.

## Architecture

### Components

1. **CodeReviewAgent** (`mpp-core`): Core agent that orchestrates the review process
2. **Linter System** (`mpp-core/linter`): Pluggable linter architecture
3. **DiffParser** (`mpp-ui`): Parses git diffs to extract changed files
4. **ReviewMode** (`mpp-ui/typescript`): CLI interface for code review

### Workflow

```
1. Get Diff
   ↓
2. Parse Changed Files
   ↓
3. Run Linters (optional)
   ↓
4. AI Analysis
   ↓
5. Generate Report
```

### Review Process

1. **Lint Phase**: Runs appropriate linters on changed files
2. **Analysis Phase**: AI analyzes lint results and code changes
3. **Fix Phase**: Provides suggestions and potential fixes

## Configuration

The tool uses the same LLM configuration as the main AutoDev CLI. Configure it by running:

```bash
autodev chat
```

Then set up your LLM provider (OpenAI, Anthropic, DeepSeek, etc.).

## Development

### Build

```bash
# Build Kotlin core
./gradlew :mpp-core:assembleJsPackage

# Build TypeScript CLI
cd mpp-ui
npm run build
```

### Test

```bash
# Test Kotlin code
./gradlew :mpp-core:test

# Test TypeScript code
cd mpp-ui
npm test
```

### Add New Linter

1. Create a new linter class extending `ShellBasedLinter`:

```kotlin
class MyLinter(shellExecutor: ShellExecutor) : ShellBasedLinter(shellExecutor) {
    override val name = "my-linter"
    override val description = "My custom linter"
    override val supportedExtensions = listOf("ext")
    
    override fun getVersionCommand() = "my-linter --version"
    override fun getLintCommand(filePath: String, projectPath: String) = 
        "my-linter check \"$filePath\""
    override fun parseOutput(output: String, filePath: String): List<LintIssue> {
        // Parse linter output
    }
    override fun getInstallationInstructions() = "Install: npm install -g my-linter"
}
```

2. Register it in `LinterRegistry`

## Troubleshooting

### "No suitable linters found"

Install linters for your project's languages. For example:

```bash
# JavaScript/TypeScript
npm install -g @biomejs/biome

# Python
pip install ruff

# Kotlin
# Add detekt to your build.gradle.kts
```

### "Failed to get git diff"

Make sure you're in a git repository and have changes to review.

### "No active LLM configuration found"

Run `autodev chat` first to configure your LLM provider.

## Future Enhancements

- [ ] Auto-fix capabilities
- [ ] Custom linter configurations
- [ ] Integration with CI/CD pipelines
- [ ] HTML/JSON report generation
- [ ] Incremental review (only new issues)
- [ ] Code quality metrics tracking

## Related Documentation

- [Linter List](../mpp-core/docs/linter.md)
- [Design System](design-system-color.md)
- [AutoDev CLI](../mpp-ui/README.md)

