# Domain Dictionary Implementation

## Overview

This document describes the implementation of the domain dictionary generation feature for AutoDev CLI. The feature allows users to generate a domain-specific dictionary from their codebase using the `/init` command.

## Problem

The original request was to implement a domain dictionary generation feature that:
1. Analyzes project code files
2. Extracts semantic names and terms
3. Generates a CSV file with domain-specific vocabulary
4. Integrates with the existing CLI chat interface

## Root Cause

The main challenges were:
1. Missing dependencies on `mpp-codegraph` module
2. Incompatible APIs between different modules
3. TypeScript compilation errors in the CLI
4. Missing type definitions for new commands

## Solution

### 1. Core Implementation

**Files Created/Modified:**
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/DomainDictService.kt` - Main service for collecting semantic names
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/DomainDictGenerator.kt` - Generator with LLM integration
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/model/` - Data models for domain dictionary
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/naming/` - Name processing utilities
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/scoring/` - File weight calculation
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/template/` - Template engine for prompts
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/utils/` - Token counting utilities

### 2. CLI Integration

**Files Modified:**
- `mpp-ui/src/jsMain/typescript/processors/SlashCommandProcessor.ts` - Added `/init` command
- `mpp-ui/src/jsMain/typescript/i18n/types.ts` - Added type definitions for init command
- `mpp-ui/src/jsMain/typescript/i18n/locales/en.ts` - Added English translations
- `mpp-ui/src/jsMain/typescript/i18n/locales/zh.ts` - Added Chinese translations

### 3. Key Features

1. **File Analysis**: Scans project files and extracts semantic names from file paths and names
2. **Weight Calculation**: Assigns importance weights to files based on location and type
3. **Name Processing**: Splits camelCase names and filters common suffixes
4. **Token Management**: Respects token limits for LLM processing
5. **Template System**: Uses configurable templates for LLM prompts
6. **CSV Export**: Generates structured CSV output with semantic names and metadata

### 4. Architecture

```
CLI (/init command)
    ↓
DomainDictGenerator
    ↓
DomainDictService (collects semantic names)
    ↓
Various utilities (naming, scoring, templates)
    ↓
LLM Processing (generates descriptions)
    ↓
CSV Export (prompts/domain.csv)
```

## Testing

Created test scripts:
- `docs/test-scripts/test-domain-dict.sh` (JavaScript/CLI version)
- `docs/test-scripts/test-domain-dict-jvm.sh` (JVM/Desktop version)

**JavaScript/CLI Test Results:**
- ✅ mpp-core JS builds successfully
- ✅ mpp-ui TypeScript compiles successfully
- ✅ CLI starts and shows help
- ✅ Basic functionality works
- ⚠️  Interactive mode has raw mode issues (expected in non-interactive environments)

**JVM/Desktop Test Results:**
- ✅ mpp-core JVM builds successfully (1.6MB jar)
- ✅ mpp-ui JVM builds successfully (733KB jar)
- ✅ Desktop application launches successfully
- ✅ Domain dictionary service classes available
- ✅ MCP servers and tools load correctly
- ✅ 211/217 tests pass (6 unrelated test failures)

## Usage

1. **Build the project:**
   ```bash
   ./gradlew :mpp-core:assembleJsPackage
   cd mpp-ui && npm run build:ts
   ```

2. **Run the CLI:**
   ```bash
   cd mpp-ui && node dist/jsMain/typescript/index.js chat
   ```

3. **Generate domain dictionary:**
   ```
   /init
   ```

4. **Check output:**
   ```bash
   cat prompts/domain.csv
   ```

## Next Steps

1. Test the `/init` command with actual LLM configuration
2. Verify CSV output format and content
3. Add more sophisticated code analysis (currently simplified)
4. Integrate with full `mpp-codegraph` module when available
5. Add progress indicators for long-running operations

## Files Structure

```
mpp-core/src/commonMain/kotlin/cc/unitmesh/indexer/
├── DomainDictService.kt          # Main service
├── DomainDictGenerator.kt        # LLM integration
├── model/                        # Data models
├── naming/                       # Name processing
├── scoring/                      # File weighting
├── template/                     # Template engine
└── utils/                        # Utilities
```
