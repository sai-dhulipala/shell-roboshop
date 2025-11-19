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

# Step 1: Disable Nginx
dnf module disable nginx -y &>> $LOG_FILE
echo -e "Disabling default Nginx ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Enable Nginx:1.24
dnf module enable nginx:1.24 -y &>> $LOG_FILE
echo -e "Enabling Nginx:1.24 ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Install Nginx
dnf install nginx -y &>> $LOG_FILE
echo -e "Installing Nginx ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Enable and Start Nginx
systemctl enable nginx &>> $LOG_FILE
echo -e "Enabling Nginx ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start nginx &>> $LOG_FILE
echo -e "Starting Nginx ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 5: Download source code to tmp
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
echo -e "Downloading source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 6: Extract source code
cd /usr/share/nginx/html &>> $LOG_FILE
rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
echo -e "Removing default Nginx HTML content ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

unzip /tmp/frontend.zip &>> $LOG_FILE
echo -e "Extracting source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 7: Replace Nginx.conf with modified configuration
rm -rf /etc/nginx/nginx.conf &>> $LOG_FILE
cp $UTILS_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
echo -e "Replacing Nginx.conf with modified configuration ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 8: Reload SystemD
systemctl daemon-reload &>> $LOG_FILE
echo -e "Reload SystemD ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 9: Restart Nginx
systemctl restart nginx &>> $LOG_FILE
echo -e "Restarting Nginx ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)" | tee -a $LOG_FILE
