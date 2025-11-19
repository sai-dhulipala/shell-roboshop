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

# Step 1: Copy rabbitmq.repo to yum.repos.d
cp $UTILS_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOG_FILE
echo -e "Copying rabbitmq.repo file ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Install RabbitMQ Server
dnf install rabbitmq-server -y &>> $LOG_FILE
echo -e "Installing RabbitMQ ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 3: Enable and Start RabbitMQ Server
systemctl enable rabbitmq-server &>> $LOG_FILE
echo -e "Enabling RabbitMQ service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start rabbitmq-server &>> $LOG_FILE
echo -e "Starting RabbitMQ service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Create Roboshop user
# Check if user exists and capture the result
if rabbitmqctl list_users &> /dev/null | grep -q "^roboshop\s"
then
    echo "RabbitMQ user 'roboshop' already exists" &>> $LOG_FILE
    echo -e "Creating roboshop user ... ${Y}SKIPPING${N}" | tee -a $LOG_FILE

    # You might still want to update permissions
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
    echo -e "Updating permissions ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
else
    rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
    echo -e "Creating roboshop user ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
fi

echo "Script ended at: $(date)" | tee -a $LOG_FILE
