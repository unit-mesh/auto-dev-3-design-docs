# 测试脚本说明

本目录包含用于测试和调试的脚本。

## 文件列表

### test-file-search.kt
Kotlin 测试脚本，测试文档搜索和过滤功能。

**用法**:
```bash
# 需要在 Kotlin 环境中运行
```

### test-search-debug.sh
Shell 脚本，使用 `find` 命令模拟文档搜索，用于诊断问题。

**用法**:
```bash
chmod +x test-search-debug.sh
./test-search-debug.sh
```

**输出示例**:
```
=== 测试文档搜索功能 ===
项目路径: /Volumes/source/ai/autocrud

✓ .gitignore 存在

关键排除规则:
.intellijPlatform
node_modules
docs

找到的文档总数（未过滤）:     4976
应该被排除的文件数:           3676
理论上应该索引的文件数:       1300
```

## 注意事项

- 这些脚本仅用于测试和调试
- 不要提交到生产环境
- 临时测试文件应该放在这个目录下

