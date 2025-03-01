#!/bin/bash

# AWS Deployment Script for Poker Night App
# This script helps deploy the application to AWS ECS

# Configuration - Replace these values with your own
AWS_REGION="us-east-1"
ECR_REPOSITORY_NAME="poker-night-app"
ECS_CLUSTER_NAME="poker-night-cluster"
ECS_SERVICE_NAME="poker-night-service"
ECS_TASK_FAMILY="poker-night-task"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}"

# Build the Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPOSITORY_NAME}:latest .

# Log in to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URI}

# Tag and push the image to ECR
echo "Tagging and pushing image to ECR..."
docker tag ${ECR_REPOSITORY_NAME}:latest ${ECR_REPOSITORY_URI}:latest
docker push ${ECR_REPOSITORY_URI}:latest

# Update the ECS service to use the new image
echo "Updating ECS service..."
aws ecs update-service --cluster ${ECS_CLUSTER_NAME} --service ${ECS_SERVICE_NAME} --force-new-deployment --region ${AWS_REGION}

echo "Deployment completed successfully!"
echo "Your application should be updating on ECS. Check the AWS Console for status." 