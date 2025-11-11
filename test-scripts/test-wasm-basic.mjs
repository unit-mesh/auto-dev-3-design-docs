// WASM Test - Basic Platform Info
// This file demonstrates using mpp-core WASM in Node.js

import { Platform } from '@autodev/mpp-core-wasm';

console.log('=== AutoDev WASM Test ===');
console.log('Platform Name:', Platform.name);
console.log('Is WASM:', Platform.isWasm);
console.log('OS Name:', Platform.getOSName());
console.log('OS Info:', Platform.getOSInfo());
console.log('Current Timestamp:', Platform.getCurrentTimestamp());
console.log('User Home Dir:', Platform.getUserHomeDir());
console.log('Log Dir:', Platform.getLogDir());
console.log('=== Test Complete ===');
