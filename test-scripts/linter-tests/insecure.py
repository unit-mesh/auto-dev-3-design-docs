#!/usr/bin/env python3
"""File with security issues for Semgrep testing"""

import pickle
import yaml
import subprocess
import os

# Insecure deserialization
def load_data(data):
    return pickle.loads(data)  # Security issue

# Command injection
def run_command(user_input):
    os.system("ls " + user_input)  # Command injection

# SQL injection
def get_user(username):
    query = "SELECT * FROM users WHERE username = '" + username + "'"
    return query

# Hardcoded secret
API_KEY = "sk-1234567890abcdef"
PASSWORD = "admin123"

# Insecure random
import random
token = random.random()

# Using eval
def execute_code(code):
    eval(code)  # Dangerous

