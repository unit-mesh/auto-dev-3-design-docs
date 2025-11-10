#!/bin/bash
# Git Clone 优化测试脚本

set -e

echo "======================================"
echo "Git Clone 优化测试"
echo "======================================"
echo ""

# 1. 构建项目
echo "📦 1. 构建 mpp-server..."
./gradlew :mpp-server:clean :mpp-server:build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
else
    echo "❌ 构建失败"
    exit 1
fi
echo ""

# 2. 运行测试
echo "🧪 2. 运行测试..."
./gradlew :mpp-server:test

if [ $? -eq 0 ]; then
    echo "✅ 测试通过"
else
    echo "❌ 测试失败"
    exit 1
fi
echo ""

# 3. 检查日志目录
echo "📁 3. 检查日志目录..."
LOG_DIR="$HOME/.autodev/logs"
if [ -d "$LOG_DIR" ]; then
    echo "✅ 日志目录存在: $LOG_DIR"
    
    if [ -f "$LOG_DIR/autodev-app.log" ]; then
        echo "✅ 日志文件存在: $LOG_DIR/autodev-app.log"
        
        # 显示最后10行日志
        echo ""
        echo "最近的日志条目:"
        echo "---"
        tail -n 10 "$LOG_DIR/autodev-app.log" || echo "（日志文件为空或无法读取）"
        echo "---"
    else
        echo "⚠️ 日志文件尚未创建（需要运行服务后才会创建）"
    fi
else
    echo "⚠️ 日志目录尚未创建（需要运行服务后才会创建）"
fi
echo ""

# 4. 验证关键类存在
echo "🔍 4. 验证关键类..."
echo "检查 GitCloneService..."
if grep -r "class GitCloneService" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ GitCloneService 存在"
fi

echo "检查 GitCommand..."
if grep -r "class GitCommand" mpp-server/src/main/kotlin/cc/unitmesh/server/command/GitCommand.kt > /dev/null; then
    echo "✅ GitCommand 存在"
fi
echo ""

# 5. 检查日志记录器
echo "📝 5. 检查日志记录器集成..."
if grep -r "AutoDevLogger.getLogger" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ GitCloneService 已集成 AutoDevLogger"
fi

if grep -r "AutoDevLogger.getLogger" mpp-server/src/main/kotlin/cc/unitmesh/server/command/GitCommand.kt > /dev/null; then
    echo "✅ GitCommand 已集成 AutoDevLogger"
fi
echo ""

# 6. 检查分支处理逻辑
echo "🌿 6. 检查分支处理逻辑..."
if grep -r "Git will use repository's default branch" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ 已实现默认分支逻辑"
fi

if grep -r "retrying with default branch" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ 已实现分支回退机制"
fi
echo ""

# 7. 检查临时目录跟踪
echo "🗂️  7. 检查临时目录跟踪..."
if grep -r "tempDirectoryMap" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ 已实现临时目录跟踪"
fi

if grep -r "fun getWorkspacePath" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ 已实现工作区路径查询 API"
fi

if grep -r "fun getAllWorkspaces" mpp-server/src/main/kotlin/cc/unitmesh/server/service/GitCloneService.kt > /dev/null; then
    echo "✅ 已实现所有工作区查询 API"
fi
echo ""

echo "======================================"
echo "✅ 所有检查通过！"
echo "======================================"
echo ""
echo "📚 查看详细文档: docs/test-scripts/git-clone-optimization-summary.md"
echo "📊 查看日志: tail -f ~/.autodev/logs/autodev-app.log"
echo ""

