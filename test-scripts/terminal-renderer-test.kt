#!/usr/bin/env kotlin

/**
 * Test script for the ANSI Terminal Renderer.
 * 
 * This script demonstrates various ANSI escape sequences and how they are rendered.
 * Run this to verify that the terminal renderer correctly handles:
 * - Colors (foreground and background)
 * - Text styles (bold, italic, underline, dim)
 * - Cursor movements
 * - Line clearing
 * - Complex real-world output (like Gradle builds)
 */

import cc.unitmesh.devins.ui.compose.terminal.AnsiParser
import cc.unitmesh.devins.ui.compose.terminal.TerminalState

fun main() {
    println("=== ANSI Terminal Renderer Test ===\n")
    
    // Test 1: Basic colors
    println("Test 1: Basic Colors")
    testBasicColors()
    println()
    
    // Test 2: Text styles
    println("Test 2: Text Styles")
    testTextStyles()
    println()
    
    // Test 3: Cursor movements
    println("Test 3: Cursor Movements")
    testCursorMovements()
    println()
    
    // Test 4: Line clearing
    println("Test 4: Line Clearing")
    testLineClearing()
    println()
    
    // Test 5: Gradle build output
    println("Test 5: Gradle Build Output")
    testGradleBuild()
    println()
    
    println("=== All Tests Complete ===")
}

fun testBasicColors() {
    val state = TerminalState()
    val parser = AnsiParser()
    
    val input = """
        ${'\u001B'}[31mRed Text${'\u001B'}[0m
        ${'\u001B'}[32mGreen Text${'\u001B'}[0m
        ${'\u001B'}[33mYellow Text${'\u001B'}[0m
        ${'\u001B'}[34mBlue Text${'\u001B'}[0m
    """.trimIndent()
    
    parser.parse(input, state)
    
    println("Input: $input")
    println("Parsed lines: ${state.lines.size}")
    println("Output text:")
    println(state.toText())
    
    // Verify colors are set
    assert(state.lines.size >= 4) { "Expected at least 4 lines" }
    println("✓ Basic colors test passed")
}

fun testTextStyles() {
    val state = TerminalState()
    val parser = AnsiParser()
    
    val input = """
        ${'\u001B'}[1mBold${'\u001B'}[0m
        ${'\u001B'}[3mItalic${'\u001B'}[0m
        ${'\u001B'}[4mUnderline${'\u001B'}[0m
        ${'\u001B'}[2mDim${'\u001B'}[0m
        ${'\u001B'}[1;4;31mBold Underline Red${'\u001B'}[0m
    """.trimIndent()
    
    parser.parse(input, state)
    
    println("Input: $input")
    println("Parsed lines: ${state.lines.size}")
    println("Output text:")
    println(state.toText())
    
    // Check that styles are applied
    val line1 = state.lines[0]
    assert(line1.cells.any { it.bold }) { "Expected bold text in first line" }
    
    println("✓ Text styles test passed")
}

fun testCursorMovements() {
    val state = TerminalState()
    val parser = AnsiParser()
    
    // Write "Hello", move back, overwrite with "HELLO"
    val input = "Hello${'\u001B'}[5DH${'\u001B'}[1CE${'\u001B'}[1CL${'\u001B'}[1CL${'\u001B'}[1CO"
    
    parser.parse(input, state)
    
    println("Input: $input")
    println("Output: ${state.toText()}")
    
    // Should show "HELLO" (uppercase)
    assert(state.toText().contains("HELLO")) { "Expected 'HELLO' in output" }
    println("✓ Cursor movements test passed")
}

fun testLineClearing() {
    val state = TerminalState()
    val parser = AnsiParser()
    
    // Write text, then clear from cursor
    val input = "Hello World${'\u001B'}[6D${'\u001B'}[0K"
    
    parser.parse(input, state)
    
    println("Input: $input")
    println("Output: '${state.toText()}'")
    
    // Should show "Hello " (World cleared)
    val output = state.toText()
    assert(output.trim() == "Hello") { "Expected 'Hello', got '$output'" }
    println("✓ Line clearing test passed")
}

fun testGradleBuild() {
    val state = TerminalState()
    val parser = AnsiParser()
    
    val gradleOutput = """
Starting a Gradle Daemon (subsequent builds will be faster)


[2A[1B[1m> Starting Daemon[m[17D[1B[2A[1m<[0;1m-------------> 0% INITIALIZING [44ms][m[38D[2B[2A[1m<[0;1m-------------> 0% INITIALIZING [248ms][m[39D[1B[1m> Evaluating settings[m[21D[1B[2A[1m<[0;1m-------------> 0% INITIALIZING [449ms][m[39D[2B[2A[1m<[0;1m-------------> 0% INITIALIZING [645ms][m[39D[1B[1m> Evaluating settings > Resolve dependencies of detachedConfiguration1[m[70D[1B[2A[1m<[0;1m-------------> 0% INITIALIZING [849ms][m[39D[2B[2A[1m<[0;1m-------------> 0% INITIALIZING [1s][m[0K[36D[2B[1A[1m> root project[m[0K[14D[1B[2A[1m<[0;1m-------------> 0% CONFIGURING [3s][m[35D[2B[2A[1m<[0;32;1m=============[0;39;1m> 100% CONFIGURING [3s][m[37D[1B> IDLE[0K[6D[1B[1A[1m> :compileJava > Resolve dependencies of :compileClasspath > Resolve dependenci[m[79D[1B[1A[1m> :compileJava[m[0K[14D[1B[2A[1m<[0;32;1m=======[0;39;1m------> 53% EXECUTING [3s][m[34D[1B[1m> :compileTestJava[m[18D[1B[2A[1m<[0;32;1m==========[0;39;1m---> 76% EXECUTING [4s][m[34D[1B[1m> :test > 0 tests completed[m[27D[1B[3A[0K
[31;1m> Task :test[0;39m[31m FAILED[39m[0K
[0K
DemoApplicationTests > contextLoads() [31mFAILED[39m
    java.lang.IllegalStateException at DefaultCacheAwareContextLoaderDelegate.java:98
        Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException at ConstructorResolver.java:800
            Caused by: org.springframework.beans.factory.BeanCreationException at ConstructorResolver.java:658
                Caused by: org.springframework.beans.BeanInstantiationException at SimpleInstantiationStrategy.java:185
                    Caused by: java.lang.IllegalStateException at Assert.java:97

2 tests completed, 1 failed
[0K
[0K
[0K
[3A[1m<[0;31;1m===========[0;39;1m--> 84% EXECUTING [5s][m[34D[1B> IDLE[6D[1B> IDLE[6D[1B[3A[2K[1B[2K[1B[2K[2A[0m[?12l[?25h
"""
    
    parser.parse(gradleOutput, state)
    
    println("Gradle output parsed")
    println("Total lines: ${state.lines.size}")
    println("Visible lines: ${state.getVisibleLines().size}")
    println("\nFinal output:")
    println(state.toText())
    
    // Verify key elements are present
    val output = state.toText()
    assert(output.contains("FAILED")) { "Expected 'FAILED' in output" }
    assert(output.contains("DemoApplicationTests")) { "Expected test name in output" }
    
    println("\n✓ Gradle build test passed")
}

