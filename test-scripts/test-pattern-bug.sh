#!/bin/bash

# 测试 gitignore 的真实行为 vs 我们的实现

echo "=== 测试 .intellijPlatform 模式 ==="
echo ""

# 创建测试环境
TEST_DIR="/tmp/gitignore-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 初始化 git 仓库
git init -q

# 创建 gitignore
cat > .gitignore << 'EOF'
.intellijPlatform
docs
build/
EOF

# 创建测试文件
mkdir -p .intellijPlatform/localPlatformArtifacts
touch .intellijPlatform/file1.xml
touch .intellijPlatform/localPlatformArtifacts/bundledPlugin.xml
mkdir -p docs/guide
touch docs/README.md
touch docs/guide/intro.md
mkdir -p build
touch build/output.txt
touch normal-file.txt

# 检查 git 的行为
echo "Git 的行为（git status 显示的未跟踪文件）:"
git status --short --untracked-files=all

echo ""
echo "被 git 忽略的文件（git check-ignore）:"
git check-ignore -v .intellijPlatform/file1.xml
git check-ignore -v .intellijPlatform/localPlatformArtifacts/bundledPlugin.xml
git check-ignore -v docs/README.md
git check-ignore -v docs/guide/intro.md
git check-ignore -v build/output.txt

echo ""
echo "结论："
echo "✓ .intellijPlatform (无斜杠) 应该匹配该目录及其所有内容"
echo "✓ docs (无斜杠) 应该匹配该目录及其所有内容"  
echo "✓ build/ (有斜杠) 只匹配目录，不匹配名为 build 的文件"

# 清理
cd /
rm -rf "$TEST_DIR"

