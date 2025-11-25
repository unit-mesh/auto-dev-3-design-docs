#!/bin/bash

# 测试脚本：检查哪些文件被搜索到但不应该被搜索到

PROJECT_DIR="/Volumes/source/ai/autocrud"

echo "=== 测试文档搜索功能 ==="
echo "项目路径: $PROJECT_DIR"
echo ""

# 检查 .gitignore 是否存在
if [ -f "$PROJECT_DIR/.gitignore" ]; then
    echo "✓ .gitignore 存在"
    echo ""
    echo "关键排除规则:"
    grep -E "(\.intellijPlatform|^docs$|^build|node_modules|\.idea)" "$PROJECT_DIR/.gitignore"
    echo ""
else
    echo "✗ .gitignore 不存在"
fi

# 使用 find 模拟搜索（不使用 gitignore）
echo "=== 使用 find 搜索文档文件 ==="
echo "搜索模式: *.{md,markdown,pdf,doc,docx,ppt,pptx,txt,html,htm}"
echo ""

# 统计总文件数
total=$(find "$PROJECT_DIR" -type f \( \
    -name "*.md" -o \
    -name "*.markdown" -o \
    -name "*.pdf" -o \
    -name "*.doc" -o \
    -name "*.docx" -o \
    -name "*.ppt" -o \
    -name "*.pptx" -o \
    -name "*.txt" -o \
    -name "*.html" -o \
    -name "*.htm" \
    \) 2>/dev/null | wc -l)

echo "找到的文档总数（未过滤）: $total"
echo ""

# 统计不应该被索引的文件
excluded=$(find "$PROJECT_DIR" -type f \( \
    -name "*.md" -o \
    -name "*.markdown" -o \
    -name "*.pdf" -o \
    -name "*.doc" -o \
    -name "*.docx" -o \
    -name "*.ppt" -o \
    -name "*.pptx" -o \
    -name "*.txt" -o \
    -name "*.html" -o \
    -name "*.htm" \
    \) \( \
    -path "*/.intellijPlatform/*" -o \
    -path "*/node_modules/*" -o \
    -path "*/build/*" -o \
    -path "*/.gradle/*" -o \
    -path "*/.idea/*" -o \
    -path "*/bin/*" -o \
    -path "*/out/*" -o \
    -path "*/target/*" -o \
    -path "*/dist/*" -o \
    -path "*/.git/*" \
    \) 2>/dev/null | wc -l)

echo "应该被排除的文件数: $excluded"
echo ""

# 显示前10个不应该被索引的文件
echo "前10个应该被排除的文件示例:"
find "$PROJECT_DIR" -type f \( \
    -name "*.md" -o \
    -name "*.markdown" -o \
    -name "*.pdf" -o \
    -name "*.doc" -o \
    -name "*.docx" -o \
    -name "*.ppt" -o \
    -name "*.pptx" -o \
    -name "*.txt" -o \
    -name "*.html" -o \
    -name "*.htm" \
    \) \( \
    -path "*/.intellijPlatform/*" -o \
    -path "*/node_modules/*" -o \
    -path "*/build/*" -o \
    -path "*/.gradle/*" -o \
    -path "*/.idea/*" -o \
    -path "*/bin/*" -o \
    -path "*/out/*" -o \
    -path "*/target/*" -o \
    -path "*/dist/*" -o \
    -path "*/.git/*" \
    \) 2>/dev/null | head -10 | sed "s|$PROJECT_DIR/||"

echo ""
echo "理论上应该索引的文件数: $((total - excluded))"
echo ""

# 按目录统计
echo "=== 按顶层目录统计（未过滤）==="
find "$PROJECT_DIR" -maxdepth 2 -type f \( \
    -name "*.md" -o \
    -name "*.txt" -o \
    -name "*.html" \
    \) 2>/dev/null | \
    awk -F'/' '{print $(NF-1)}' | sort | uniq -c | sort -rn | head -20

