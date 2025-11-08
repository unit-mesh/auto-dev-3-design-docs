# Web Fetch 功能测试文档

## 问题诊断

### 原始错误（修复前）
```
Error: connect ECONNREFUSED 0.0.0.0:443
```
原因：Ktor JS 引擎在 Node.js 环境中存在网络请求兼容性问题

### 修复方案
创建了 `NodeFetchHttpFetcher` 使用 Node.js 原生 fetch API，绕过 Ktor 限制。

## 网络环境诊断结果

```bash
# Curl 测试
$ curl -I https://raw.githubusercontent.com/unit-mesh/auto-dev/master/README.md
curl: (7) Failed to connect to raw.githubusercontent.com port 443 after 1 ms: Couldn't connect to server

# Node.js fetch 测试  
$ node -e "fetch('https://www.google.com').then(r => console.log('OK')).catch(e => console.log(e))"
TypeError: fetch failed
[cause]: Error [ERR_TLS_CERT_ALTNAME_INVALID]: Hostname/IP does not match certificate's altnames
```

**结论**：当前网络环境存在以下问题之一：
- 企业防火墙/代理拦截外网访问
- SSL/TLS 中间人检测
- DNS 解析被劫持
- 完全无法访问 GitHub

## 代码修复验证

### 创建的文件
1. `mpp-core/src/jsMain/kotlin/cc/unitmesh/agent/tool/impl/NodeFetchHttpFetcher.js.kt`
2. `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/impl/HttpFetcherFactory.kt`
3. `mpp-core/src/jvmMain/kotlin/cc/unitmesh/agent/tool/impl/HttpFetcherFactory.jvm.kt`
4. `mpp-core/src/androidMain/kotlin/cc/unitmesh/agent/tool/impl/HttpFetcherFactory.android.kt`
5. `mpp-core/src/jsMain/kotlin/cc/unitmesh/agent/tool/impl/HttpFetcherFactory.js.kt`

### 修改的文件
- `mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/tool/impl/WebFetchTool.kt`

### 编译状态
✅ 编译成功，无错误

### 本地测试脚本

创建一个简单的 HTTP 服务器用于本地测试：

```bash
# 1. 启动本地 HTTP 服务器
cd /tmp
echo "# Test README\n\nThis is a test file for web-fetch functionality." > test.md
python3 -m http.server 8000 &

# 2. 测试 web-fetch（使用本地 URL）
cd /Volumes/source/ai/autocrud/mpp-ui
node dist/jsMain/typescript/index.js code --task "读取 http://localhost:8000/test.md 并总结" -p .

# 3. 清理
kill %1
```

## 解决方案建议

### 临时方案（测试用）
```bash
# 使用本地 URL 测试
export TEST_URL="http://localhost:8000/test.md"

# 或使用可访问的镜像站
export TEST_URL="https://gitee.com/..."  # 如果 gitee.com 可访问
```

### 生产环境方案
1. **配置企业代理**：
   ```bash
   export HTTP_PROXY=http://proxy.company.com:8080
   export HTTPS_PROXY=http://proxy.company.com:8080
   export NO_PROXY=localhost,127.0.0.1
   ```

2. **使用内网 Git 服务**：将 README 托管到内网 GitLab/Gitea

3. **预下载文件**：将需要读取的文件先下载到本地，使用 `read-file` 工具

## 功能验证清单

- [x] 代码编译通过
- [x] JS 平台使用原生 fetch API
- [x] JVM/Android 平台使用 Ktor CIO 引擎
- [ ] 网络环境允许外网访问（**当前环境不满足**）

## 建议

在有正常网络访问的环境中测试：
- 家庭网络
- 移动热点
- VPN/代理配置正确的环境
- 云服务器环境



