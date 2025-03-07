#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Source environment variables if available
if [ -f "aws-deploy/env-vars.sh" ]; then
  source aws-deploy/env-vars.sh
fi

# Source outputs if available
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

# Check if we have the cluster name
if [ -z "$ECS_CLUSTER_NAME" ]; then
  get_cluster_name
fi

# Check if we have the service name
if [ -z "$ECS_SERVICE_NAME" ]; then
  get_service_name
fi

# Get the current task definition
echo "Getting current task definition..."
TASK_DEF=$(aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --query 'services[0].taskDefinition' \
  --output text)

echo "Current task definition: $TASK_DEF"

# Get the task definition family
FAMILY=$(aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition.family' \
  --output text)

echo "Task definition family: $FAMILY"

# Get the container name
CONTAINER_NAME=$(aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition.containerDefinitions[0].name' \
  --output text)

echo "Container name: $CONTAINER_NAME"

# Register a new task definition with enableExecuteCommand
echo "Registering new task definition with enableExecuteCommand..."

# Download the current task definition to a file
aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --include TAGS \
  --query 'taskDefinition' \
  --output json > current-task-def.json

# Create a modified task definition file
# This is a simple sed replacement to add the initProcessEnabled property
# We're looking for the containerDefinitions section and adding the linuxParameters property
sed -i 's/"containerDefinitions": \[{/"containerDefinitions": \[{"linuxParameters": {"initProcessEnabled": true},/g' current-task-def.json

# Register the new task definition
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://current-task-def.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "New task definition registered: $NEW_TASK_DEF_ARN"

# Update the service to use the new task definition and enable execute command
echo "Updating service to use new task definition and enable execute command..."
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --task-definition $NEW_TASK_DEF_ARN \
  --enable-execute-command \
  --force-new-deployment

echo "Service updated successfully!"
echo "ECS Exec has been enabled for your service."
echo "Wait for the new tasks to be deployed, then you can use:"
echo "aws ecs execute-command --cluster $ECS_CLUSTER_NAME --task TASK_ID --container $CONTAINER_NAME --command \"/bin/bash\" --interactive"

# Clean up
rm current-task-def.json 