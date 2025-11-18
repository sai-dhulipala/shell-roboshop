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

# Step 4: Disable NodeJS
dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling default NodeJS"

# Step 5: Enable NoteJS:20
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS:20"

# Step 6: Install NodeJS
dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing NodeJS"

# Step 7: Add application user 'roboshop'
# Check if user exists -> if not then create the user -> else skip

id roboshop &>> $LOG_FILE

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "Adding application user `roboshop`"
else
    echo "User `Roboshop` already exists" &>> $LOG_FILE
    echo -e "Adding application user `roboshop` ... ${Y}SKIPPING${N}" | tee -a $LOG_FILE
fi

# Step 8: Create directory '/app'
mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating `/app` directory"

# Step 9: Download source code to tmp
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading source code"

# Step 10: Extract source code
cd /app &>> $LOG_FILE

# We are doing this to ensure idempotency, meaning even if we run the script twice, it should be working fine
rm -rf /app/* &>> $LOG_FILE

unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "Extracting source code"

# Step 11: Install dependencies
npm install &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

# Step 12: Setup SystemD Catalogue Service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
VALIDATE $? "Setting up SystemD Catalogue Service"

# Step 13: Enable and Start Service
systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue &>> $LOG_FILE
VALIDATE $? "Starting catalogue"

# Step 14: Setup MongoDB repo
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? "Setting up MongoDB repo"

# Step 15: Install MongoDB Client
dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB Client"

# Step 16: Load masterdata into MongoDB
INDEX=$(mongosh mongodb.svd-learn-devops.fun --quite --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -lt 0 ]
then
    mongosh --host mongodb.svd-learn-devops.fun </app/db/master-data.js &>> $LOG_FILE
    VALIDATE $? "Loading masterdata into MongoDB"
else
    echo "Masterdata already loaded" &>> $LOG_FILE
    echo -e "Loading masterdata into MongoDB ${Y}SKIPPING${N}"  | tee -a $LOG_FILE
fi

# Step 17: Restart Service
systemctl restart catalogue &>> $LOG_FILE
VALIDATE $? "Restarting catalogue"

echo "Script ended at: $(date)"| tee -a $LOG_FILE
