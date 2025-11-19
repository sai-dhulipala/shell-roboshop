#!/bin/bash
set -euo pipefail

# Color code configuration
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Log Directory configuration
LOGS_DIR="/var/log/shell-roboshop"
mkdir -p $LOGS_DIR

SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="${LOGS_DIR}/${SCRIPT_NAME}.log"

# User Validation
USERID=$(id -u)

if [ $USERID -ne 0 ]
then
    echo -e "${R}ERROR${N}: Please run the script with root privileges" | tee -a $LOG_FILE
    exit 1
fi

# Error Handler configuration
error_handler() {
    echo -e "${R}Error${N} at line $1: $2" | tee -a "$LOG_FILE"
    echo "Exit code: $3" | tee -a "$LOG_FILE"
    exit 1
}

trap 'error_handler $LINENO "$BASH_COMMAND" $?' ERR

# Initialize
echo "Script started at: $(date)"| tee -a $LOG_FILE

UTILS_DIR='../utils'

# Step 1: Disable NodeJS
dnf module disable nodejs -y &>> $LOG_FILE
echo -e "Disabling default NodeJS ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Enable NoteJS:20
dnf module enable nodejs:20 -y &>> $LOG_FILE
echo -e "Enabling NodeJS:20 ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Install NodeJS
dnf install nodejs -y &>> $LOG_FILE
echo -e "Installing NodeJS ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Add application user 'roboshop'
if ! id roboshop &> /dev/null
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    echo -e "Adding application user 'roboshop' ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
else
    echo "User 'Roboshop' already exists" &>> $LOG_FILE
    echo -e "Adding application user 'roboshop' ... ${Y}SKIPPING${N}" | tee -a $LOG_FILE
fi

# Step 5: Create directory '/app'
mkdir -p /app &>> $LOG_FILE
echo -e "Creating '/app' directory ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 6: Download source code to tmp
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
echo -e "Downloading source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 7: Extract source code
cd /app &>> $LOG_FILE

# We are doing this to ensure idempotency,
# meaning even if we run the script twice, it should be working fine
rm -rf /app/* &>> $LOG_FILE
unzip /tmp/catalogue.zip &>> $LOG_FILE
echo -e "Extracting source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 8: Install dependencies
npm install &>> $LOG_FILE
echo -e "Installing dependencies ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 9: Setup SystemD Catalogue Service
cp $UTILS_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
echo -e "Setting up SystemD Catalogue Service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 10: Reload SystemD
systemctl daemon-reload &>> $LOG_FILE
echo -e "Reload SystemD ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 11: Enable and Start Service
systemctl enable catalogue &>> $LOG_FILE
echo -e "Enabling catalogue ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start catalogue &>> $LOG_FILE
echo -e "Starting catalogue ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 12: Setup MongoDB repo
cp $UTILS_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
echo -e "Setting up MongoDB repo ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 13: Install MongoDB Client
dnf install mongodb-mongosh -y &>> $LOG_FILE
echo -e "Installing MongoDB Client ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 14: Load masterdata into MongoDB
INDEX=$(mongosh mongodb.svd-learn-devops.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

# Check if INDEX is empty or not a number
if [ -z "$INDEX" ] || ! [[ "$INDEX" =~ ^-?[0-9]+$ ]]
then
    INDEX=-1  # Set to -1 to trigger data loading
fi

if [ $INDEX -lt 0 ]
then
    mongosh --host mongodb.svd-learn-devops.fun </app/db/master-data.js &>> $LOG_FILE
    echo -e "Loading masterdata into MongoDB ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
else
    echo "Masterdata already loaded" &>> $LOG_FILE
    echo -e "Loading masterdata into MongoDB ... ${Y}SKIPPING${N}"  | tee -a $LOG_FILE
fi

# Step 15: Restart Service
systemctl restart catalogue &>> $LOG_FILE
echo -e "Restarting catalogue ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)"| tee -a $LOG_FILE
