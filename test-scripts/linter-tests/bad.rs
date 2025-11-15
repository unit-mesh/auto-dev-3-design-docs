// Bad Rust file for Clippy testing

fn main() {
    let x = 1;
    let y = 2;  // Unused variable
    println!("{}", x);
    
    // Unnecessary clone
    let s = String::from("hello");
    let _t = s.clone();
    println!("{}", s);
    
    // Needless return
    let _result = add(1, 2);
}

fn add(a: i32, b: i32) -> i32 {
    return a + b;  // Clippy suggests removing 'return'
}

// Missing documentation
pub fn public_function() {
    let vec = vec![1, 2, 3];
    // Unnecessary iter call
    for i in vec.iter() {
        println!("{}", i);
    }
}

