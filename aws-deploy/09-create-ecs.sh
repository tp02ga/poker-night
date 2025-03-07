#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

# Load VPC outputs
source aws-deploy/outputs/vpc-outputs.txt

# Load ECR outputs
source aws-deploy/outputs/ecr-outputs.txt

# Load IAM outputs
source aws-deploy/outputs/iam-outputs.txt

# Load ALB outputs
source aws-deploy/outputs/alb-outputs.txt

# Load secrets outputs
source aws-deploy/outputs/secrets-outputs.txt

echo "Creating ECS cluster, task definition, and service..."

# Create ECS cluster
aws ecs create-cluster \
  --cluster-name $ECS_CLUSTER_NAME \
  --tags key=Name,value=$ECS_CLUSTER_NAME

echo "ECS cluster created: $ECS_CLUSTER_NAME"

# Create task definition JSON file
cat > aws-deploy/task-definition.json << EOL
{
  "family": "${ECS_TASK_FAMILY}",
  "networkMode": "awsvpc",
  "executionRoleArn": "${ECS_TASK_EXECUTION_ROLE_ARN}",
  "taskRoleArn": "${ECS_TASK_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "${APP_NAME}",
      "image": "${ECR_REPO_URI}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${APP_NAME}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "${SECRET_ARN}:DATABASE_URL::"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "${SECRET_ARN}:JWT_SECRET::"
        },
        {
          "name": "GOOGLE_CLIENT_ID",
          "valueFrom": "${SECRET_ARN}:GOOGLE_CLIENT_ID::"
        },
        {
          "name": "GOOGLE_CLIENT_SECRET",
          "valueFrom": "${SECRET_ARN}:GOOGLE_CLIENT_SECRET::"
        },
        {
          "name": "NEXT_PUBLIC_APP_URL",
          "valueFrom": "${SECRET_ARN}:NEXT_PUBLIC_APP_URL::"
        },
        {
          "name": "NODE_ENV",
          "valueFrom": "${SECRET_ARN}:NODE_ENV::"
        }
      ],
      "cpu": 256,
      "memory": 512,
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f -s -m 5 http://localhost:3000/api/health?simple=true || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512"
}
EOL

# Register task definition
TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://aws-deploy/task-definition.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "Task definition registered: $TASK_DEFINITION_ARN"
echo "TASK_DEFINITION_ARN=$TASK_DEFINITION_ARN" >> aws-deploy/outputs/ecs-outputs.txt

# Create ECS service
SERVICE_ARN=$(aws ecs create-service \
  --cluster $ECS_CLUSTER_NAME \
  --service-name $ECS_SERVICE_NAME \
  --task-definition $TASK_DEFINITION_ARN \
  --desired-count 1 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[$PUBLIC_SUBNET_1_ID,$PUBLIC_SUBNET_2_ID],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=${APP_NAME},containerPort=3000" \
  --health-check-grace-period-seconds 120 \
  --query 'service.serviceArn' \
  --output text)

echo "ECS service created: $SERVICE_ARN"
echo "SERVICE_ARN=$SERVICE_ARN" >> aws-deploy/outputs/ecs-outputs.txt

echo "ECS cluster, task definition, and service created successfully!" 