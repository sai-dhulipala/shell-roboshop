#!/bin/bash

dnf install git -y

if [ $? -eq 0 ]
then
    echo "Git installation successful."
else
    echo "Git installation unsuccessful."
fi