package test

// This file has intentional code style issues for detekt testing

class BadKotlin {
    fun veryLongFunctionNameThatExceedsTheRecommendedLengthAndShouldTriggerDetektWarningAboutNamingConventions() {
        println("This is a very long line that exceeds the maximum line length and should trigger a detekt warning about line length being too long and should be split into multiple lines")
    }
    
    fun unusedParameter(param1: String, param2: Int) {
        // param2 is never used
        println(param1)
    }
    
    var x = 1
    var y = 2
    var z = 3
}
