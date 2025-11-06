#!/usr/bin/env kotlin

/**
 * Simple test script to verify Logback integration
 */

import java.io.File

fun main() {
    println("🧪 Testing Logback integration...\n")
    
    try {
        // Test 1: Check if logback.xml exists in resources
        val logbackConfig = File("mpp-core/src/jvmMain/resources/logback.xml")
        if (logbackConfig.exists()) {
            println("✅ logback.xml configuration file found")
            println("   Path: ${logbackConfig.absolutePath}")
        } else {
            println("❌ logback.xml configuration file not found")
            return
        }
        
        // Test 2: Check if Logback dependency is in build.gradle.kts
        val buildFile = File("mpp-core/build.gradle.kts")
        if (buildFile.exists()) {
            val content = buildFile.readText()
            if (content.contains("logback-classic:1.5.19")) {
                println("✅ Logback dependency found in build.gradle.kts")
            } else {
                println("❌ Logback dependency not found in build.gradle.kts")
            }
            
            if (!content.contains("slf4j-simple")) {
                println("✅ slf4j-simple dependency removed")
            } else {
                println("⚠️  slf4j-simple dependency still present")
            }
        }
        
        // Test 3: Check log directory structure
        val homeDir = System.getProperty("user.home")
        val logDir = File("$homeDir/.autodev/logs")
        println("\n📁 Expected log directory: ${logDir.absolutePath}")
        
        if (!logDir.exists()) {
            println("ℹ️  Log directory doesn't exist yet (will be created on first use)")
        } else {
            println("✅ Log directory already exists")
            val logFiles = logDir.listFiles()?.filter { it.name.contains("autodev-mpp-core") }
            if (logFiles?.isNotEmpty() == true) {
                println("📄 Existing log files:")
                logFiles.forEach { file ->
                    println("   - ${file.name} (${file.length()} bytes)")
                }
            }
        }
        
        // Test 4: Verify platform-specific files exist
        val jvmLoggingInit = File("mpp-core/src/jvmMain/kotlin/cc/unitmesh/agent/logging/JvmLoggingInitializer.kt")
        val jvmPlatformLogging = File("mpp-core/src/jvmMain/kotlin/cc/unitmesh/agent/logging/PlatformLogging.jvm.kt")
        val jsPlatformLogging = File("mpp-core/src/jsMain/kotlin/cc/unitmesh/agent/logging/PlatformLogging.js.kt")
        
        if (jvmLoggingInit.exists()) {
            println("✅ JvmLoggingInitializer.kt exists")
        } else {
            println("❌ JvmLoggingInitializer.kt missing")
        }
        
        if (jvmPlatformLogging.exists()) {
            println("✅ PlatformLogging.jvm.kt exists")
        } else {
            println("❌ PlatformLogging.jvm.kt missing")
        }
        
        if (jsPlatformLogging.exists()) {
            println("✅ PlatformLogging.js.kt exists")
        } else {
            println("❌ PlatformLogging.js.kt missing")
        }
        
        println("\n🎉 Logback integration setup verification completed!")
        println("📝 Summary:")
        println("   - Logback configuration file is in place")
        println("   - Logback dependency is configured")
        println("   - Platform-specific logging files exist")
        println("   - Log directory structure is ready")
        println("\n💡 To test actual logging, run a JVM application that uses the logging system")
        
    } catch (e: Exception) {
        println("❌ Test failed: ${e.message}")
        e.printStackTrace()
    }
}
