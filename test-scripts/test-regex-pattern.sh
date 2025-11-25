#!/bin/bash

echo "=== 测试搜索模式的正则转换 ==="
echo ""

# 原始模式
PATTERN="*.{md,markdown,pdf,doc,docx,ppt,pptx,txt,html,htm}"
echo "原始模式: $PATTERN"
echo ""

# 当前代码的转换逻辑
echo "当前代码的转换:"
echo "  .replace('.', '\\.')     → 转义点号"
echo "  .replace('**', '.*')     → ** 变为 .*"
echo "  .replace('*', '[^/]*')   → * 变为 [^/]*"
echo "  .replace('{', '(')       → { 变为 ("
echo "  .replace('}', ')')       → } 变为 )"
echo "  .replace(',', '|')       → , 变为 |"
echo ""

# 转换结果
REGEX="[^/]*\\.(md|markdown|pdf|doc|docx|ppt|pptx|txt|html|htm)"
echo "转换后的正则: $REGEX"
echo ""

# 测试匹配
echo "测试匹配:"
test_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # 使用 grep 测试（模拟正则匹配）
    if echo "$filename" | grep -qE "$REGEX"; then
        echo "  ✓ 匹配: $filename"
    else
        echo "  ✗ 不匹配: $filename"
    fi
}

test_file "README.md"
test_file "guide.markdown"
test_file "doc.pdf"
test_file "file.txt"
test_file "page.html"
test_file "bundledPlugin-org.intellij.plugins.markdown-2022.2.4+490.xml"
test_file "test.xml"
test_file "contains-md-in-name.xml"

echo ""
echo "❌ 问题分析:"
echo "文件名 'bundledPlugin-org.intellij.plugins.markdown-...' 中包含 '.markdown'，"
echo "被错误地匹配为 markdown 文件！"
echo ""
echo "原因: 正则 '[^/]*\\.(md|markdown|...)' 匹配文件名中任何 '.md' 或 '.markdown'，"
echo "不仅仅是文件扩展名。"
echo ""
echo "正确的做法: 应该匹配 '\\.(md|markdown|...)$'，确保匹配的是扩展名。"

