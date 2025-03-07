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

if [ -f "aws-deploy/outputs/vpc-outputs.txt" ]; then
  source aws-deploy/outputs/vpc-outputs.txt
fi

# Function to get cluster name if not available from outputs
get_cluster_name() {
  echo "Cluster name not found in environment. Please enter the ECS cluster name:"
  read ECS_CLUSTER_NAME
}

# Function to get subnet ID if not available from outputs
get_subnet_id() {
  echo "Subnet ID not found in environment. Please enter a public subnet ID:"
  read PUBLIC_SUBNET_1_ID
}

# Function to get security group ID if not available from outputs
get_security_group_id() {
  echo "Security group ID not found in environment. Please enter a security group ID:"
  read ECS_SG_ID
}

# Check if we have the cluster name
if [ -z "$ECS_CLUSTER_NAME" ]; then
  get_cluster_name
fi

# Check if we have the subnet ID
if [ -z "$PUBLIC_SUBNET_1_ID" ]; then
  get_subnet_id
fi

# Check if we have the security group ID
if [ -z "$ECS_SG_ID" ]; then
  get_security_group_id
fi

# Get the service's task definition
echo "Getting task definition from service..."
SERVICE_NAME=${ECS_SERVICE_NAME:-"poker-night-app-service"}
TASK_DEF=$(aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $SERVICE_NAME \
  --query 'services[0].taskDefinition' \
  --output text)

echo "Service is using task definition: $TASK_DEF"

# Create a diagnostic task definition based on the service's task definition
echo "Creating diagnostic task definition..."
DIAGNOSTIC_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --query 'taskDefinition' \
  --output json)

# Extract the container name from the task definition
CONTAINER_NAME=$(echo $DIAGNOSTIC_TASK_DEF | jq -r '.containerDefinitions[0].name')
echo "Container name: $CONTAINER_NAME"

# Create a temporary JSON file for the diagnostic task
echo "Creating temporary task definition file..."
echo $DIAGNOSTIC_TASK_DEF | jq '.family = "diagnostic-task"' > diagnostic-task-def.json

# Register the diagnostic task definition
echo "Registering diagnostic task definition..."
DIAGNOSTIC_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://diagnostic-task-def.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "Diagnostic task definition registered: $DIAGNOSTIC_TASK_DEF_ARN"

# Run the diagnostic task
echo "Running diagnostic task..."
TASK_ARN=$(aws ecs run-task \
  --cluster $ECS_CLUSTER_NAME \
  --task-definition $DIAGNOSTIC_TASK_DEF_ARN \
  --network-configuration "awsvpcConfiguration={subnets=[$PUBLIC_SUBNET_1_ID],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" \
  --launch-type FARGATE \
  --overrides "{
    \"containerOverrides\": [
      {
        \"name\": \"$CONTAINER_NAME\",
        \"command\": [
          \"/bin/sh\", 
          \"-c\", 
          \"echo 'Testing health check endpoint...' && curl -v http://localhost:3000/api/health && echo 'Testing database connection...' && node -e \\\"const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient(); async function testDb() { try { console.log('Connecting to database...'); const result = await prisma.\$queryRaw\\\\\`SELECT 1\\\\\`; console.log('Database connection successful:', result); } catch (error) { console.error('Database connection failed:', error); } finally { await prisma.\$disconnect(); } } testDb();\\\" && sleep 60\"
        ]
      }
    ]
  }" \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Diagnostic task started: $TASK_ARN"
echo "Task ID: $(echo $TASK_ARN | cut -d'/' -f3)"

# Wait for the task to start
echo "Waiting for task to start..."
aws ecs wait tasks-running \
  --cluster $ECS_CLUSTER_NAME \
  --tasks $TASK_ARN

echo "Task is now running. Logs will be available in CloudWatch."
echo "Check the logs at: /ecs/$CONTAINER_NAME"

# Clean up the temporary file
rm diagnostic-task-def.json

echo "To view the logs, run:"
echo "aws logs get-log-events --log-group-name /ecs/$CONTAINER_NAME --log-stream-name \$(aws logs describe-log-streams --log-group-name /ecs/$CONTAINER_NAME --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text) --limit 100" 