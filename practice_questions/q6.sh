#!/bin/bash

N="\e[0m"
R="\e[31m"
G="\e[32m"

# echo -e means print with interpretation of backslash escapes, similar to print in Python
# Without -e, it would print like r-strings in Python

echo -e "${G}SUCCESS${N}"
echo -e "${R}FAILURE${N}"