#!/bin/bash

# A. Cart
deploy_cart() {
    local component="cart"
    local package="nodejs"
    local version="20"
    local service=$component

    # Step 1: Source Code Management
    setup_source_code $component

    # Step 2: User Management
    add_app_user

    # Step 3: Package Management
    enable_custom_runtime $package $version
    install_runtime $package
    install_dependencies $component

    # Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service
}

# B. Catalogue
deploy_catalogue() {
    local component="catalogue"
    local package="nodejs"
    local version="20"
    local service=$component

    # Step 1: Source Code Management
    setup_source_code $component

    # Step 2: User Management
    add_app_user

    # Step 3: Package Management
    enable_custom_runtime $package $version
    install_runtime $package
    install_dependencies $component

    # Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service

    # Step 5: Application Specific Steps
    log_echo "Executing application specific steps ..."

    ## 1. MongoDB Setup
    create_repo "mongo"
    install_runtime "mongodb-mongosh"

    ## 2. Load masterdata into MongoDB
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

    ## 3. Restart Service
    restart_service $service

    log_echo "Executing application specific steps ... ${G}SUCCESS${N}"
}

# C. Dispatch
deploy_dispatch() {
    local component="dispatch"
    local package="golang"
    local service=$component

    # Step 1: Source Code Management
    setup_source_code $component

    # Step 2: User Management
    add_app_user

    # Step 3: Package Management
    install_runtime $package
    install_dependencies $component

    # Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service
}

# D. Payment
deploy_payment() {
    local component="payment"
    local packages=("python3" "gcc" "python3-devel")
    local service=$component

    # Step 1: Source Code Management
    setup_source_code $component

    # Step 2: User Management
    add_app_user

    # Step 3: Package Management
    for package in "${packages[@]}"; do
        install_runtime $package
    done

    install_dependencies $component

    # Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service
}

# E. Shipping
deploy_shipping() {
    local component="shipping"
    local package="maven"
    local service=$component

    local mysql_ip="mysql.svd-learn-devops.fun"
    local mysql_user="root"
    local mysql_password="RoboShop@1"

    # Step 1: Source Code Management
    setup_source_code $component

    # Step 2: User Management
    add_app_user

    # Step 3: Package Management
    install_runtime $package
    install_dependencies $component

    # Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service

    # Step 5: Application Specific Steps
    log_echo "Executing application specific steps ..."

    ## 1. MySQL Setup
    install_runtime "mysql"

    ## 2. Load schema, Create app user and load masterdata
    log_echo "Loading Schema ..."
    log_exec mysql -h ${mysql_ip} -u${mysql_user} -p${mysql_password} < /app/db/schema.sql
    log_echo "Loading Schema ... ${G}SUCCESS${N}"

    log_echo "Creating App User ..."
    log_exec mysql -h ${mysql_ip} -u${mysql_user} -p${mysql_password} < /app/db/app-user.sql
    log_echo "Creating App User ... ${G}SUCCESS${N}"

    log_echo "Loading Masterdata ..."
    log_exec mysql -h ${mysql_ip} -u${mysql_user} -p${mysql_password} < /app/db/master-data.sql
    log_echo "Loading Masterdata ... ${G}SUCCESS${N}"

    ## 3. Restart Service
    restart_service $service

    log_echo "Executing application specific steps ... ${G}SUCCESS${N}"
}

# F. User
deploy_user() {
    local component="user"
    local package="nodejs"
    local version="20"
    local service=$component

    ## Step 1: Source Code Management
    setup_source_code $component

    ## Step 2: User Management
    add_app_user

    ## Step 3: Package Management
    enable_custom_runtime $package $version
    install_runtime $package
    install_dependencies $component

    ## Step 4: Service Management
    setup_systemd_service $service
    enable_service $service
    start_service $service
}

# Deploy Backend
deploy_backend() {
    local sub_component=$1

    case $sub_component in
        "cart")
            deploy_cart
            ;;
        "catalogue")
            deploy_catalogue
            ;;
        "dispatch")
            deploy_dispatch
            ;;
        "payment")
            deploy_payment
            ;;
        "shipping")
            deploy_shipping
            ;;
        "user")
            deploy_user
            ;;
        *)
            log_echo "Invalid backend type: ${sub_component}"
            exit 1
            ;;
    esac
}
