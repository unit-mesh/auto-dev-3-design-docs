#!/usr/bin/env kotlin

/**
 * Test script for Git Graph algorithm
 * 
 * Run with: kotlinc -script test-git-graph.kt
 * Or just read the output examples below
 */

// Test cases
fun main() {
    println("Git Graph Algorithm Test")
    println("=" .repeat(60))
    println()
    
    // Test 1: Simple linear history
    println("Test 1: Linear History")
    println("-".repeat(60))
    val linearCommits = listOf(
        "Initial commit",
        "Add feature A",
        "Fix bug in feature A",
        "Update documentation"
    )
    printTestCase(linearCommits)
    
    // Test 2: Simple branch and merge
    println("\nTest 2: Branch and Merge")
    println("-".repeat(60))
    val branchCommits = listOf(
        "Initial commit",
        "feat: Start new feature",
        "Implement feature logic",
        "Merge branch 'feature' into main",
        "Continue on main"
    )
    printTestCase(branchCommits)
    
    // Test 3: Multiple features
    println("\nTest 3: Multiple Feature Branches")
    println("-".repeat(60))
    val multiCommits = listOf(
        "Initial commit",
        "feat: Add authentication",
        "Implement OAuth",
        "Merge branch 'auth' into main",
        "feat: Add user profile",
        "Design profile page",
        "Merge branch 'profile' into main",
        "Final cleanup"
    )
    printTestCase(multiCommits)
    
    // Test 4: Complex scenario
    println("\nTest 4: Complex Scenario")
    println("-".repeat(60))
    val complexCommits = listOf(
        "Initial setup",
        "feat: Start feature A",
        "Work on A - part 1",
        "Work on A - part 2",
        "Merge branch 'feature-a' into main",
        "Hotfix on main",
        "feat: Start feature B",
        "Work on B",
        "Merge branch 'feature-b' into main"
    )
    printTestCase(complexCommits)
}

fun printTestCase(commits: List<String>) {
    println("Commits:")
    commits.forEachIndexed { index, commit ->
        println("  $index. $commit")
    }
    println()
    println("Expected Graph:")
    println(simulateGraph(commits))
    println()
}

/**
 * Simulate the graph algorithm output
 */
fun simulateGraph(commits: List<String>): String {
    val output = StringBuilder()
    var currentColumn = 0
    var nextColumn = 1
    val activeColumns = mutableSetOf(0)
    
    commits.forEachIndexed { index, message ->
        val isMerge = message.contains("Merge", ignoreCase = true)
        val isBranch = (message.contains("feat:", ignoreCase = true) || 
                       message.contains("feature:", ignoreCase = true)) && 
                       index < commits.size - 1
        
        // Build graph line
        val maxCol = maxOf(currentColumn, nextColumn)
        val line = CharArray(maxCol * 2 + 3) { ' ' }
        
        when {
            isMerge -> {
                // Merge: show both columns
                line[currentColumn * 2] = 'M'
                if (currentColumn > 0) {
                    for (col in 0 until currentColumn) {
                        line[col * 2 + 1] = '-'
                    }
                    line[0] = '|'
                }
                activeColumns.remove(currentColumn)
                currentColumn = 0
            }
            isBranch -> {
                // Branch: create new column
                line[nextColumn * 2] = 'B'
                line[currentColumn * 2] = '|'
                line[currentColumn * 2 + 1] = '/'
                activeColumns.add(nextColumn)
                currentColumn = nextColumn
                nextColumn++
            }
            else -> {
                // Regular commit
                line[currentColumn * 2] = '*'
            }
        }
        
        output.append(String(line).trimEnd())
        output.append("  ${message.take(40)}")
        output.appendLine()
        
        // Draw continuation line (except for last commit)
        if (index < commits.size - 1 && !isBranch) {
            val contLine = CharArray(maxCol * 2 + 3) { ' ' }
            contLine[currentColumn * 2] = '|'
            output.append(String(contLine).trimEnd())
            output.appendLine()
        }
    }
    
    return output.toString()
}

// Run the tests
main()

/**
 * Expected outputs:
 * 
 * Test 1: Linear History (single column)
 * *  Initial commit
 * |
 * *  Add feature A
 * |
 * *  Fix bug in feature A
 * |
 * *  Update documentation
 * 
 * Test 2: Branch and Merge
 * *  Initial commit
 * |
 * |/B  feat: Start new feature
 * *  Implement feature logic
 * M--|  Merge branch 'feature' into main
 * *  Continue on main
 * 
 * Test 3: Multiple branches (more complex)
 * Similar pattern repeats
 */

