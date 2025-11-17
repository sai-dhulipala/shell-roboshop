#!/bin/bash

NUMBER=$1

if [ $NUMBER > 100 ]
then
    echo "${NUMBER} is a Large Number"
else
    echo "${NUMBER} is a Small Number"
fi