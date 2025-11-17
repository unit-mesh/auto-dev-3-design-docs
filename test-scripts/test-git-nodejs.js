/**
 * GitOperations Node.js 测试脚本
 * 测试 Kotlin jsMain 编译后的 GitOperations 类
 * 使用系统 git 命令（通过 child_process）
 */

import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function testGitOperations() {
  console.log('🧪 开始 GitOperations Node.js 测试...\n');

  // 加载 Kotlin 编译的模块
  let GitOperations;
  try {
    // 需要先运行 npm run build:kotlin
    const mppCorePath = path.join(__dirname, '../../mpp-core/build/packages/js/kotlin/autodev-mpp-core.mjs');
    console.log(`📦 加载模块: ${mppCorePath}`);
    
    const module = await import(mppCorePath);
    GitOperations = module.cc.unitmesh.agent.platform.GitOperations;
    console.log('✅ 模块加载成功\n');
  } catch (error) {
    console.error('❌ 无法加载 mpp-core 模块:', error.message);
    console.log('\n请先运行: cd /Volumes/source/ai/autocrud && ./gradlew :mpp-core:assembleJsPackage\n');
    return false;
  }

  // 创建临时测试目录
  const testDir = path.join(os.tmpdir(), `git-test-${Date.now()}`);
  await fs.mkdir(testDir, { recursive: true });

  console.log(`📁 测试目录: ${testDir}\n`);

  try {
    // 初始化 Git 仓库（使用系统命令）
    console.log('✅ 测试 0: 初始化 Git 仓库（系统命令）');
    execSync('git init', { cwd: testDir, stdio: 'pipe' });
    execSync('git config user.name "Test User"', { cwd: testDir, stdio: 'pipe' });
    execSync('git config user.email "test@example.com"', { cwd: testDir, stdio: 'pipe' });
    console.log('   ✓ Git 仓库初始化成功\n');

    // 创建 GitOperations 实例
    const gitOps = new GitOperations(testDir);

    // 测试 1: 检测支持
    console.log('✅ 测试 1: 检测 Git 支持');
    const isSupported = gitOps.isSupported();
    console.log(`   ✓ Git 支持: ${isSupported}`);
    if (!isSupported) {
      throw new Error('Git 不支持（需要 Node.js 环境）');
    }
    console.log();

    // 测试 2: 获取修改的文件（应该为空）
    console.log('✅ 测试 2: 获取修改的文件（空仓库）');
    const modifiedFiles = await gitOps.getModifiedFiles();
    console.log(`   ✓ 修改的文件数: ${modifiedFiles.length}`);
    console.log();

    // 测试 3: 创建文件并提交
    console.log('✅ 测试 3: 创建文件并提交');
    const testFile = path.join(testDir, 'test.txt');
    await fs.writeFile(testFile, 'Hello, Git!');
    execSync('git add test.txt', { cwd: testDir, stdio: 'pipe' });
    execSync('git commit -m "Initial commit"', { cwd: testDir, stdio: 'pipe' });
    console.log('   ✓ 文件已创建并提交\n');

    // 测试 4: 获取最近的提交
    console.log('✅ 测试 4: 获取最近的提交');
    const commits = await gitOps.getRecentCommits(5);
    console.log(`   ✓ 提交数: ${commits.length}`);
    if (commits.length > 0) {
      console.log(`   - 消息: ${commits[0].message}`);
      console.log(`   - 作者: ${commits[0].author}`);
      console.log(`   - Hash: ${commits[0].shortHash}`);
    }
    console.log();

    // 测试 5: 获取总提交数
    console.log('✅ 测试 5: 获取总提交数');
    const totalCount = await gitOps.getTotalCommitCount();
    console.log(`   ✓ 总提交数: ${totalCount}`);
    console.log();

    // 测试 6: 修改文件
    console.log('✅ 测试 6: 修改文件');
    await fs.writeFile(testFile, 'Hello, Git! Modified.');
    console.log('   ✓ 文件已修改\n');

    // 测试 7: 获取修改的文件列表
    console.log('✅ 测试 7: 获取修改的文件列表');
    const modifiedFiles2 = await gitOps.getModifiedFiles();
    console.log(`   ✓ 修改的文件数: ${modifiedFiles2.length}`);
    if (modifiedFiles2.length > 0) {
      console.log(`   - 文件: ${modifiedFiles2.join(', ')}`);
    }
    console.log();

    // 测试 8: 获取文件差异
    console.log('✅ 测试 8: 获取文件差异');
    const diff = await gitOps.getFileDiff('test.txt');
    if (diff) {
      console.log(`   ✓ 差异内容长度: ${diff.length} 字符`);
      console.log(`   - 差异预览:\n${diff.split('\n').slice(0, 5).join('\n')}`);
    } else {
      console.log('   ⚠ 无差异内容');
    }
    console.log();

    // 测试 9: 提交修改
    console.log('✅ 测试 9: 提交修改并测试提交差异');
    execSync('git add test.txt', { cwd: testDir, stdio: 'pipe' });
    const commitHash = execSync('git commit -m "Second commit"', { cwd: testDir, stdio: 'pipe' })
      .toString()
      .match(/\[.+? ([a-f0-9]+)\]/)?.[1];
    console.log(`   ✓ 已提交，Hash: ${commitHash}\n`);

    // 测试 10: 获取提交差异
    if (commitHash) {
      console.log('✅ 测试 10: 获取提交差异');
      const commitDiff = await gitOps.getCommitDiff(commitHash);
      if (commitDiff) {
        console.log(`   ✓ 差异内容长度: ${commitDiff.originDiff?.length || 0} 字符`);
      } else {
        console.log('   ⚠ 无差异内容');
      }
      console.log();
    }

    // 测试 11: 获取两个引用之间的差异
    console.log('✅ 测试 11: 获取分支差异');
    const branchDiff = await gitOps.getDiff('HEAD~1', 'HEAD');
    if (branchDiff) {
      console.log(`   ✓ 差异内容长度: ${branchDiff.originDiff?.length || 0} 字符`);
    } else {
      console.log('   ⚠ 无差异内容');
    }
    console.log();

    console.log('🎉 所有测试通过！\n');

    return true;
  } catch (error) {
    console.error('❌ 测试失败:', error);
    console.error('Stack:', error.stack);
    return false;
  } finally {
    // 清理测试目录
    console.log('🧹 清理测试目录...');
    try {
      await fs.rm(testDir, { recursive: true, force: true });
      console.log('✓ 清理完成\n');
    } catch (error) {
      console.warn('清理失败:', error.message);
    }
  }
}

// 运行测试
testGitOperations()
  .then((success) => {
    process.exit(success ? 0 : 1);
  })
  .catch((error) => {
    console.error('测试执行出错:', error);
    process.exit(1);
  });
