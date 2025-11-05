#!/usr/bin/env node

/**
 * Test script to verify that mcpToolsTotal field is correctly implemented
 * in ToolLoadingStatus
 */

const path = require('path');
const fs = require('fs');

async function testMcpToolsTotal() {
    console.log('🧪 Testing mcpToolsTotal field in ToolLoadingStatus...');

    try {
        // Test that ToolLoadingStatus includes mcpToolsTotal field by checking source code
        console.log('🔍 Checking ToolLoadingStatus structure in source code...');

        // Check the Kotlin source file directly
        const sourceFilePath = path.join(__dirname, '../../mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/CodingAgentViewModel.kt');

        if (fs.existsSync(sourceFilePath)) {
            const sourceContent = fs.readFileSync(sourceFilePath, 'utf8');

            // Check if ToolLoadingStatus data class includes mcpToolsTotal
            const toolLoadingStatusMatch = sourceContent.match(/data class ToolLoadingStatus\([^)]+\)/s);

            if (toolLoadingStatusMatch) {
                const dataClassContent = toolLoadingStatusMatch[0];
                console.log('📋 ToolLoadingStatus data class found:');
                console.log(dataClassContent);

                if (dataClassContent.includes('mcpToolsTotal')) {
                    console.log('✅ mcpToolsTotal field is present in ToolLoadingStatus');
                } else {
                    console.log('❌ mcpToolsTotal field is missing from ToolLoadingStatus');
                    return false;
                }

                // Check for other expected fields
                const expectedFields = [
                    'builtinToolsEnabled',
                    'builtinToolsTotal',
                    'subAgentsEnabled',
                    'subAgentsTotal',
                    'mcpServersLoaded',
                    'mcpServersTotal',
                    'mcpToolsEnabled',
                    'mcpToolsTotal',
                    'isLoading'
                ];

                const missingFields = expectedFields.filter(field => !dataClassContent.includes(field));

                if (missingFields.length === 0) {
                    console.log('✅ All expected fields are present in ToolLoadingStatus');
                } else {
                    console.log('❌ Missing fields:', missingFields);
                    return false;
                }

                // Also check if getToolLoadingStatus method sets mcpToolsTotal
                console.log('\n🔍 Checking getToolLoadingStatus method...');

                if (sourceContent.includes('fun getToolLoadingStatus()')) {
                    console.log('✅ getToolLoadingStatus method found');

                    if (sourceContent.includes('mcpToolsTotal = mcpToolsTotal')) {
                        console.log('✅ mcpToolsTotal is being set in getToolLoadingStatus method');
                    } else {
                        console.log('❌ mcpToolsTotal is not being set in getToolLoadingStatus method');
                        return false;
                    }

                    // Check if mcpToolsTotal calculation logic exists
                    if (sourceContent.includes('McpToolConfigManager.getTotalDiscoveredTools()')) {
                        console.log('✅ mcpToolsTotal calculation logic is present');
                    } else {
                        console.log('❌ mcpToolsTotal calculation logic is missing');
                        return false;
                    }

                    // Check if mcpToolsTotal variable is declared
                    if (sourceContent.includes('val mcpToolsTotal =')) {
                        console.log('✅ mcpToolsTotal variable declaration found');
                    } else {
                        console.log('❌ mcpToolsTotal variable declaration not found');
                        return false;
                    }


                } else {
                    console.log('❌ getToolLoadingStatus method not found');
                    return false;
                }
            } else {
                console.log('❌ ToolLoadingStatus data class not found in source code');
                return false;
            }
        } else {
            console.log('❌ Source file not found:', sourceFilePath);
            return false;
        }
        
        // Also check McpToolConfigManager.getTotalDiscoveredTools method
        console.log('\n🔍 Checking McpToolConfigManager.getTotalDiscoveredTools method...');
        const mcpToolConfigManagerPath = path.join(__dirname, '../../mpp-core/src/commonMain/kotlin/cc/unitmesh/agent/config/McpToolConfigManager.kt');

        if (fs.existsSync(mcpToolConfigManagerPath)) {
            const mcpManagerContent = fs.readFileSync(mcpToolConfigManagerPath, 'utf8');

            if (mcpManagerContent.includes('fun getTotalDiscoveredTools()')) {
                console.log('✅ getTotalDiscoveredTools method found in McpToolConfigManager');

                if (mcpManagerContent.includes('cached.values.sumOf { serverToolsMap ->')) {
                    console.log('✅ getTotalDiscoveredTools implementation looks correct');
                } else {
                    console.log('❌ getTotalDiscoveredTools implementation may be incorrect');
                    return false;
                }

                // Check if lastDiscoveredToolsCount is used as fallback
                if (mcpManagerContent.includes('lastDiscoveredToolsCount')) {
                    console.log('✅ lastDiscoveredToolsCount fallback mechanism found');
                } else {
                    console.log('❌ lastDiscoveredToolsCount fallback mechanism not found');
                    return false;
                }
            } else {
                console.log('❌ getTotalDiscoveredTools method not found in McpToolConfigManager');
                return false;
            }
        } else {
            console.log('❌ McpToolConfigManager source file not found');
            return false;
        }

        console.log('🎉 Test completed successfully!');
        return true;
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        return false;
    }
}

// Run the test
testMcpToolsTotal().then(success => {
    process.exit(success ? 0 : 1);
}).catch(error => {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
});
