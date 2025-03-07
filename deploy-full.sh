#!/bin/bash

# Full Deployment Script: Build, Push to ECR, and Update ECS Service
# Author: Claude
# Date: 2023-03-07

# Set default values
DEFAULT_AWS_REGION="us-east-1"
DEFAULT_APP_NAME="poker-night-app"
DEFAULT_TAG="latest"
DEFAULT_CLUSTER_NAME="poker-night-app-cluster"
DEFAULT_SERVICE_NAME="poker-night-app-service"

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${BOLD}${BLUE}=========================================${NC}"
echo -e "${BOLD}${BLUE}   Full Deployment Script   ${NC}"
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

# Source ECS outputs if available
if [ -f "aws-deploy/outputs/ecs-outputs.txt" ]; then
  echo -e "${YELLOW}Loading ECS outputs from aws-deploy/outputs/ecs-outputs.txt...${NC}"
  source aws-deploy/outputs/ecs-outputs.txt
  echo -e "${GREEN}ECS outputs loaded successfully!${NC}"
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

# Function to check if a command succeeded
check_success() {
  if [ $? -ne 0 ]; then
    echo -e "\n${BOLD}${RED}Error: $1 failed.${NC}"
    exit 1
  fi
  echo -e "${GREEN}$2${NC}"
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
  check_success "Getting AWS account ID" "AWS Account ID: ${AWS_ACCOUNT_ID}"
fi

# Set ECR repository URI if not already set
if [ -z "$ECR_REPO_URI" ]; then
  ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"
  echo -e "ECR Repository URI: ${GREEN}${ECR_REPO_URI}${NC}"
  echo ""
fi

# Prompt for cluster name if not set
if [ -z "$ECS_CLUSTER_NAME" ]; then
  prompt_with_default "Enter ECS cluster name" "$DEFAULT_CLUSTER_NAME" "ECS_CLUSTER_NAME"
fi

# Prompt for service name if not set
if [ -z "$ECS_SERVICE_NAME" ]; then
  prompt_with_default "Enter ECS service name" "$DEFAULT_SERVICE_NAME" "ECS_SERVICE_NAME"
fi

# PART 1: BUILD AND PUSH TO ECR
echo -e "${BOLD}${BLUE}PART 1: BUILD AND PUSH TO ECR${NC}"
echo -e "${BOLD}${BLUE}---------------------------${NC}"
echo ""

# Step 1: ECR Login
echo -e "${BOLD}Step 1: Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
check_success "ECR login" "Successfully logged in to ECR!"

# Step 2: Build Docker image
echo -e "${BOLD}Step 2: Building Docker image...${NC}"
echo -e "Running: ${YELLOW}docker build -t ${APP_NAME}:${IMAGE_TAG} .${NC}"
docker build -t ${APP_NAME}:${IMAGE_TAG} .
check_success "Docker build" "Docker image built successfully!"

# Step 3: Tag Docker image
echo -e "${BOLD}Step 3: Tagging Docker image...${NC}"
echo -e "Running: ${YELLOW}docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}${NC}"
docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}
check_success "Docker tag" "Docker image tagged successfully!"

# Step 4: Push Docker image to ECR
echo -e "${BOLD}Step 4: Pushing Docker image to ECR...${NC}"
echo -e "Running: ${YELLOW}docker push ${ECR_REPO_URI}:${IMAGE_TAG}${NC}"
docker push ${ECR_REPO_URI}:${IMAGE_TAG}
check_success "Docker push" "Docker image pushed to ECR successfully!"

# Step 5: Verify the pushed image
echo -e "${BOLD}Step 5: Verifying pushed image...${NC}"
aws ecr describe-images --repository-name ${APP_NAME} --image-ids imageTag=${IMAGE_TAG} --region ${AWS_REGION} --output json
check_success "Image verification" "Image verification completed!"

# PART 2: UPDATE ECS SERVICE
echo -e "${BOLD}${BLUE}PART 2: UPDATE ECS SERVICE${NC}"
echo -e "${BOLD}${BLUE}---------------------------${NC}"
echo ""

# Step 6: Update ECS service
echo -e "${BOLD}Step 6: Updating ECS service...${NC}"
echo -e "Running: ${YELLOW}aws ecs update-service --cluster ${ECS_CLUSTER_NAME} --service ${ECS_SERVICE_NAME} --force-new-deployment${NC}"
aws ecs update-service --cluster ${ECS_CLUSTER_NAME} --service ${ECS_SERVICE_NAME} --force-new-deployment
check_success "ECS service update" "ECS service update initiated!"

# Step 7: Monitor deployment
echo -e "${BOLD}Step 7: Monitoring deployment...${NC}"
echo -e "This may take a few minutes..."
echo ""

# Function to check deployment status
check_deployment() {
  DEPLOYMENT_STATUS=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER_NAME \
    --services $ECS_SERVICE_NAME \
    --query 'services[0].deployments' \
    --output json)
  
  # Count the number of deployments
  DEPLOYMENT_COUNT=$(echo $DEPLOYMENT_STATUS | grep -o '"status":' | wc -l)
  
  # If there's only one deployment and it's PRIMARY, we're done
  if [ $DEPLOYMENT_COUNT -eq 1 ] && echo $DEPLOYMENT_STATUS | grep -q '"status": "PRIMARY"'; then
    return 0
  else
    return 1
  fi
}

# Wait for deployment to complete with timeout
TIMEOUT=600  # 10 minutes
START_TIME=$(date +%s)
while true; do
  if check_deployment; then
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    break
  fi
  
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
    echo -e "${YELLOW}Timeout waiting for deployment to complete.${NC}"
    echo -e "${YELLOW}Please check the ECS console for deployment status.${NC}"
    break
  fi
  
  echo -e "Deployment in progress... (${ELAPSED_TIME}s elapsed)"
  sleep 30
done

# Final summary
echo ""
echo -e "${BOLD}${GREEN}=========================================${NC}"
echo -e "${BOLD}${GREEN}   Full Deployment Completed!   ${NC}"
echo -e "${BOLD}${GREEN}=========================================${NC}"
echo ""
echo -e "Image URI: ${BOLD}${ECR_REPO_URI}:${IMAGE_TAG}${NC}"
echo -e "ECS Cluster: ${BOLD}${ECS_CLUSTER_NAME}${NC}"
echo -e "ECS Service: ${BOLD}${ECS_SERVICE_NAME}${NC}"
echo ""
echo -e "To check the service status, run:"
echo -e "${YELLOW}aws ecs describe-services --cluster ${ECS_CLUSTER_NAME} --services ${ECS_SERVICE_NAME} --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount,Events:events[0:3]}' --output json${NC}"
echo "" 