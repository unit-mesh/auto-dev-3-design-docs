import Foundation

// Long line violation
let veryLongVariableName = "This is a very long string that exceeds the recommended line length limit and should be wrapped"

// Force unwrapping
let name: String? = "John"
print(name!)

// Unused variable
let unusedVariable = 42

// Trailing whitespace   
let value = 10  

// Missing documentation
class MyClass {
    var property: String
    
    init(property: String) {
        self.property = property
    }
    
    // Force cast
    func doSomething(obj: Any) {
        let str = obj as! String
        print(str)
    }
}

// Multiple empty lines


// Violation
func badFunction( ){
    print("Bad spacing")
}

// Implicit getter
class AnotherClass {
    var name: String {
        get {
            return "name"
        }
    }
}

