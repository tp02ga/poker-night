#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

# Load VPC outputs
source aws-deploy/outputs/vpc-outputs.txt

echo "Creating RDS MySQL database..."

# Create DB subnet group
DB_SUBNET_GROUP_NAME="${APP_NAME}-db-subnet-group"

aws rds create-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
  --db-subnet-group-description "Subnet group for ${APP_NAME} RDS" \
  --subnet-ids $PUBLIC_SUBNET_1_ID $PUBLIC_SUBNET_2_ID \
  --tags "Key=Name,Value=${APP_NAME}-db-subnet-group"

echo "DB Subnet Group created: $DB_SUBNET_GROUP_NAME"

# Create RDS instance
RDS_INSTANCE_ID="${APP_NAME}-db"

aws rds create-db-instance \
  --db-instance-identifier $RDS_INSTANCE_ID \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --allocated-storage 20 \
  --master-username $DB_USERNAME \
  --master-user-password $DB_PASSWORD \
  --db-name $DB_NAME \
  --vpc-security-group-ids $RDS_SG_ID \
  --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
  --publicly-accessible \
  --port $DB_PORT \
  --backup-retention-period 1 \
  --no-multi-az \
  --storage-type gp2 \
  --no-auto-minor-version-upgrade \
  --tags "Key=Name,Value=${APP_NAME}-db"

echo "RDS instance creation initiated: $RDS_INSTANCE_ID"
echo "Waiting for RDS instance to be available (this may take several minutes)..."

# Wait for the RDS instance to be available
aws rds wait db-instance-available \
  --db-instance-identifier $RDS_INSTANCE_ID

# Get the RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $RDS_INSTANCE_ID \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS instance created successfully!"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "RDS_INSTANCE_ID=$RDS_INSTANCE_ID" >> aws-deploy/outputs/rds-outputs.txt
echo "RDS_ENDPOINT=$RDS_ENDPOINT" >> aws-deploy/outputs/rds-outputs.txt
echo "DATABASE_URL=mysql://${DB_USERNAME}:${DB_PASSWORD}@${RDS_ENDPOINT}:${DB_PORT}/${DB_NAME}" >> aws-deploy/outputs/rds-outputs.txt 