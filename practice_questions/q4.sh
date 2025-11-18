#!/bin/bash

USER_ID=$(id -u)

if [ "${USER_ID}" -eq 0 ]
then
    echo "You are root user"
else
    echo "You are not root user"
fi