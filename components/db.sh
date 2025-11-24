#!/bin/bash

# A. MongoDB
deploy_mongodb() {
    local component="mongodb"
    local repo="mongo"
    local package="mongodb-org"
    local service="mongod"

    # Step 1: Package Management
    create_repo $repo
    install_runtime $package

    # Step 2: Service Management
    enable_service $service
    start_service $service

    # Step 3: Change bind address to allow remote connections
    log_echo "Allowing remote connections to MongoDB ..."
    log_exec sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
    log_echo "Allowing remote connections to MongoDB ... ${G}SUCCESS${N}"

    # Step 4: Restart Service
    restart_service $service
}

# B. MySQL
deploy_mysql() {
    local component="mysql"
    local package="mysql-server"
    local service="mysqld"

    local mysql_password="RoboShop@1"

    # Step 1: Package Management
    install_runtime $package

    # Step 2: Service Management
    enable_service $service
    start_service $service

    # Step 3: Set root user password
    log_echo "Setting root user password ..."
    log_exec mysql_secure_installation --set-root-pass ${mysql_password}
    log_echo "Setting root user password ... ${G}SUCCESS${N}"

    # Step 4: Restart Service
    restart_service $service
}

# C. RabbitMQ
deploy_rabbitmq() {
    local component="rabbitmq"
    local repo=$component
    local package="rabbitmq-server"
    local service=$package

    local rabbitmq_user="roboshop"
    local rabbitmq_password="roboshop123"

    # Step 1: Package Management
    create_repo $repo
    install_runtime $package

    # Step 2: Service Management
    enable_service $service
    start_service $service

    # Step 3: Create Roboshop user
    log_echo "Creating roboshop user ..."
    log_exec rabbitmqctl add_user ${rabbitmq_user} ${rabbitmq_password}
    log_exec rabbitmqctl set_permissions -p / ${rabbitmq_user} ".*" ".*" ".*"
    log_echo "Creating roboshop user ... ${G}SUCCESS${N}"

    # Step 4: Restart Service
    restart_service $service
}

# D. Redis
deploy_redis() {
    local component="redis"
    local package=$component
    local version="7"
    local service=$component

    # Step 1: Package Management
    enable_custom_runtime $package $version
    install_runtime $package

    # Step 2: Change bind address in redis.conf to allow remote connections
    log_echo "Allowing remote connections to redis ..."
    log_exec sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf
    log_echo "Allowing remote connections to redis ... ${G}SUCCESS${N}"

    # Step 3: Update protected-mode from yes to no
    log_echo "Updating Protected Mode from Yes to No ..."
    log_exec sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf
    log_echo "Updating Protected Mode from Yes to No ... ${G}SUCCESS${N}"

    # Step 4: Service Management
    reload_systemd
    enable_service $service
    start_service $service
}

# Deploy DB
deploy_db() {
    local sub_component=$1

    case $sub_component in
        "mongodb")
            deploy_mongodb
            ;;
        "mysql")
            deploy_mysql
            ;;
        "rabbitmq")
            deploy_rabbitmq
            ;;
        "redis")
            deploy_redis
            ;;
        *)
            log_echo "Unsupported database type: ${sub_component}"
            exit 1
            ;;
    esac
}
