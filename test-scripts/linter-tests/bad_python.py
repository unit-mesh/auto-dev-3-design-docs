def unused_function():
    x = 1  # Unused variable
    y = 2  # Another unused
    print("Hello")

def long_function():
    """This function is intentionally long"""
    line1 = "This is a very long line that exceeds the maximum line length and should trigger a warning about line length being too long"
    print(line1)
    
# Missing type hints
def add(a, b):
    return a + b
