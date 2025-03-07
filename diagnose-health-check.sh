#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Source environment variables if available
if [ -f "aws-deploy/env-vars.sh" ]; then
  source aws-deploy/env-vars.sh
fi

# Source outputs if available
if [ -f "aws-deploy/outputs/alb-outputs.txt" ]; then
  source aws-deploy/outputs/alb-outputs.txt
fi

if [ -f "aws-deploy/outputs/ecs-outputs.txt" ]; then
  source aws-deploy/outputs/ecs-outputs.txt
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

# Check if we have the target group ARN
if [ -z "$TG_ARN" ]; then
  get_target_group_arn
fi

# Check if we have the cluster name
if [ -z "$ECS_CLUSTER_NAME" ]; then
  get_cluster_name
fi

# Check if we have the service name
if [ -z "$ECS_SERVICE_NAME" ]; then
  get_service_name
fi

echo "=== HEALTH CHECK DIAGNOSTICS ==="
echo "Running comprehensive diagnostics to identify health check issues..."
echo

echo "=== TARGET GROUP HEALTH CHECK CONFIGURATION ==="
aws elbv2 describe-target-groups \
  --target-group-arns $TG_ARN \
  --query 'TargetGroups[0].HealthCheckSettings' \
  --output json

echo
echo "=== TARGET GROUP HEALTH STATUS ==="
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --output json

echo
echo "=== ECS SERVICE STATUS ==="
aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Events:events[0:3]}' \
  --output json

echo
echo "=== LATEST ECS TASK STATUS ==="
TASK_ARNS=$(aws ecs list-tasks \
  --cluster $ECS_CLUSTER_NAME \
  --service-name $ECS_SERVICE_NAME \
  --query 'taskArns' \
  --output text)

if [ -n "$TASK_ARNS" ]; then
  aws ecs describe-tasks \
    --cluster $ECS_CLUSTER_NAME \
    --tasks $TASK_ARNS \
    --query 'tasks[*].{TaskArn:taskArn,LastStatus:lastStatus,HealthStatus:healthStatus,Containers:containers[*].{Name:name,Status:lastStatus,Reason:reason,ExitCode:exitCode}}' \
    --output json
else
  echo "No running tasks found for service $ECS_SERVICE_NAME"
fi

echo
echo "=== CLOUDWATCH LOGS LOCATION ==="
echo "Check the following CloudWatch Log Group for application logs:"
echo "/ecs/$APP_NAME"
echo
echo "Command to view recent logs:"
echo "aws logs get-log-events --log-group-name /ecs/$APP_NAME --log-stream-name \$(aws logs describe-log-streams --log-group-name /ecs/$APP_NAME --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text) --limit 100"

echo
echo "=== NEXT STEPS ==="
echo "1. Check if the health check path is correct (/api/health)"
echo "2. Verify database connectivity from the application"
echo "3. Check if the application is listening on port 3000"
echo "4. Review security groups to ensure traffic is allowed"
echo "5. Check for any errors in the application logs"
echo
echo "For more detailed diagnostics, run:"
echo "aws ecs execute-command --cluster $ECS_CLUSTER_NAME --task \$(aws ecs list-tasks --cluster $ECS_CLUSTER_NAME --service-name $ECS_SERVICE_NAME --query 'taskArns[0]' --output text) --container $APP_NAME --command '/bin/sh' --interactive"
echo "Note: This requires ECS Exec to be enabled on your cluster" 