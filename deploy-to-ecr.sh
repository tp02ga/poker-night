#!/bin/bash

# Script to automate ECR login, Docker build, tag, and push
# Author: Claude
# Date: 2023-03-07

# Set default values
DEFAULT_AWS_REGION="us-east-1"
DEFAULT_APP_NAME="poker-night-app"
DEFAULT_TAG="latest"

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BOLD}${BLUE}=========================================${NC}"
echo -e "${BOLD}${BLUE}   Docker Build and Push to ECR Script   ${NC}"
echo -e "${BOLD}${BLUE}=========================================${NC}"
echo ""

# Source environment variables if available
if [ -f "aws-deploy/env-vars.sh" ]; then
  echo -e "${YELLOW}Loading environment variables from aws-deploy/env-vars.sh...${NC}"
  source aws-deploy/env-vars.sh
  echo -e "${GREEN}Environment variables loaded successfully!${NC}"
  echo ""
fi

# Source ECR outputs if available
if [ -f "aws-deploy/outputs/ecr-outputs.txt" ]; then
  echo -e "${YELLOW}Loading ECR outputs from aws-deploy/outputs/ecr-outputs.txt...${NC}"
  source aws-deploy/outputs/ecr-outputs.txt
  echo -e "${GREEN}ECR outputs loaded successfully!${NC}"
  echo ""
fi

# Function to prompt for a value with a default
prompt_with_default() {
  local prompt_message=$1
  local default_value=$2
  local var_name=$3
  
  echo -e "${YELLOW}${prompt_message} (default: ${default_value})${NC}"
  read -p "> " user_input
  
  if [ -z "$user_input" ]; then
    eval "$var_name=\"$default_value\""
    echo -e "Using default: ${GREEN}${default_value}${NC}"
  else
    eval "$var_name=\"$user_input\""
    echo -e "Using: ${GREEN}${user_input}${NC}"
  fi
  echo ""
}

# Prompt for AWS region if not set
if [ -z "$AWS_REGION" ]; then
  prompt_with_default "Enter AWS region" "$DEFAULT_AWS_REGION" "AWS_REGION"
fi

# Prompt for app name if not set
if [ -z "$APP_NAME" ]; then
  prompt_with_default "Enter application name" "$DEFAULT_APP_NAME" "APP_NAME"
fi

# Prompt for image tag
prompt_with_default "Enter image tag" "$DEFAULT_TAG" "IMAGE_TAG"

# Get AWS account ID if not already set
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo -e "${YELLOW}Getting AWS account ID...${NC}"
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
  echo -e "AWS Account ID: ${GREEN}${AWS_ACCOUNT_ID}${NC}"
  echo ""
fi

# Set ECR repository URI if not already set
if [ -z "$ECR_REPO_URI" ]; then
  ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"
  echo -e "ECR Repository URI: ${GREEN}${ECR_REPO_URI}${NC}"
  echo ""
fi

# Step 1: ECR Login
echo -e "${BOLD}Step 1: Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
  echo -e "\n${BOLD}Error: Failed to login to ECR.${NC}"
  exit 1
fi

echo -e "${GREEN}Successfully logged in to ECR!${NC}"
echo ""

# Step 2: Build Docker image
echo -e "${BOLD}Step 2: Building Docker image...${NC}"
echo -e "Running: ${YELLOW}docker build -t ${ECR_REPO_URI}:${IMAGE_TAG} .${NC}"

docker build -t ${ECR_REPO_URI}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
  echo -e "\n${BOLD}Error: Docker build failed.${NC}"
  exit 1
fi

echo -e "${GREEN}Docker image built successfully!${NC}"
echo ""

# # Step 3: Tag Docker image
# echo -e "${BOLD}Step 3: Tagging Docker image...${NC}"
# echo -e "Running: ${YELLOW}docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}${NC}"

# docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}

# if [ $? -ne 0 ]; then
#   echo -e "\n${BOLD}Error: Docker tag failed.${NC}"
#   exit 1
# fi

# echo -e "${GREEN}Docker image tagged successfully!${NC}"
# echo ""

# Step 4: Push Docker image to ECR
echo -e "${BOLD}Step 4: Pushing Docker image to ECR...${NC}"
echo -e "Running: ${YELLOW}docker push ${ECR_REPO_URI}:${IMAGE_TAG}${NC}"

docker push ${ECR_REPO_URI}:${IMAGE_TAG}

if [ $? -ne 0 ]; then
  echo -e "\n${BOLD}Error: Docker push failed.${NC}"
  exit 1
fi

echo -e "${GREEN}Docker image pushed to ECR successfully!${NC}"
echo ""

# Step 5: Verify the pushed image
echo -e "${BOLD}Step 5: Verifying pushed image...${NC}"
aws ecr describe-images --repository-name ${APP_NAME} --image-ids imageTag=${IMAGE_TAG} --region ${AWS_REGION} --output json

echo ""
echo -e "${BOLD}${GREEN}=========================================${NC}"
echo -e "${BOLD}${GREEN}   Deployment to ECR Completed!   ${NC}"
echo -e "${BOLD}${GREEN}=========================================${NC}"
echo ""
echo -e "Image URI: ${BOLD}${ECR_REPO_URI}:${IMAGE_TAG}${NC}"
echo ""
echo -e "To update your ECS service with this image, run:"
echo -e "${YELLOW}aws ecs update-service --cluster ${APP_NAME}-cluster --service ${APP_NAME}-service --force-new-deployment${NC}"
echo "" 