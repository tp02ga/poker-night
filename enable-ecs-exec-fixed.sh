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

# Get the container name
CONTAINER_NAME=$(aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition.containerDefinitions[0].name' \
  --output text)

echo "Container name: $CONTAINER_NAME"

# Download the current task definition to a file
echo "Downloading current task definition..."
aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition' \
  --output json > full-task-def.json

# Extract only the allowed parameters for register-task-definition
echo "Extracting allowed parameters for new task definition..."
cat full-task-def.json | \
  grep -v '"revision":' | \
  grep -v '"status":' | \
  grep -v '"taskDefinitionArn":' | \
  grep -v '"requiresAttributes":' | \
  grep -v '"compatibilities":' | \
  grep -v '"registeredAt":' | \
  grep -v '"registeredBy":' > cleaned-task-def.json

# Now modify the cleaned task definition to add linuxParameters
echo "Adding linuxParameters to enable execute command..."
# Check if linuxParameters already exists
if grep -q "linuxParameters" cleaned-task-def.json; then
  # Update existing linuxParameters
  sed -i 's/"linuxParameters": {/"linuxParameters": {"initProcessEnabled": true,/g' cleaned-task-def.json
else
  # Add new linuxParameters to the first container definition
  sed -i 's/"containerDefinitions": \[\s*{/"containerDefinitions": \[\n    {\n      "linuxParameters": {\n        "initProcessEnabled": true\n      },/g' cleaned-task-def.json
fi

# Register the new task definition
echo "Registering new task definition..."
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://cleaned-task-def.json \
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
rm full-task-def.json cleaned-task-def.json 