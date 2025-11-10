#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e9d12ee26b8b5dbb"

for instance in "$@"
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --count 1 \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --region us-east-1 \
        --query 'Instances[0].InstanceId' \
        --output text)

    if [ "$instance" != 'frontend' ]
    then
        IP_ADDRESS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
    else
        IP_ADDRESS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    fi

    echo "Instance: $instance, Instance ID: $INSTANCE_ID, IP Address: $IP_ADDRESS"
done