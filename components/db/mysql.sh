#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="mysql"
PACKAGE="mysql-server"
SERVICE="mysqld"

# Import common variables and functions
source "$SCRIPT_DIR/../../utils/variables.conf"
source "$SCRIPT_DIR/../../utils/functions.sh"

# Script Initialization
## A. Validate user
validate_user

## B. Setup logging
setup_logging

## C. Setup Error Handling
trap 'error_handler $LINENO "$BASH_COMMAND" $?' ERR

# Start script execution
START_TIME=$(date +%s)
log_echo "Script started at: $(date)"

## Step 1: Package Management
install_runtime $PACKAGE

## Step 2: Service Management
enable_service $SERVICE
start_service $SERVICE

## Step 3: Set root user password
log_echo "Setting root user password ..."
log_exec mysql_secure_installation --set-root-pass RoboShop@1
log_echo "Setting root user password ... ${G}SUCCESS${N}"

## Step 4: Restart Service
restart_service $SERVICE

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
