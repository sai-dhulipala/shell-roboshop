#!/bin/bash

dnf list installed mysql

if [ $? -eq 0 ]
then
    echo "MySQL is installed."
else
    echo "MySQL is not installed."
fi
