#!/bin/bash

# Disable path conversion in Git Bash (for Windows)
export MSYS_NO_PATHCONV=1

# Source environment variables
source aws-deploy/env-vars.sh

echo "Deleting existing IAM roles and policies..."

# Get the ARNs of the policies
SECRETS_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='${APP_NAME}-secrets-policy'].Arn" --output text)
LOGS_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='${APP_NAME}-logs-policy'].Arn" --output text)

# Detach policies from the execution role
if [ ! -z "$SECRETS_POLICY_ARN" ]; then
  echo "Detaching secrets policy from execution role..."
  aws iam detach-role-policy \
    --role-name ${APP_NAME}-ecs-task-execution-role \
    --policy-arn $SECRETS_POLICY_ARN || echo "Failed to detach secrets policy, continuing..."
fi

if [ ! -z "$LOGS_POLICY_ARN" ]; then
  echo "Detaching logs policy from execution role..."
  aws iam detach-role-policy \
    --role-name ${APP_NAME}-ecs-task-execution-role \
    --policy-arn $LOGS_POLICY_ARN || echo "Failed to detach logs policy, continuing..."
fi

echo "Detaching ECS task execution policy from execution role..."
aws iam detach-role-policy \
  --role-name ${APP_NAME}-ecs-task-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || echo "Failed to detach ECS task execution policy, continuing..."

# Delete the policies
if [ ! -z "$SECRETS_POLICY_ARN" ]; then
  echo "Deleting secrets policy..."
  aws iam delete-policy \
    --policy-arn $SECRETS_POLICY_ARN || echo "Failed to delete secrets policy, continuing..."
fi

if [ ! -z "$LOGS_POLICY_ARN" ]; then
  echo "Deleting logs policy..."
  aws iam delete-policy \
    --policy-arn $LOGS_POLICY_ARN || echo "Failed to delete logs policy, continuing..."
fi

# Delete the roles
echo "Deleting execution role..."
aws iam delete-role \
  --role-name ${APP_NAME}-ecs-task-execution-role || echo "Failed to delete execution role, continuing..."

echo "Deleting task role..."
aws iam delete-role \
  --role-name ${APP_NAME}-ecs-task-role || echo "Failed to delete task role, continuing..."

echo "IAM roles and policies deleted!" 