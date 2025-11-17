#!/bin/bash

if [ -e $1 -eq 0 ]
then
    echo "${1}: File exists"
else
    echo "${1}: File doesn't exists"
fi