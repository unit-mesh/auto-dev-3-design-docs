import org.treesitter.TSParser
import org.treesitter.TreeSitterKotlin

fun main() {
    val sourceCode = """
        package com.example
        
        class Calculator {
            fun add(a: Int, b: Int): Int {
                return a + b
            }
        }
    """.trimIndent()
    
    val parser = TSParser()
    parser.language = TreeSitterKotlin()
    val tree = parser.parseString(null, sourceCode)
    val rootNode = tree.rootNode
    
    printNode(rootNode, sourceCode, 0)
}

fun printNode(node: org.treesitter.TSNode, sourceCode: String, depth: Int) {
    val indent = "  ".repeat(depth)
    val text = sourceCode.substring(node.startByte, minOf(node.endByte, node.startByte + 50))
        .replace("\n", "\\n")
    println("$indent${node.type}: $text")
    
    for (i in 0 until node.childCount) {
        val child = node.getChild(i) ?: continue
        printNode(child, sourceCode, depth + 1)
    }
}

