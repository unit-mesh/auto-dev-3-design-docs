#!/bin/bash

echo "=== 验证文件扩展名匹配修复 ==="
echo ""

# 模拟正则匹配（修复后）
REGEX="[^/]*\\.(md|markdown|pdf|doc|docx|ppt|pptx|txt|html|htm)$"

echo "修复后的正则: $REGEX"
echo "关键变化: 添加了 \$ 确保匹配文件末尾"
echo ""

echo "测试用例:"
echo ""

test_match() {
    local file="$1"
    local should_match="$2"
    local filename=$(basename "$file")
    
    if echo "$filename" | grep -qE "$REGEX"; then
        if [ "$should_match" = "yes" ]; then
            echo "  ✓ 正确匹配: $filename"
        else
            echo "  ✗ 错误匹配: $filename (不应该匹配)"
        fi
    else
        if [ "$should_match" = "no" ]; then
            echo "  ✓ 正确不匹配: $filename"
        else
            echo "  ✗ 错误不匹配: $filename (应该匹配)"
        fi
    fi
}

echo "1. 应该匹配的文件 (正常的文档文件):"
test_match "README.md" "yes"
test_match "guide.markdown" "yes"
test_match "document.pdf" "yes"
test_match "file.txt" "yes"
test_match "page.html" "yes"
test_match "index.htm" "yes"

echo ""
echo "2. 不应该匹配的文件 (包含文档扩展名但不是文档):"
test_match "bundledPlugin-org.intellij.plugins.markdown-2022.2.4+490.xml" "no"
test_match "contains.markdown.xml" "no"
test_match "file.md.xml" "no"
test_match "test.xml" "no"
test_match "config.json" "no"
test_match "script.js" "no"

echo ""
echo "总结:"
echo "✓ 修复后，只有真正的文档文件（扩展名为 md, txt, html 等）会被匹配"
echo "✓ 文件名中包含 .markdown 但扩展名为 .xml 的文件不会被匹配"

