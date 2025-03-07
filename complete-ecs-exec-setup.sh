#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Set variables - replace these with your actual values
CLUSTER_NAME="poker-night-app-cluster"
SERVICE_NAME="poker-night-app-service"
TASK_ROLE_NAME="ecsTaskRole"
TASK_DEF_FAMILY="poker-night-app"

echo "=== COMPLETE ECS EXEC SETUP ==="
echo "This script will set up everything needed for ECS Exec to work properly."

# Step 1: Update the task role with SSM permissions
echo "Step 1: Updating task role with SSM permissions..."

# Check if the policy file exists
if [ ! -f "ecs-exec-iam-policy.json" ]; then
  echo "Error: ecs-exec-iam-policy.json not found!"
  exit 1
fi

# Create a policy for ECS Exec
POLICY_ARN=$(aws iam create-policy \
  --policy-name ECSExecPolicy \
  --policy-document file://ecs-exec-iam-policy.json \
  --query 'Policy.Arn' \
  --output text)

echo "Created policy: $POLICY_ARN"

# Attach the policy to the task role
aws iam attach-role-policy \
  --role-name $TASK_ROLE_NAME \
  --policy-arn $POLICY_ARN

echo "Attached policy to role: $TASK_ROLE_NAME"

# Step 2: Register a new task definition with all required settings
echo "Step 2: Registering new task definition..."

# Check if the task definition file exists
if [ ! -f "complete-ecs-exec-task-def.json" ]; then
  echo "Error: complete-ecs-exec-task-def.json not found!"
  exit 1
fi

# Register the new task definition
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://complete-ecs-exec-task-def.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "Registered new task definition: $NEW_TASK_DEF_ARN"

# Step 3: Update the service with the new task definition and enable execute command
echo "Step 3: Updating service with new task definition and enabling execute command..."

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $NEW_TASK_DEF_ARN \
  --enable-execute-command \
  --force-new-deployment

echo "Service updated successfully!"

# Step 4: Wait for the deployment to complete
echo "Step 4: Waiting for deployment to complete..."
echo "This may take a few minutes..."

# Function to check deployment status
check_deployment() {
  DEPLOYMENT_STATUS=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
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
    echo "Deployment completed successfully!"
    break
  fi
  
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
    echo "Timeout waiting for deployment to complete."
    echo "Please check the ECS console for deployment status."
    break
  fi
  
  echo "Deployment in progress... (${ELAPSED_TIME}s elapsed)"
  sleep 30
done

# Step 5: Get the new task ID
echo "Step 5: Getting new task ID..."

NEW_TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --query 'taskArns[0]' \
  --output text)

NEW_TASK_ID=$(echo $NEW_TASK_ARN | awk -F'/' '{print $3}')

echo "New task ID: $NEW_TASK_ID"

# Step 6: Provide the command to connect
echo "=== SETUP COMPLETE ==="
echo "To connect to your container, run:"
echo "aws ecs execute-command \\"
echo "  --cluster $CLUSTER_NAME \\"
echo "  --task $NEW_TASK_ID \\"
echo "  --container poker-night-app \\"
echo "  --command \"/bin/bash\" \\"
echo "  --interactive" 