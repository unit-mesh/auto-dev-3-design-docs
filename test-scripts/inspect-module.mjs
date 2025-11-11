#!/usr/bin/env node
/**
 * Inspect AutoDev mpp-core module structure
 */

import('../../mpp-core/build/packages/js/autodev-mpp-core.js')
  .then(module => {
    console.log('=== Module Structure ===\n');
    console.log('Module keys:', Object.keys(module));
    console.log('\nModule content:', module);
    
    // Try to find Platform in different ways
    if (module.default) {
      console.log('\nDefault export keys:', Object.keys(module.default));
    }
    
    // Check for namespace
    for (const key of Object.keys(module)) {
      if (typeof module[key] === 'object' && module[key] !== null) {
        console.log(`\n${key} keys:`, Object.keys(module[key]).slice(0, 10));
      }
    }
  })
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });
