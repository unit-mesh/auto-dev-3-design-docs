package main

import (
	"fmt"
	"os"
	"io"  // unused import
)

func main() {
	// Magic number
	x := 42
	// Unused variable
	y := 10
	
	// Bad error handling
	fmt.Println(x)
	
	// Line too long for some standards
	veryLongVariableName := "This is a very long string that might trigger a line length warning in some linters and configurations"
	fmt.Println(veryLongVariableName)
}

