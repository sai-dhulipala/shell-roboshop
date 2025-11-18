#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_DIR="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="${LOGS_DIR}/${SCRIPT_NAME}.log"
SCRIPT_DIR=$PWD

# Step 1: Create logs directory if not exists
mkdir -p $LOGS_DIR
echo "Script started at: $(date)"| tee -a $LOG_FILE

# Step 2: Check for root user privileges
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run the script with root privileges" | tee -a $LOG_FILE
    exit 1
fi

# Step 3: Function to validate the status of the previous command
VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R}FAILURE${N}" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "${2} ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
    fi
}

# Step 4: Copy mongo.repo to yum.repos.d
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? "Copying mongo.repo file"

# Step 5: Install MongoDB
dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB"

# Step 6: Start and enable MongoDB service
systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "Enabling MongoDB service"

systemctl start mongod &>> $LOG_FILE
VALIDATE $? "Starting MongoDB service"

# Step 7: Change bind address in mongod.conf to allow remote connections
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "Allowing remote connections to MongoDB"

# Step 8: Restart MongoDB
systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "Restarting MongoDB service"

echo "Script ended at: $(date)"| tee -a $LOG_FILE
