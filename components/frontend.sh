#!/bin/bash

deploy_frontend() {
    local component="frontend"
    local package="nginx"
    local version="1.24"
    local service=$package

    # Step 1: Package Management
    enable_custom_runtime $package $version
    install_runtime $package

    # Step 2: Service Management
    enable_service $service
    start_service $service

    # Step 3: Source Code Management
    setup_source_code $component

    # Step 4: Replace nginx.conf with modified configuration
    log_echo "Replacing nginx.conf with modified configuration ..."
    log_exec rm -rf /etc/nginx/nginx.conf
    log_exec cp ${TEMPLATES_DIR}/nginx.conf /etc/nginx/nginx.conf
    log_echo -e "Replacing nginx.conf with modified configuration ... ${G}SUCCESS${N}"

    # Step 5: Restart Service
    reload_systemd
    restart_service $service
}
