// Bad JavaScript file for ESLint testing

var x = 1;  // Should use const or let
console.log(x)

function test() {
    var y = 2;
    if (true) {
        var z = 3;  // Should use let
    }
    console.log(y);
}

// Missing semicolon
const a = 1

// Unused variable
const unused = "test";

// == instead of ===
if (a == "1") {
    console.log("equal")
}

// Trailing comma
const obj = {
    key1: "value1",
    key2: "value2",
}

// console.log in production code
console.log("Debug info");

test()

