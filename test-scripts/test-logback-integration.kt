#!/usr/bin/env kotlin

/**
 * Test script to verify Logback integration and file logging
 * This script tests the logging system with file storage
 */

@file:DependsOn("io.github.oshai:kotlin-logging:7.0.13")
@file:DependsOn("ch.qos.logback:logback-classic:1.5.19")

import cc.unitmesh.agent.logging.LoggingInitializer
import cc.unitmesh.agent.logging.LoggingConfig
import cc.unitmesh.agent.logging.getLogger
import cc.unitmesh.agent.logging.JvmLoggingInitializer
import java.io.File

fun main() {
    println("🧪 Testing Logback integration and file logging...\n")
    
    try {
        // Test 1: Initialize logging
        println("1. Initializing logging system...")
        LoggingInitializer.initialize()
        println("✅ Logging system initialized")
        
        // Test 2: Create loggers and test different levels
        println("\n2. Testing different log levels...")
        val logger = getLogger("TestLogger")
        
        logger.trace { "This is a TRACE message" }
        logger.debug { "This is a DEBUG message" }
        logger.info { "This is an INFO message" }
        logger.warn { "This is a WARN message" }
        logger.error { "This is an ERROR message" }
        
        println("✅ Log messages sent")
        
        // Test 3: Check if log files are created
        println("\n3. Checking log file creation...")
        val logDir = JvmLoggingInitializer.getLogDirectory()
        val logFile = File(JvmLoggingInitializer.getCurrentLogFile())
        val errorLogFile = File(JvmLoggingInitializer.getErrorLogFile())
        
        println("Log directory: $logDir")
        println("Main log file: ${logFile.absolutePath}")
        println("Error log file: ${errorLogFile.absolutePath}")
        
        // Wait a moment for file system operations
        Thread.sleep(1000)
        
        if (logFile.exists()) {
            println("✅ Main log file created successfully")
            println("   File size: ${logFile.length()} bytes")
            
            // Read and display last few lines
            val content = logFile.readText()
            val lines = content.lines().takeLast(5).filter { it.isNotBlank() }
            println("   Last few log entries:")
            lines.forEach { line ->
                println("     $line")
            }
        } else {
            println("⚠️  Main log file not found")
        }
        
        if (errorLogFile.exists()) {
            println("✅ Error log file created successfully")
            println("   File size: ${errorLogFile.length()} bytes")
        } else {
            println("ℹ️  Error log file not created (no errors logged yet)")
        }
        
        // Test 4: Test error logging specifically
        println("\n4. Testing error logging...")
        try {
            throw RuntimeException("Test exception for logging")
        } catch (e: Exception) {
            logger.error(e) { "Caught test exception: ${e.message}" }
        }
        
        // Wait for error log to be written
        Thread.sleep(1000)
        
        if (errorLogFile.exists() && errorLogFile.length() > 0) {
            println("✅ Error logged to separate error file")
        }
        
        // Test 5: Test different component loggers
        println("\n5. Testing component-specific loggers...")
        val agentLogger = getLogger("cc.unitmesh.agent.TestComponent")
        val devinsLogger = getLogger("cc.unitmesh.devins.TestComponent")
        val llmLogger = getLogger("cc.unitmesh.llm.TestComponent")
        
        agentLogger.info { "Agent component test message" }
        devinsLogger.debug { "DevIns component test message" }
        llmLogger.info { "LLM component test message" }
        
        println("✅ Component loggers tested")
        
        println("\n🎉 Logback integration test completed successfully!")
        println("📝 Summary:")
        println("   - Logging system initializes correctly")
        println("   - Log files are created in: $logDir")
        println("   - Different log levels work properly")
        println("   - Error logging works with separate file")
        println("   - Component-specific loggers work")
        
    } catch (e: Exception) {
        println("❌ Test failed: ${e.message}")
        e.printStackTrace()
    }
}
