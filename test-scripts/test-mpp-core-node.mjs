#!/usr/bin/env node
/**
 * Test script for AutoDev mpp-core (JS build)
 * This demonstrates the multiplatform core functionality in Node.js
 */

// Import from the built package
import('../../mpp-core/build/packages/js/autodev-mpp-core.js')
  .then(module => {
    console.log('=== AutoDev MPP-Core Test (JS) ===\n');
    
    // Access the default export
    const exports = module.default || module['module.exports'];
    
    // Test Platform API using JsPlatform export
    const Platform = exports.cc.unitmesh.agent.JsPlatform;
    console.log('📱 Platform Information:');
    console.log('  Name:', Platform.name);
    console.log('  Is JVM:', Platform.isJvm);
    console.log('  Is JS:', Platform.isJs);
    console.log('  Is WASM:', Platform.isWasm);
    console.log('  Is Android:', Platform.isAndroid);
    console.log('  Is iOS:', Platform.isIOS);
    console.log();
    
    console.log('🖥️  System Information:');
    console.log('  OS Name:', Platform.getOSName());
    console.log('  OS Info:', Platform.getOSInfo());
    console.log('  OS Version:', Platform.getOSVersion());
    console.log('  Default Shell:', Platform.getDefaultShell());
    console.log();
    
    console.log('📂 Paths:');
    console.log('  User Home:', Platform.getUserHomeDir());
    console.log('  Log Directory:', Platform.getLogDir());
    console.log();
    
    console.log('⏰ Time:');
    console.log('  Current Timestamp:', Platform.getCurrentTimestamp());
    console.log();
    
    // Test if we can access other modules
    try {
      const FileSystem = exports.cc.unitmesh.devins.filesystem.DefaultFileSystem;
      console.log('✅ FileSystem module accessible');
    } catch (e) {
      console.log('ℹ️  FileSystem:', e.message);
    }
    
    console.log('\n=== Test Complete ===');
  })
  .catch(error => {
    console.error('❌ Error loading module:', error);
    process.exit(1);
  });
