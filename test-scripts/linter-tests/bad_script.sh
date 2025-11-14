#!/bin/bash

# This file has intentional shell script issues for shellcheck testing

# Unused variable
UNUSED_VAR="test"

# Command without quotes
echo $HOME

# Missing shebang error would be caught too
for i in `seq 1 10`
do
  echo $i
done

# Double brackets preferred
if [ "$var" == "test" ]; then
    echo "match"
fi
