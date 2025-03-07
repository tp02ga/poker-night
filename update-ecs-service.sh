#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Source environment variables if available
if [ -f "aws-deploy/env-vars.sh" ]; then
  source aws-deploy/env-vars.sh
fi

# Source ECS outputs if available
if [ -f "aws-deploy/outputs/ecs-outputs.txt" ]; then
  source aws-deploy/outputs/ecs-outputs.txt
fi

# Function to get cluster name if not available from outputs
get_cluster_name() {
  echo "Cluster name not found in environment. Please enter the ECS cluster name:"
  read ECS_CLUSTER_NAME
}

# Function to get service name if not available from outputs
get_service_name() {
  echo "Service name not found in environment. Please enter the ECS service name:"
  read ECS_SERVICE_NAME
}

# Function to get the latest task definition
get_latest_task_definition() {
  echo "Getting the latest task definition for family: $ECS_TASK_FAMILY"
  
  # If task family is not defined, try to get it from the service
  if [ -z "$ECS_TASK_FAMILY" ]; then
    echo "Task family not found in environment. Attempting to get it from the service..."
    
    CURRENT_TASK_DEF=$(aws ecs describe-services \
      --cluster $ECS_CLUSTER_NAME \
      --services $ECS_SERVICE_NAME \
      --query 'services[0].taskDefinition' \
      --output text)
    
    # Extract the family name from the current task definition ARN
    ECS_TASK_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d'/' -f2 | cut -d':' -f1)
    
    if [ -z "$ECS_TASK_FAMILY" ]; then
      echo "Could not determine task family. Please enter the task definition family name:"
      read ECS_TASK_FAMILY
    else
      echo "Found task family: $ECS_TASK_FAMILY"
    fi
  fi
  
  # Get the latest active revision of the task definition
  LATEST_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $ECS_TASK_FAMILY \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)
  
  echo "Latest task definition: $LATEST_TASK_DEF"
}

# Check if we have the cluster name
if [ -z "$ECS_CLUSTER_NAME" ]; then
  get_cluster_name
fi

# Check if we have the service name
if [ -z "$ECS_SERVICE_NAME" ]; then
  get_service_name
fi

# Get the latest task definition
get_latest_task_definition

echo "Updating ECS service: $ECS_SERVICE_NAME in cluster: $ECS_CLUSTER_NAME"
echo "Using task definition: $LATEST_TASK_DEF"

# Update the ECS service with the new task definition
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --task-definition $LATEST_TASK_DEF \
  --force-new-deployment

echo "ECS service update initiated!"
echo "The service will gradually replace tasks with the new task definition."

# Monitor the deployment
echo "Monitoring deployment status (press Ctrl+C to stop monitoring)..."
aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --query 'services[0].deployments' \
  --output table

echo "You can continue to monitor the deployment with the following command:"
echo "aws ecs describe-services --cluster $ECS_CLUSTER_NAME --services $ECS_SERVICE_NAME --query 'services[0].deployments' --output table" 