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
MYSQL_IP="mysql.svd-learn-devops.fun"

# Step 1: Install Maven
dnf install maven -y &>> $LOG_FILE
echo -e "Installing Maven ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 2: Add application user 'roboshop'
if ! id roboshop &> /dev/null
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    echo -e "Adding application user 'roboshop' ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
else
    echo "User 'Roboshop' already exists" &>> $LOG_FILE
    echo -e "Adding application user 'roboshop' ... ${Y}SKIPPING${N}" | tee -a $LOG_FILE
fi

# Step 3: Create directory '/app'
mkdir -p /app &>> $LOG_FILE
echo -e "Creating '/app' directory ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 4: Download source code to tmp
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
echo -e "Downloading source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 5: Extract source code
cd /app &>> $LOG_FILE

# We are doing this to ensure idempotency,
# meaning even if we run the script twice, it should be working fine
rm -rf /app/* &>> $LOG_FILE
unzip /tmp/shipping.zip &>> $LOG_FILE
echo -e "Extracting source code ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 6: Download dependencies and build application
mvn clean package &>> $LOG_FILE
mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
echo -e "Downloading dependencies and building applications ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 7: Setup SystemD Shipping Service
cp $UTILS_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
echo -e "Setting up SystemD Shipping Service ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 8: Reload SystemD
systemctl daemon-reload &>> $LOG_FILE
echo -e "Reload SystemD ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 9: Enable and Start Service
systemctl enable shipping &>> $LOG_FILE
echo -e "Enabling Shipping ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

systemctl start shipping &>> $LOG_FILE
echo -e "Starting Shipping ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 10: Install MySQL Client
dnf install mysql -y &>> $LOG_FILE
echo -e "Installing MySQL Client ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 11: Load schema, Create app user and load master data
mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOG_FILE
echo -e "Loading Schema ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOG_FILE
echo -e "Creating App User ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOG_FILE
echo -e "Loading Master Data ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

# Step 12: Restart Shipping Sevice
systemctl restart shipping &>> $LOG_FILE
echo -e "Restarting Shipping ... ${G}SUCCESS${N}" | tee -a $LOG_FILE

echo "Script ended at: $(date)" | tee -a $LOG_FILE
