#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="shipping"
PACKAGE="maven"
SERVICE=$COMPONENT
MYSQL_IP="mysql.svd-learn-devops.fun"

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

## Step 1: Source Code Management
setup_source_code $COMPONENT

## Step 2: User Management
add_app_user $APP_USER

## Step 3: Package Management
install_runtime $PACKAGE
install_dependencies $PACKAGE

## Step 4: Service Management
setup_systemd_service $SERVICE
enable_service $SERVICE
start_service $SERVICE

## Step 5: Application Specific Steps
log_echo "Executing application specific steps ..."

### MySQL Setup
install_runtime "mysql"

### Load schema, Create app user and load masterdata
log_echo "Loading Schema ..."
log_exec mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/schema.sql
log_echo "Loading Schema ... ${G}SUCCESS${N}"

log_echo "Creating App User ..."
log_exec mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/app-user.sql
log_echo "Creating App User ... ${G}SUCCESS${N}"

log_echo "Loading Masterdata ..."
log_exec mysql -h $MYSQL_IP -uroot -pRoboShop@1 < /app/db/master-data.sql
log_echo "Loading Masterdata ... ${G}SUCCESS${N}"

### Restart Service
restart_service $SERVICE

log_echo "Executing application specific steps ... ${G}SUCCESS${N}"

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
