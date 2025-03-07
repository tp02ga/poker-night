#!/bin/bash

# Disable path conversion in Git Bash (for Windows)
export MSYS_NO_PATHCONV=1

# Source environment variables
source aws-deploy/env-vars.sh

# Load secrets outputs
source aws-deploy/outputs/secrets-outputs.txt

echo "Creating IAM role for ECS task execution..."

# Create a trust policy document for ECS tasks
cat > aws-deploy/ecs-task-trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

# Create the ECS task execution role
ECS_TASK_EXECUTION_ROLE_NAME="${APP_NAME}-ecs-task-execution-role"

ECS_TASK_EXECUTION_ROLE_ARN=$(aws iam create-role \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --assume-role-policy-document file://aws-deploy/ecs-task-trust-policy.json \
  --query 'Role.Arn' \
  --output text)

echo "ECS task execution role created: $ECS_TASK_EXECUTION_ROLE_ARN"
echo "ECS_TASK_EXECUTION_ROLE_ARN=$ECS_TASK_EXECUTION_ROLE_ARN" >> aws-deploy/outputs/iam-outputs.txt

# Attach the AmazonECSTaskExecutionRolePolicy to the role
aws iam attach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

echo "AmazonECSTaskExecutionRolePolicy attached to role"

# Create a policy document for accessing Secrets Manager
cat > aws-deploy/secrets-manager-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${SECRET_ARN}"
      ]
    }
  ]
}
EOL

# Create the Secrets Manager access policy
SECRETS_POLICY_NAME="${APP_NAME}-secrets-policy"

SECRETS_POLICY_ARN=$(aws iam create-policy \
  --policy-name $SECRETS_POLICY_NAME \
  --policy-document file://aws-deploy/secrets-manager-policy.json \
  --query 'Policy.Arn' \
  --output text)

echo "Secrets Manager access policy created: $SECRETS_POLICY_ARN"
echo "SECRETS_POLICY_ARN=$SECRETS_POLICY_ARN" >> aws-deploy/outputs/iam-outputs.txt

# Attach the Secrets Manager access policy to the role
aws iam attach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn $SECRETS_POLICY_ARN

echo "Secrets Manager access policy attached to role"

# Create a policy document for CloudWatch Logs
cat > aws-deploy/cloudwatch-logs-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:${AWS_REGION}:*:log-group:/ecs/${APP_NAME}*",
        "arn:aws:logs:${AWS_REGION}:*:log-group:/ecs/${APP_NAME}*:log-stream:*"
      ]
    }
  ]
}
EOL

# Create the CloudWatch Logs access policy
LOGS_POLICY_NAME="${APP_NAME}-logs-policy"

LOGS_POLICY_ARN=$(aws iam create-policy \
  --policy-name $LOGS_POLICY_NAME \
  --policy-document file://aws-deploy/cloudwatch-logs-policy.json \
  --query 'Policy.Arn' \
  --output text)

echo "CloudWatch Logs access policy created: $LOGS_POLICY_ARN"
echo "LOGS_POLICY_ARN=$LOGS_POLICY_ARN" >> aws-deploy/outputs/iam-outputs.txt

# Attach the CloudWatch Logs access policy to the role
aws iam attach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn $LOGS_POLICY_ARN

echo "CloudWatch Logs access policy attached to role"

# Create a task role for the application
ECS_TASK_ROLE_NAME="${APP_NAME}-ecs-task-role"

ECS_TASK_ROLE_ARN=$(aws iam create-role \
  --role-name $ECS_TASK_ROLE_NAME \
  --assume-role-policy-document file://aws-deploy/ecs-task-trust-policy.json \
  --query 'Role.Arn' \
  --output text)

echo "ECS task role created: $ECS_TASK_ROLE_ARN"
echo "ECS_TASK_ROLE_ARN=$ECS_TASK_ROLE_ARN" >> aws-deploy/outputs/iam-outputs.txt

echo "IAM roles and policies created successfully!" 