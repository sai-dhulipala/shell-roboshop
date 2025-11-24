#!/bin/bash
set -euo pipefail

# Set script variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )

# Import common variables and functions
source "$SCRIPT_DIR/utils/variables.conf"
source "$SCRIPT_DIR/utils/functions.sh"

# Import component functions
source "$SCRIPT_DIR/components/db.sh"
source "$SCRIPT_DIR/components/backend.sh"
source "$SCRIPT_DIR/components/frontend.sh"

# Script Initialization
validate_user
setup_logging
trap 'error_handler $LINENO "$BASH_COMMAND" $?' ERR

# Set component and subcomponent variables
COMPONENT=$1
SUB_COMPONENT=${2:-""}

# Start script execution
START_TIME=$(date +%s)
log_echo "Script started at: $(date)"

case $COMPONENT in
    "frontend")
        deploy_frontend
        ;;
    "backend")
        deploy_backend $SUB_COMPONENT
        ;;
    "db")
        deploy_db $SUB_COMPONENT
        ;;
    *)
        log_echo "Invalid component specified: $COMPONENT"
        exit 1
        ;;
esac

# End script execution
END_TIME=$(date +%s)
log_echo "Script ended at: $(date)"
log_echo "Total execution time: $(($END_TIME - $START_TIME)) seconds"
