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

# Get the task definition details
echo "Getting task definition details..."
TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition' \
  --output json)

# Create a temporary file for the task definition
echo "Creating temporary task definition file..."
echo $TASK_DEF_JSON > temp-task-def.json

# Extract the family name
FAMILY=$(echo $TASK_DEF_JSON | jq -r '.family')
echo "Task definition family: $FAMILY"

# Register a new task definition with enableExecuteCommand
echo "Registering new task definition with enableExecuteCommand..."
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$(echo $TASK_DEF_JSON | jq '.containerDefinitions[0].linuxParameters.initProcessEnabled = true')" \
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
echo "aws ecs execute-command --cluster $ECS_CLUSTER_NAME --task TASK_ID --container CONTAINER_NAME --command \"/bin/bash\" --interactive"

# Clean up
rm temp-task-def.json 