#!/usr/bin/env kotlin

/**
 * Debug script to test tool call parsing
 */

import cc.unitmesh.agent.parser.ToolCallParser

fun main() {
    val parser = ToolCallParser()
    
    // Test cases from the log
    val testCases = listOf(
        // Case 1: Shell command with gradle
        """
        <devin>
        /shell ./gradlew build
        </devin>
        """.trimIndent(),
        
        // Case 2: Write file with content
        """
        <devin>
        /write-file path="src/main/java/cc/unitmesh/untitled/demo/controller/HelloWorldController.java" content="package cc.unitmesh.untitled.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloWorldController {
    
    @GetMapping(\"/hello\")
    public String hello() {
        return \"Hello World!\";
    }
}"
        </devin>
        """.trimIndent(),
        
        // Case 3: Direct shell command without devin blocks
        "/shell ./gradlew build",
        
        // Case 4: Shell command with parameters
        """
        <devin>
        /shell command="./gradlew build" workingDirectory="/tmp/test-coding-agent"
        </devin>
        """.trimIndent()
    )
    
    testCases.forEachIndexed { index, testCase ->
        println("=== Test Case ${index + 1} ===")
        println("Input:")
        println(testCase)
        println("\nParsed Tool Calls:")
        
        val toolCalls = parser.parseToolCalls(testCase)
        if (toolCalls.isEmpty()) {
            println("  No tool calls found!")
        } else {
            toolCalls.forEach { toolCall ->
                println("  Tool: ${toolCall.toolName}")
                println("  Params: ${toolCall.params}")
            }
        }
        println()
    }
}
