#!/bin/bash

#### Read all lines from output to a variable.
VAR=`ls -1`
VAR=$(ls -1)
VAR="$(ls -1)"

# Output will be in $VAR. To show it, use this command.
echo "$VAR"

# Double quotes are required to display all lines in seperate lines. If not have double quotes, all lines will be displayed in one line, seperate by space.

#### Read all lines to array
readarray -t ARR <<<"$VAR"

#### Access array
echo ${ARR[0]}

#### For all items in an array
for ITEM in "${ARR[@]}"
do
   echo "$ITEM"
done
