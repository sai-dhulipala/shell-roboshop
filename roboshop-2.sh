#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e9d12ee26b8b5dbb"

HOSTED_ZONE_ID="Z00563383PG5TZI6QAZ2E"
DOMAIN="svd-learn-devops.fun"

for instance in "$@"
do
    # Step 1: Create EC2 Instance

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "${AMI_ID}" \
        --instance-type t3.micro \
        --security-group-ids "${SG_ID}" \
        --count 1 \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance}}]" \
        --region us-east-1 \
        --query 'Instances[0].InstanceId' \
        --output text)

    # Step 2: Retrieve Public and Private IP Addresses

    PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances \
        --instance-ids "${INSTANCE_ID}" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)

    PRIVATE_IP_ADDRESS=$(aws ec2 describe-instances \
        --instance-ids "${INSTANCE_ID}" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)

    # Step 3: Determine DNS record and IP based on instance type

    if [ "${instance}" != 'frontend' ]
    then
        DNS_RECORD="${instance}.${DOMAIN}"
        IP_ADDRESS="${PRIVATE_IP_ADDRESS}"
    else
        DNS_RECORD="${DOMAIN}"
        IP_ADDRESS="${PUBLIC_IP_ADDRESS}"
    fi

    echo "Instance: ${instance}, Instance ID: ${INSTANCE_ID}, IP Address: ${IP_ADDRESS}"

    # Step 4: Update Route53 Records (note: no $() around the command)
    aws route53 change-resource-record-sets \
        --hosted-zone-id "${HOSTED_ZONE_ID}" \
        --change-batch "{
            \"Changes\": [
                {
                    \"Action\": \"UPSERT\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"${DNS_RECORD}\",
                        \"Type\": \"A\",
                        \"TTL\": 300,
                        \"ResourceRecords\": [
                            {
                                \"Value\": \"${IP_ADDRESS}\"
                            }
                        ]
                    }
                }
            ]
        }"

    if [ $? -ne 0 ]
    then
        echo "DNS Record update failed for ${DNS_RECORD}"
        exit 1
    else
        echo "DNS Record updated: ${DNS_RECORD} -> ${IP_ADDRESS}"
    fi

done
