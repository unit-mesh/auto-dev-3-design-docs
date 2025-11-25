#!/bin/bash

PROJECT_DIR="/Volumes/source/ai/autocrud"

echo "=== 测试实际搜索到的文件类型 ==="
echo ""

# 获取搜索模式（从 DocumentParserFactory）
PATTERN="*.{md,markdown,pdf,doc,docx,ppt,pptx,txt,html,htm}"
echo "搜索模式: $PATTERN"
echo "预期只匹配: md, markdown, pdf, doc, docx, ppt, pptx, txt, html, htm"
echo ""

# 使用 find 模拟搜索
echo "按文件扩展名统计:"
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
    \) 2>/dev/null | \
    awk -F'.' '{print $NF}' | \
    sort | uniq -c | sort -rn

echo ""
echo "检查是否有非预期的文件类型被搜索到..."
echo ""

# 检查特定的 .xml 文件
XML_FILE=".intellijPlatform/localPlatformArtifacts/bundledPlugin-org.intellij.plugins.markdown-2022.2.4+490.xml"
if [ -f "$PROJECT_DIR/$XML_FILE" ]; then
    echo "✗ 发现 .xml 文件: $XML_FILE"
    echo "  这个文件不应该被搜索模式匹配！"
    
    # 检查文件名
    FILENAME=$(basename "$XML_FILE")
    echo "  文件名: $FILENAME"
    echo "  扩展名: ${FILENAME##*.}"
    
    # 检查是否包含 .md
    if [[ "$FILENAME" == *".md"* ]]; then
        echo "  ⚠️ 警告: 文件名包含 .md 字符串"
        echo "  这可能导致模糊匹配问题"
    fi
else
    echo "✓ 该 .xml 文件不存在或已被删除"
fi

echo ""
echo "搜索文件名包含 'markdown' 但不是 .md 的文件:"
find "$PROJECT_DIR" -type f -name "*markdown*" ! -name "*.md" ! -name "*.markdown" 2>/dev/null | head -10

echo ""
echo "搜索 .xml 文件名包含 .md 的:"
find "$PROJECT_DIR" -type f -name "*.xml" -name "*md*" 2>/dev/null | head -10

