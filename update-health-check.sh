#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Source environment variables if available
if [ -f "aws-deploy/env-vars.sh" ]; then
  source aws-deploy/env-vars.sh
fi

# Source ALB outputs if available
if [ -f "aws-deploy/outputs/alb-outputs.txt" ]; then
  source aws-deploy/outputs/alb-outputs.txt
fi

# Function to get target group ARN if not available from outputs
get_target_group_arn() {
  echo "Target group ARN not found in outputs. Attempting to retrieve it..."
  
  # Check if TG_NAME is defined
  if [ -z "$TG_NAME" ]; then
    echo "Enter the target group name:"
    read TG_NAME
  fi
  
  # Get the target group ARN
  TG_ARN=$(aws elbv2 describe-target-groups \
    --names $TG_NAME \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
    
  if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "Could not find target group with name: $TG_NAME"
    echo "Enter the target group ARN manually:"
    read TG_ARN
  fi
}

# Check if we have the target group ARN
if [ -z "$TG_ARN" ]; then
  get_target_group_arn
fi

echo "Updating health check for target group: $TG_ARN"

# Update the target group health check
aws elbv2 modify-target-group \
  --target-group-arn $TG_ARN \
  --health-check-path /api/health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2

echo "Health check updated successfully!"

# Verify the changes
echo "Verifying the updated health check configuration:"
aws elbv2 describe-target-group-attributes \
  --target-group-arn $TG_ARN

echo "Health check path updated to /api/health" 