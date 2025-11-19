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

# Step 1: Disable Redis
dnf module disable redis -y &>> $LOG_FILE
echo -e "Disabling default Redis ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Enable Redis:7
dnf module enable redis:7 -y &>> $LOG_FILE
echo -e "Enabling Redis:7 ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Install NodeJS
dnf install redis -y &>> $LOG_FILE
echo -e "Installing redis ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Change bind address in redis.conf to allow remote connections
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf &>> $LOG_FILE
echo -e "Allowing remote connections to Redis ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 5: Update protected-mode from yes to no
sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf &>> $LOG_FILE
echo -e "Updating Protected Mode from Yes to No ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 6: Reload SystemD
systemctl daemon-reload &>> $LOG_FILE
echo -e "Reload SystemD ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 7: Enable and Start Redis Service
systemctl enable redis &>> $LOG_FILE
echo -e "Enabling Redis ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start redis &>> $LOG_FILE
echo -e "Starting Redis ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)" | tee -a $LOG_FILE
