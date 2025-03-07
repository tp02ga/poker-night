#!/bin/bash

# Disable path conversion in Git Bash (for Windows)
export MSYS_NO_PATHCONV=1

# Source environment variables
source aws-deploy/env-vars.sh

echo "Updating ECS permissions and service..."

# Step 1: Delete the existing ECS service
echo "Deleting existing ECS service..."
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --desired-count 0 || echo "Failed to update service, continuing..."

aws ecs delete-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --force || echo "Failed to delete service, continuing..."

# Step 2: Delete existing IAM roles and policies
echo "Running delete-iam-role.sh..."
bash aws-deploy/delete-iam-role.sh

# Step 3: Recreate IAM roles and policies
echo "Running 07-create-iam-role.sh..."
bash aws-deploy/07-create-iam-role.sh

# Step 4: Recreate ECS service
echo "Running 09-create-ecs.sh..."
bash aws-deploy/09-create-ecs.sh

echo "Update completed! The ECS service should now have the proper permissions for CloudWatch Logs."
echo "You can check the ECS service status in the AWS Management Console." 