#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="rabbitmq"
REPO=$COMPONENT
PACKAGE="rabbitmq-server"
SERVICE=$PACKAGE

# Import common variables and functions
source "$SCRIPT_DIR/../../utils/variables.conf"
source "$SCRIPT_DIR/../../utils/functions.sh"

# Script Initialization
## A. Validate user
validate_user

## B. Setup logging
setup_logging

## C. Setup Error Handling
setup_error_handler

# Start script execution
START_TIME=$(date +%s)
log_echo "Script started at: $(date)"

## Step 1: Package Management
create_repo $REPO
install_runtime $PACKAGE

## Step 2: Service Management
enable_service $SERVICE
start_service $SERVICE

## Step 3: Create Roboshop user
log_echo "Creating roboshop user ..."
if rabbitmqctl list_users &> /dev/null | grep -q "^roboshop\s"
then
    log_echo "RabbitMQ user 'roboshop' already exists"
    log_exec rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    log_echo "Creating roboshop user ... ${Y}SKIPPING${N}"
else
    log_exec rabbitmqctl add_user roboshop roboshop123
    log_exec rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    log_echo "Creating roboshop user ... ${G}SUCCESS${N}"
fi

### Restart Service
restart_service $SERVICE

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
