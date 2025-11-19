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

# Step 1: Install MySQL Server
dnf install mysql-server -y &>> $LOG_FILE
echo -e "Installing MySQL Server ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Enable and Start MySQL Service
systemctl enable mysqld &>> $LOG_FILE
echo -e "Enabling MySQL service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start mysqld &>> $LOG_FILE
echo -e "Starting MySQL service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Set root user password
mysql_secure_installation --set-root-pass RoboShop@1
echo -e "Setting root user password ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)" | tee -a $LOG_FILE
