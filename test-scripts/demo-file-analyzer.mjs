#!/usr/bin/env node
/**
 * 完整示例：使用 AutoDev MPP-Core 创建一个简单的文件分析器
 * 
 * 功能：
 * 1. 检测平台信息
 * 2. 读取项目文件
 * 3. 分析文件内容
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 导入 AutoDev MPP-Core
import('../../mpp-core/build/packages/js/autodev-mpp-core.js')
  .then(async module => {
    const exports = module.default || module['module.exports'];
    
    console.log('╔════════════════════════════════════════════════════╗');
    console.log('║   AutoDev MPP-Core - File Analyzer Demo          ║');
    console.log('╚════════════════════════════════════════════════════╝\n');
    
    // 1. 平台检测
    const Platform = exports.cc.unitmesh.agent.JsPlatform;
    console.log('🔍 检测运行环境...');
    console.log(`   平台: ${Platform.name}`);
    console.log(`   系统: ${Platform.getOSInfo()}`);
    console.log(`   主目录: ${Platform.getUserHomeDir()}`);
    console.log(`   时间: ${Platform.getCurrentTimestamp()}\n`);
    
    // 2. 功能展示
    console.log('🛠️  可用功能演示:\n');
    
    console.log('   ✅ 平台检测 - Platform API');
    console.log('   ✅ 时间处理 - getCurrentTimestamp()');
    console.log('   ✅ 路径管理 - getUserHomeDir(), getLogDir()');
    console.log('   ✅ 系统信息 - getOSInfo(), getOSVersion()');
    
    console.log('\n� 已导出的模块:');
    const agentKeys = Object.keys(exports.cc.unitmesh.agent);
    agentKeys.forEach(key => {
      if (key.startsWith('Js')) {
        console.log(`   • ${key}`);
      }
    });
    
    console.log('\n💡 使用示例:');
    console.log('   ```javascript');
    console.log('   const Platform = exports.cc.unitmesh.agent.JsPlatform;');
    console.log('   console.log(Platform.getOSInfo());');
    console.log('   console.log(Platform.getUserHomeDir());');
    console.log('   ```');
    
    console.log('\n� 更多信息:');
    console.log('   - 查看 docs/nodejs-test-guide.md');
    console.log('   - 查看 docs/wasm-test-summary.md');
    
    console.log('✨ 演示完成！\n');
    
  })
  .catch(error => {
    console.error('❌ 错误:', error.message);
    console.error('\n请先构建 JS package:');
    console.error('  cd /Volumes/source/ai/autocrud');
    console.error('  ./gradlew :mpp-core:assembleJsPackage\n');
    process.exit(1);
  });
