#!/bin/bash

# Simple Git Graph ASCII Visualization Demo
# Shows expected output patterns

cat << 'EOF'
==============================================================================
Git Graph Algorithm - ASCII Visualization Tests
==============================================================================

Test 1: Linear History (Single Branch)
--------------------------------------
Commits:
  0. Initial commit
  1. Add feature A
  2. Fix bug
  3. Update docs

Expected Graph:
*  Initial commit
|
*  Add feature A
|
*  Fix bug
|
*  Update docs


Test 2: Simple Branch and Merge
--------------------------------
Commits:
  0. Initial commit
  1. feat: Start new feature
  2. Work on feature
  3. Merge branch 'feature' into main
  4. Continue on main

Expected Graph:
*      Initial commit
| /
B      feat: Start new feature
|
*      Work on feature
M      Merge branch 'feature' into main
|
*      Continue on main


Test 3: Multiple Branches
--------------------------
Commits:
  0. Initial commit
  1. feat: Add auth
  2. Work on auth
  3. Merge branch 'auth'
  4. feat: Add profile
  5. Work on profile  
  6. Merge branch 'profile'
  7. Final commit

Expected Graph:
*          Initial commit
| /
B          feat: Add auth
|
*          Work on auth
M          Merge branch 'auth'
| /
B          feat: Add profile
|
*          Work on profile
M          Merge branch 'profile'
|
*          Final commit


Legend:
-------
*  = Regular commit
B  = Branch start
M  = Merge commit  
|  = Vertical line (continue)
/  = Branch line


Algorithm Overview:
-------------------
1. Start with main branch (column 0)
2. When "feat:" detected → create new column, branch off
3. When "Merge" detected → merge current column back to column 0
4. Draw lines connecting commits:
   - Vertical lines for same-column commits
   - Diagonal/curved lines for branching
   - Merge lines for merges

==============================================================================
EOF

