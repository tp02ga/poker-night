#!/bin/bash

# CloudFormation Deployment Script for Poker Night App
# This script deploys the AWS infrastructure using CloudFormation

# Configuration - Replace these values with your own
AWS_REGION="us-east-1"
STACK_NAME="poker-night-stack"
ENVIRONMENT="dev"

# Prompt for sensitive parameters
read -sp "Enter database password (min 8 characters): " DB_PASSWORD
echo
read -sp "Enter JWT secret (min 16 characters): " JWT_SECRET
echo
read -p "Enter Google Client ID: " GOOGLE_CLIENT_ID
read -sp "Enter Google Client Secret: " GOOGLE_CLIENT_SECRET
echo

# Validate inputs
if [ ${#DB_PASSWORD} -lt 8 ]; then
    echo "Error: Database password must be at least 8 characters"
    exit 1
fi

if [ ${#JWT_SECRET} -lt 16 ]; then
    echo "Error: JWT secret must be at least 16 characters"
    exit 1
fi

# Deploy the CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file aws-cloudformation.yml \
    --stack-name ${STACK_NAME} \
    --parameter-overrides \
        EnvironmentName=${ENVIRONMENT} \
        DBPassword=${DB_PASSWORD} \
        JWTSecret=${JWT_SECRET} \
        GoogleClientID=${GOOGLE_CLIENT_ID} \
        GoogleClientSecret=${GOOGLE_CLIENT_SECRET} \
    --capabilities CAPABILITY_IAM \
    --region ${AWS_REGION}

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "CloudFormation stack deployed successfully!"
    
    # Get stack outputs
    echo "Stack outputs:"
    aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --query "Stacks[0].Outputs" \
        --output table \
        --region ${AWS_REGION}
else
    echo "CloudFormation stack deployment failed."
    exit 1
fi 