#!/bin/bash

for SERVICE in sshd firewalld NetworkManager
do
    systemctl is-active --quiet $SERVICE
    if [ $? -eq 0 ]
    then
        echo "${SERVICE} is active"
    else
        echo "${SERVICE} is inactive"
    fi
done