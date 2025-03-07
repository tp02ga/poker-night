#!/bin/bash

# Create the aws-deploy/outputs directory if it doesn't exist
mkdir -p aws-deploy/outputs

echo "Starting deployment of poker-night-app to AWS ECS..."

# Step 0: Configure AWS CLI with credentials
echo "Step 0: Configuring AWS CLI with credentials..."
bash aws-deploy/00-configure-aws-cli.sh
echo "Step 0 completed!"

# Step 1: Set up AWS CLI configuration
echo "Step 1: Setting up AWS CLI configuration..."
bash aws-deploy/01-setup.sh
echo "Step 1 completed!"

# Step 2: Create VPC, Subnets, and Internet Gateway
echo "Step 2: Creating VPC infrastructure..."
bash aws-deploy/02-create-vpc.sh
echo "Step 2 completed!"

# Step 3: Create RDS MySQL Database
echo "Step 3: Creating RDS MySQL database..."
bash aws-deploy/03-create-rds.sh
echo "Step 3 completed!"

# Step 4: Create AWS Certificate Manager (ACM) Certificate
echo "Step 4: Creating SSL certificate..."
bash aws-deploy/04-create-certificate.sh
echo "Step 4 completed!"

# Step 5: Create AWS Secrets Manager Secrets
echo "Step 5: Creating AWS Secrets Manager secrets..."
bash aws-deploy/05-create-secrets.sh
echo "Step 5 completed!"

# Step 6: Create ECR Repository and Push Docker Image
echo "Step 6: Creating ECR repository and pushing Docker image..."
bash aws-deploy/06-create-ecr-push-image.sh
echo "Step 6 completed!"

# Step 7: Create IAM Role for ECS Task Execution
echo "Step 7: Creating IAM roles and policies..."
bash aws-deploy/07-create-iam-role.sh
echo "Step 7 completed!"

# Step 8: Create Application Load Balancer
echo "Step 8: Creating Application Load Balancer..."
bash aws-deploy/08-create-load-balancer.sh
echo "Step 8 completed!"

# Step 9: Create ECS Cluster, Task Definition, and Service
echo "Step 9: Creating ECS cluster, task definition, and service..."
bash aws-deploy/09-create-ecs.sh
echo "Step 9 completed!"

# Step 10: Configure Route 53 DNS Records
echo "Step 10: Configuring Route 53 DNS records..."
bash aws-deploy/10-configure-route53.sh
echo "Step 10 completed!"

echo "Deployment completed successfully!"
echo "Your application should be accessible at https://$DOMAIN_NAME and https://www.$DOMAIN_NAME"
echo "Note: It may take a few minutes for the DNS changes to propagate and for the ECS service to start the task." 