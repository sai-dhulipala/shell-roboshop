#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="mongodb"
REPO="mongo"
PACKAGE="mongodb-org"
SERVICE="mongod"

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

### Change bind address in mongod.conf to allow remote connections
log_echo "Allowing remote connections to MongoDB ..."
log_exec sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
log_echo "Allowing remote connections to MongoDB ... ${G}SUCCESS${N}"

### Restart Service
restart_service $SERVICE

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
