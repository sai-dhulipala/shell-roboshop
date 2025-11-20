#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="redis"
PACKAGE=$COMPONENT
VERSION="7"
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
setup_error_handler

# Start script execution
START_TIME=$(date +%s)
log_echo "Script started at: $(date)"

## Step 1: Package Management
enable_custom_runtime $PACKAGE $VERSION
install_runtime $PACKAGE

## Step 2: Change bind address in redis.conf to allow remote connections
log_echo "Allowing remote connections to redis ..."
log_exec sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf
log_echo "Allowing remote connections to redis ... ${G}SUCCESS${N}"

## Step 3: Update protected-mode from yes to no
log_echo "Updating Protected Mode from Yes to No ..."
log_exec sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf
log_echo "Updating Protected Mode from Yes to No ... ${G}SUCCESS${N}"

## Step 4: Service Management
reload_systemd
enable_service $SERVICE
start_service $SERVICE

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
