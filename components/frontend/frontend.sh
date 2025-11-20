#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
COMPONENT="frontend"
PACKAGE="nginx"
VERSION="1.24"
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
enable_custom_runtime $PACKAGE $VERSION
install_runtime $PACKAGE

## Step 2: Service Management
enable_service $SERVICE
start_service $SERVICE

## Step 3: Source Code Management
setup_source_code $COMPONENT

## Step 4: Replace nginx.conf with modified configuration
log_echo "Replacing nginx.conf with modified configuration ..."
log_exec rm -rf /etc/nginx/nginx.conf
log_exec cp $TEMPLATES_DIR/nginx.conf /etc/nginx/nginx.conf
log_echo -e "Replacing nginx.conf with modified configuration ... ${G}SUCCESS${N}"

## Step 5: Restart Service
reload_systemd
restart_service $SERVICE

log_echo "Executing application specific steps ... ${G}SUCCESS${N}"

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
