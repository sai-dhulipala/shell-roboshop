#!/bin/bash

for SERVICE in sshd firewalld NetworkManager
do
    systemctl is-active --quiet $SERVICE
done