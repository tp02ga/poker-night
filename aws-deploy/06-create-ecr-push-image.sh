#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

echo "Creating ECR repository and pushing Docker image..."

# Create ECR repository
ECR_REPO_URI=$(aws ecr create-repository \
  --repository-name $ECR_REPO_NAME \
  --image-scanning-configuration scanOnPush=true \
  --query 'repository.repositoryUri' \
  --output text)

echo "ECR repository created: $ECR_REPO_URI"
echo "ECR_REPO_URI=$ECR_REPO_URI" >> aws-deploy/outputs/ecr-outputs.txt

# Get ECR login password and login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

echo "Logged in to ECR"

# Build Docker image
echo "Building Docker image..."
docker build -t $ECR_REPO_NAME .

# Tag Docker image
docker tag $ECR_REPO_NAME:latest $ECR_REPO_URI:latest

# Push Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push $ECR_REPO_URI:latest

echo "Docker image pushed to ECR successfully!" 