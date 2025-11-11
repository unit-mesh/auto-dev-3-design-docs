/**
 * Test WASM module in Node.js
 * 
 * This script tests the Kotlin/Wasm compiled mpp-core library in Node.js environment.
 */

import { readFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Get the directory of this script
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Path to the WASM distribution
const wasmDistPath = join(__dirname, '../../mpp-core/build/dist/wasmJs/productionLibrary');

async function testWasm() {
    try {
        console.log('🚀 Loading WASM module...');
        console.log('Distribution path:', wasmDistPath);
        
        // Import the MJS wrapper (it will load the WASM file)
        const wasmModule = await import(join(wasmDistPath, 'AutoDev-Intellij-mpp-core.mjs'));
        
        console.log('\n✅ WASM module loaded successfully!');
        console.log('\nExported functions:');
        console.log(Object.keys(wasmModule).filter(k => typeof wasmModule[k] === 'function'));
        
        console.log('\n--- Testing Platform API ---');
        
        // Test platform detection functions
        if (typeof wasmModule.wasmGetPlatformName === 'function') {
            const platformName = wasmModule.wasmGetPlatformName();
            console.log('Platform Name:', platformName);
        }
        
        if (typeof wasmModule.wasmIsWasm === 'function') {
            const isWasm = wasmModule.wasmIsWasm();
            console.log('Is WASM:', isWasm);
        }
        
        if (typeof wasmModule.wasmGetOSName === 'function') {
            const osName = wasmModule.wasmGetOSName();
            console.log('OS Name:', osName);
        }
        
        if (typeof wasmModule.wasmGetCurrentTimestamp === 'function') {
            const timestamp = wasmModule.wasmGetCurrentTimestamp();
            console.log('Current Timestamp:', timestamp);
        }
        
        if (typeof wasmModule.wasmGetOSInfo === 'function') {
            const osInfo = wasmModule.wasmGetOSInfo();
            console.log('OS Info:', osInfo);
        }
        
        if (typeof wasmModule.wasmGetDefaultShell === 'function') {
            const shell = wasmModule.wasmGetDefaultShell();
            console.log('Default Shell:', shell);
        }
        
        if (typeof wasmModule.wasmGetUserHomeDir === 'function') {
            const homeDir = wasmModule.wasmGetUserHomeDir();
            console.log('User Home Dir:', homeDir);
        }
        
        console.log('\n✅ All WASM tests completed!');
        
    } catch (error) {
        console.error('\n❌ Error loading or testing WASM:', error);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

// Run tests
testWasm();
