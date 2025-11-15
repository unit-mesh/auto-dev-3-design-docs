#!/usr/bin/env python3
"""Bad Python file for Pylint testing"""

import os
import sys
import json  # Unused import

# Missing module docstring for some functions

def test_function():
    x = 1
    y = 2  # Unused variable
    return x

class TestClass:
    def __init__(self):
        self.value = 1
    
    def method(self, arg1):
        """Method with unused argument"""
        return self.value

# Line too long
very_long_line = "This is a very long line that exceeds the maximum line length and should trigger a pylint warning about line length conventions"

# Too many blank lines




def another_function():
    pass

# Invalid name (should be snake_case)
InvalidName = "test"

# Missing final newline
