#!/bin/bash
# Test script for TaskBoundaryTool with improved prompts

cd /Volumes/source/ai/autocrud/mpp-ui

echo "========================================="
echo "Testing TaskBoundaryTool"
echo "========================================="
echo ""
echo "Running complex task that should trigger task-boundary..."
echo ""

node dist/jsMain/typescript/index.js code \
  --path /Users/phodal/IdeaProjects/untitled \
  --task "Build a complete user authentication system with: 1) User entity with email/password, 2) Registration endpoint with email validation, 3) Login endpoint that returns JWT tokens, 4) Password reset flow with email, 5) User profile CRUD endpoints, 6) Admin and User roles, 7) JWT-based security filter, 8) Global exception handler, 9) Input validation for all requests, 10) Unit tests for services" \
  2>&1 | head -300

echo ""
echo "========================================="
echo "Check above for task-boundary tool calls"
echo "Look for lines like: ● task-boundary"
echo "========================================="

