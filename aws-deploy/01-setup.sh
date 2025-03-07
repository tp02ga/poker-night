#!/bin/bash

# Set AWS region
export AWS_REGION=us-east-1
aws configure set default.region $AWS_REGION

echo "AWS CLI configured for region: $AWS_REGION"

# Create a directory for storing temporary files and outputs
mkdir -p aws-deploy/outputs

# Store environment variables in a file for reference
cat > aws-deploy/env-vars.sh << EOL
#!/bin/bash

# AWS Region
export AWS_REGION=us-east-1

# Application name
export APP_NAME=poker-night-app

# Domain name
export DOMAIN_NAME=purely-functional.net

# Route 53 Zone ID - will be set by 04-create-certificate.sh
export ROUTE53_ZONE_ID=

# Database configuration
export DB_NAME=poker_game_planner
export DB_USERNAME=admin
export DB_PASSWORD=my-secret-password
export DB_PORT=3306

# ECR Repository name
export ECR_REPO_NAME=\${APP_NAME}

# ECS configuration
export ECS_CLUSTER_NAME=\${APP_NAME}-cluster
export ECS_SERVICE_NAME=\${APP_NAME}-service
export ECS_TASK_FAMILY=\${APP_NAME}-task

# Load balancer configuration
export LB_NAME=\${APP_NAME}-lb
export TG_NAME=\${APP_NAME}-tg

# VPC configuration
export VPC_CIDR=10.0.0.0/16
export PUBLIC_SUBNET_1_CIDR=10.0.1.0/24
export PUBLIC_SUBNET_2_CIDR=10.0.2.0/24
export PRIVATE_SUBNET_1_CIDR=10.0.3.0/24
export PRIVATE_SUBNET_2_CIDR=10.0.4.0/24
EOL

chmod +x aws-deploy/env-vars.sh

echo "Environment variables file created at aws-deploy/env-vars.sh"
echo "Setup complete!" 