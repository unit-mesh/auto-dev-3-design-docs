#!/usr/bin/env kotlin

// Test script for linter parsing
// This is a standalone Kotlin script to test the static parsing methods

import cc.unitmesh.agent.linter.linters.DetektLinter
import cc.unitmesh.agent.linter.linters.PMDLinter

fun main() {
    println("=== Testing DetektLinter.parseDetektOutput ===")
    val detektOutput = """
/Volumes/source/ai/autocrud/docs/test-scripts/linter-tests/BadKotlin.kt:1:1: The package declaration does not match the actual file location. [InvalidPackageDeclaration]
/Volumes/source/ai/autocrud/docs/test-scripts/linter-tests/BadKotlin.kt:7:1: Line detected, which is longer than the defined maximum line length in the code style. [MaxLineLength]
/Volumes/source/ai/autocrud/docs/test-scripts/linter-tests/BadKotlin.kt:17:13: This expression contains a magic number. Consider defining it to a well named constant. [MagicNumber]
/Volumes/source/ai/autocrud/docs/test-scripts/linter-tests/BadKotlin.kt:10:41: Function parameter `param2` is unused. [UnusedParameter]
Analysis failed with 4 weighted issues.
    """.trimIndent()
    
    val detektIssues = DetektLinter.parseDetektOutput(detektOutput, "BadKotlin.kt")
    println("Found ${detektIssues.size} issues:")
    detektIssues.forEach { issue ->
        println("  Line ${issue.line}, Col ${issue.column}: [${issue.rule}] ${issue.message}")
    }
    
    println("\n=== Testing PMDLinter.parsePMDOutput ===")
    val pmdOutput = """
[WARN] Progressbar rendering conflicts with reporting to STDOUT.
BadJava.java:7: UnusedLocalVariable:    Avoid unused local variables such as 'x'.
BadJava.java:8: UnusedLocalVariable:    Avoid unused local variables such as 'y'.
BadJava.java:13:        UnconditionalIfStatement:       Do not use if statements that are always true or always false
BadJava.java:13:        EmptyControlStatement:  Empty if statement
    """.trimIndent()
    
    val pmdIssues = PMDLinter.parsePMDOutput(pmdOutput, "BadJava.java")
    println("Found ${pmdIssues.size} issues:")
    pmdIssues.forEach { issue ->
        println("  Line ${issue.line}, Col ${issue.column}: [${issue.rule}] ${issue.message}")
    }
}

main()
