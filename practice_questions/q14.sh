#!/bin/bash

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        "${2} was successful"
    else
        "${2} was unsuccessful"

    fi
}

systemctl start httpd
VALIDATE $? "Starting httpd"

systemctl enable httpd
VALIDATE $? "Enbaling httpd"