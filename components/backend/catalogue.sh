#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="catalogue"
PACKAGE="nodejs"
VERSION="20"
SERVICE=$COMPONENT

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
enable_custom_runtime $PACKAGE $VERSION
install_runtime $PACKAGE
install_dependencies $PACKAGE

## Step 4: Service Management
setup_systemd_service $SERVICE
enable_service $SERVICE
start_service $SERVICE

## Step 5: Application Specific Steps
log_echo "Executing application specific steps ..."

### MongoDB Setup
create_repo "mongo"
install_runtime "mongodb-mongosh"

### Load masterdata into MongoDB
log_echo "Loading masterdata into MongoDB ..."

INDEX=$(mongosh mongodb.svd-learn-devops.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ -z "$INDEX" ] || ! [[ "$INDEX" =~ ^-?[0-9]+$ ]]; then
    INDEX=-1
fi

if [ $INDEX -lt 0 ]; then
    log_exec mongosh --host mongodb.svd-learn-devops.fun </app/db/master-data.js
    log_echo "Loading masterdata into MongoDB ... ${G}SUCCESS${N}"
else
    log_echo "Masterdata already loaded"
    log_echo "Loading masterdata into MongoDB ... ${Y}SKIPPING${N}"
fi

### Restart Service
restart_service $SERVICE

log_echo "Executing application specific steps ... ${G}SUCCESS${N}"

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
