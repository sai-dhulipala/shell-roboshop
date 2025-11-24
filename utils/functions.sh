#!/bin/bash

# A. Base functions
validate_user() {
    if [ $(id -u) -ne 0 ]
    then
        echo -e "${R}ERROR${N}: Please run the script with root privileges"
        exit 1
    fi
}

show_usage() {
    echo -e "${Y}Usage${N}: $0 <component> [sub-component] ...\n${Y}Valid combinations${N}:"
    for comp in "${!VALID_SUBCOMPONENTS[@]}"; do
        echo -e "  $comp → ${VALID_SUBCOMPONENTS[$comp]:-'(no sub-component needed)'}"
    done
}

validate_args() {
    [[ $# -lt 1 ]] && { echo -e "${R}Error${N}: No arguments provided"; show_usage; exit 1; }

    local component=$1 valid_subs="${VALID_SUBCOMPONENTS[$1]}"
    shift

    # Validate component exists
    [[ -z "${VALID_SUBCOMPONENTS[$component]+isset}" ]] && {
        echo -e "${R}Error${N}: Invalid component '$component'\n${Y}Valid components${N}: ${!VALID_SUBCOMPONENTS[*]}"
        exit 1
    }

    # Handle components with/without sub-components
    if [[ -z "$valid_subs" ]]; then
        [[ $# -gt 0 ]] && echo -e "${Y}Warning${N}: '$component' doesn't require sub-components, ignoring: $*"
    else
        [[ $# -lt 1 ]] && {
            echo -e "${R}Error${N}: '$component' requires at least one sub-component\n${Y}Valid sub-components${N}: $valid_subs"
            exit 1
        }
        # Validate each sub-component
        for sub in "$@"; do
            [[ ! " $valid_subs " =~ " $sub " ]] && {
                echo -e "${R}Error${N}: Invalid sub-component '$sub' for '$component'\n${Y}Valid sub-components${N}: $valid_subs"
                exit 1
            }
        done
    fi
}

setup_logging() {
    mkdir -p $LOGS_DIR
    LOG_FILE="${LOGS_DIR}/${SCRIPT_NAME}.log"
}

log_echo() {
    echo -e $1 | tee -a "$LOG_FILE"
}

log_exec() {
    "$@" &>> "$LOG_FILE"
}

error_handler() {
    log_echo "${R}Error${N} at line ${1}: ${2}"
    log_echo "Exit code: ${3}"
    exit 1
}

# B. Source code management functions
setup_source_code() {
    local component=$1

    # Step 1: Download source code to tmp
    log_echo "Downloading source code ..."
    log_exec curl -L -o /tmp/${component}.zip https://roboshop-artifacts.s3.amazonaws.com/${component}-v3.zip
    log_echo "Downloading source code ... ${G}SUCCESS${N}"

    # Step 2: Create app directory and clean up old content if exists
    if [ "$component" == "frontend" ]; then
        app_dir="/usr/share/nginx/html"
    else
        app_dir="/app"
    fi

    log_echo "Creating '${app_dir}' directory ..."
    log_exec mkdir -p ${app_dir}
    log_exec rm -rf ${app_dir}/*
    log_echo "Creating '${app_dir}' directory ... ${G}SUCCESS${N}"

    # Step 3: Extract source code
    log_echo "Extracting source code ..."
    log_exec cd ${app_dir}
    log_exec unzip /tmp/${component}.zip
    log_echo "Extracting source code ... ${G}SUCCESS${N}"
}

# C. User management functions
add_app_user() {
    log_echo "Adding application user '${APP_USER}' ..."

    if ! id $APP_USER &> /dev/null
    then
        log_exec useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" $APP_USER
        log_echo "Adding application user '${APP_USER}' ... ${G}SUCCESS${N}"
    else
        log_echo "User '${APP_USER}' already exists"
        log_echo "Adding application user '${APP_USER}' ... ${Y}SKIPPING${N}"
    fi
}

# D. Package management functions
create_repo() {
    local repo=$1

    log_echo "Creating ${repo}.repo file ..."
    log_exec cp ${TEMPLATES_DIR}/${repo}.repo /etc/yum.repos.d/${repo}.repo
    log_echo "Creating ${repo}.repo file ... ${G}SUCCESS${N}"
}

enable_custom_runtime() {
    local runtime=$1
    local version=$2

    log_echo "Disabling default ${runtime} ..."
    log_exec dnf module disable ${runtime} -y
    log_echo "Disabling default ${runtime} ... ${G}SUCCESS${N}"

    log_echo "Enabling ${runtime}:${version} ..."
    log_exec dnf module enable ${runtime}:${version} -y
    log_echo "Enabling ${runtime}:${version} ... ${G}SUCCESS${N}"
}

install_runtime() {
    local runtime=$1

    log_echo "Installing ${runtime} ..."
    log_exec dnf install "${runtime}" -y
    log_echo "Installing ${runtime} ... ${G}SUCCESS${N}"
}

install_dependencies() {
    local component=$1

    log_echo "Installing dependencies ..."
    log_exec cd /app

    if [ "${component}" == "shipping" ]; then
        log_exec mvn clean package
        log_exec mv target/${component}-1.0.jar ${component}.jar
    elif [ "${component}" == "dispatch" ]; then
        log_exec go mod init dispatch
        log_exec go get
        log_exec go build
    elif [ "${component}" == "payment" ]; then
        log_exec pip3 install -r requirements.txt
    else
        log_exec npm install
    fi

    log_echo "Installing dependencies ... ${G}SUCCESS${N}"
}

# E. Service management functions
reload_systemd() {
    log_echo "Reloading SystemD ..."
    log_exec systemctl daemon-reload
    log_echo "Reloading SystemD ... ${G}SUCCESS${N}"
}

setup_systemd_service() {
    local component=$1

    log_echo "Setting up SystemD ${component} Service ..."
    log_exec cp ${TEMPLATES_DIR}/${component}.service /etc/systemd/system/${component}.service
    log_echo "Setting up SystemD ${component} Service ... ${G}SUCCESS${N}"

    reload_systemd
}

enable_service() {
    local component=$1

    log_echo "Enabling ${component} service ..."
    log_exec systemctl enable ${component}
    log_echo "Enabling ${component} service ... ${G}SUCCESS${N}"
}

start_service() {
    local component=$1

    log_echo "Starting ${component} service ..."
    log_exec systemctl start ${component}
    log_echo "Starting ${component} service ... ${G}SUCCESS${N}"
}

restart_service() {
    local component=$1

    log_echo "Restarting ${component} ..."
    log_exec systemctl restart ${component}
    log_echo "Restarting ${component} ... ${G}SUCCESS${N}"
}
