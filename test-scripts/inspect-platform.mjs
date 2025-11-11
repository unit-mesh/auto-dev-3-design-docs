#!/usr/bin/env node
import('../../mpp-core/build/packages/js/autodev-mpp-core.js')
  .then(module => {
    const exports = module.default || module['module.exports'];
    
    console.log('cc.unitmesh:', Object.keys(exports.cc.unitmesh));
    console.log('\nagent:', Object.keys(exports.cc.unitmesh.agent));
    
    // Try to access Platform
    const agent = exports.cc.unitmesh.agent;
    console.log('\nChecking Platform...');
    console.log('Platform type:', typeof agent.Platform);
    console.log('Platform:', agent.Platform);
    
    // Try different access patterns
    if (agent.Platform) {
      console.log('\nPlatform properties:', Object.getOwnPropertyNames(agent.Platform));
    }
  })
  .catch(error => {
    console.error('Error:', error);
  });
