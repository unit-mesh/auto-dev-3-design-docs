package test;

// This file has intentional code style issues for PMD testing

public class BadJava {
    public void unusedVariable() {
        int x = 1; // unused variable
        int y = 2; // unused variable
        System.out.println("Hello");
    }
    
    public void emptyIfStatement() {
        if (true) {
            // empty block
        }
    }
    
    public void longMethod() {
        System.out.println("Line 1");
        System.out.println("Line 2");
        System.out.println("Line 3");
        System.out.println("Line 4");
        System.out.println("Line 5");
        System.out.println("Line 6");
        System.out.println("Line 7");
        System.out.println("Line 8");
        System.out.println("Line 9");
        System.out.println("Line 10");
    }
}
