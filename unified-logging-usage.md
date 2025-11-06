# AutoDev 统一日志使用指南

## 🎯 **统一日志概述**

AutoDev 现在使用统一的日志文件 `autodev-app.log`，所有组件（mpp-core、mpp-ui 等）的日志都写入同一个文件，便于统一管理和监控。

## 📁 **日志文件位置**

```
~/.autodev/logs/
├── autodev-app.log               # 统一的主日志文件
├── autodev-app-error.log         # 统一的错误日志文件
└── autodev-app.2024-11-06.1.log  # 轮转的历史日志
```

## 🔍 **日志监控命令**

### **实时监控所有日志**
```bash
# 监控主日志文件
tail -f ~/.autodev/logs/autodev-app.log

# 监控错误日志
tail -f ~/.autodev/logs/autodev-app-error.log
```

### **查看最近的日志**
```bash
# 查看最后 50 行
tail -50 ~/.autodev/logs/autodev-app.log

# 查看最后 100 行
tail -100 ~/.autodev/logs/autodev-app.log
```

### **搜索特定内容**
```bash
# 搜索错误信息
grep -i error ~/.autodev/logs/autodev-app.log

# 搜索特定组件的日志
grep "AutoDevMain" ~/.autodev/logs/autodev-app.log
grep "ToolRegistry" ~/.autodev/logs/autodev-app.log
grep "McpToolConfigManager" ~/.autodev/logs/autodev-app.log

# 搜索特定时间段的日志
grep "2025-11-06 11:" ~/.autodev/logs/autodev-app.log
```

### **按日志级别过滤**
```bash
# 只看 ERROR 级别
grep " ERROR " ~/.autodev/logs/autodev-app.log

# 只看 WARN 级别
grep " WARN " ~/.autodev/logs/autodev-app.log

# 只看 INFO 级别
grep " INFO " ~/.autodev/logs/autodev-app.log
```

## 📊 **日志分析示例**

### **统计日志级别分布**
```bash
echo "日志级别统计："
echo "ERROR: $(grep -c " ERROR " ~/.autodev/logs/autodev-app.log)"
echo "WARN:  $(grep -c " WARN " ~/.autodev/logs/autodev-app.log)"
echo "INFO:  $(grep -c " INFO " ~/.autodev/logs/autodev-app.log)"
echo "DEBUG: $(grep -c " DEBUG " ~/.autodev/logs/autodev-app.log)"
```

### **查看组件活动**
```bash
echo "组件活动统计："
echo "mpp-core: $(grep -c "mpp-core\|JvmLoggingInitializer\|LogbackIntegrationTest" ~/.autodev/logs/autodev-app.log)"
echo "mpp-ui:   $(grep -c "AutoDevMain\|ToolRegistry\|CodingAgentViewModel" ~/.autodev/logs/autodev-app.log)"
echo "MCP:      $(grep -c "McpToolConfigManager\|MCP" ~/.autodev/logs/autodev-app.log)"
```

### **查看启动过程**
```bash
# 查看应用启动日志
grep -A 10 -B 5 "AutoDev.*starting" ~/.autodev/logs/autodev-app.log

# 查看日志系统初始化
grep -A 5 -B 5 "logging system initialized" ~/.autodev/logs/autodev-app.log
```

## 🛠️ **日志管理**

### **清理旧日志**
```bash
# 查看日志文件大小
du -h ~/.autodev/logs/autodev-app.log

# 备份当前日志
cp ~/.autodev/logs/autodev-app.log ~/.autodev/logs/autodev-app.log.backup.$(date +%Y%m%d)

# 清空当前日志（谨慎使用）
> ~/.autodev/logs/autodev-app.log
```

### **日志轮转信息**
```bash
# 查看轮转的历史日志
ls -la ~/.autodev/logs/autodev-app.*.log

# 查看所有日志文件大小
du -h ~/.autodev/logs/autodev-app*.log
```

## 🔧 **开发调试**

### **开发时监控**
```bash
# 在一个终端中启动应用
./gradlew :mpp-ui:run

# 在另一个终端中监控日志
tail -f ~/.autodev/logs/autodev-app.log | grep -E "(ERROR|WARN|AutoDevMain)"
```

### **调试特定功能**
```bash
# 监控工具注册
tail -f ~/.autodev/logs/autodev-app.log | grep "ToolRegistry"

# 监控 MCP 服务器
tail -f ~/.autodev/logs/autodev-app.log | grep "Mcp"

# 监控配置加载
tail -f ~/.autodev/logs/autodev-app.log | grep -i "config"
```

## 📈 **日志格式说明**

统一日志格式：
```
2025-11-06 11:06:05.341 [main] INFO  AutoDevMain - 🚀 AutoDev Desktop starting...
│                       │      │     │           │
│                       │      │     │           └─ 日志消息
│                       │      │     └─ Logger 名称
│                       │      └─ 日志级别
│                       └─ 线程名
└─ 时间戳
```

## 🚨 **故障排查**

### **常见问题**
1. **日志文件不存在**
   ```bash
   # 检查日志目录
   ls -la ~/.autodev/logs/
   
   # 手动创建目录
   mkdir -p ~/.autodev/logs/
   ```

2. **日志没有内容**
   ```bash
   # 检查应用是否正在运行
   ps aux | grep autodev
   
   # 检查日志配置
   grep -r "autodev-app" mpp-*/src/*/resources/
   ```

3. **日志文件过大**
   ```bash
   # 检查文件大小
   du -h ~/.autodev/logs/autodev-app.log
   
   # 查看轮转配置
   grep -A 5 -B 5 "maxFileSize\|totalSizeCap" mpp-*/src/*/resources/logback.xml
   ```

## 💡 **最佳实践**

1. **定期监控**：使用 `tail -f` 实时监控日志
2. **错误关注**：重点关注 ERROR 和 WARN 级别的日志
3. **性能分析**：通过日志时间戳分析操作耗时
4. **问题定位**：使用 grep 快速定位特定问题
5. **日志备份**：定期备份重要的日志文件

现在你可以通过一个统一的日志文件监控整个 AutoDev 应用的运行状态！🎉
