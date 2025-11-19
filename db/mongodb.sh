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
echo "Script started at: $(date)" | tee -a $LOG_FILE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"

# Step 1: Copy mongo.repo to yum.repos.d
cp $UTILS_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
echo -e "Copying mongo.repo file ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Install MongoDB
dnf install mongodb-org -y &>> $LOG_FILE
echo -e "Installing MongoDB ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Start and enable MongoDB service
systemctl enable mongod &>> $LOG_FILE
echo -e "Enabling MongoDB service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start mongod &>> $LOG_FILE
echo -e "Starting MongoDB service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Change bind address in mongod.conf to allow remote connections
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$LOG_FILE
echo -e "Allowing remote connections to MongoDB ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 5: Restart MongoDB
systemctl restart mongod &>> $LOG_FILE
echo -e "Restarting MongoDB service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)" | tee -a $LOG_FILE
