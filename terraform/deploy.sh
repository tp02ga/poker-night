#!/bin/bash
set -e

# Change to the project root directory
cd "$(dirname "$0")/.."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install it first."
    exit 1
fi

# Change to the Terraform directory
cd terraform/environments/dev

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars file not found."
    echo "Please create a terraform.tfvars file with the following variables:"
    echo "  db_password = \"your-db-password\""
    echo "  jwt_secret = \"your-jwt-secret\""
    echo "  google_client_id = \"your-google-client-id\""
    echo "  google_client_secret = \"your-google-client-secret\""
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_REPOSITORY="dev-poker-night-app"
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "=== Building Docker image ==="

# Build the Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPOSITORY_URL}:latest ~/git/poker-night-app

echo "=== Deploying infrastructure with Terraform ==="

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan the deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply the Terraform code
echo "Applying Terraform deployment..."
terraform apply tfplan

# Check if the Route53 zone exists
DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "purely-functional.net")
echo "Checking if Route53 zone exists for domain: ${DOMAIN_NAME}"
if ! aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN_NAME}." --max-items 1 | grep -q "Name\": \"${DOMAIN_NAME}."; then
    echo "Warning: Route53 zone for ${DOMAIN_NAME} not found."
    echo "Please create a Route53 hosted zone for your domain before proceeding."
    echo "You can create it in the AWS console or using the AWS CLI:"
    echo "aws route53 create-hosted-zone --name ${DOMAIN_NAME} --caller-reference $(date +%s)"
    echo "Then update your domain's name servers at your domain registrar."
    echo "Continuing with deployment, but certificate validation will fail until the zone exists."
fi

echo "=== Pushing Docker image to ECR ==="

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Push the image
echo "Pushing Docker image to ECR..."
docker push ${ECR_REPOSITORY_URL}:latest

# Get the ECS cluster name and task definition
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
ECS_TASK_DEFINITION=$(terraform output -raw ecs_service_name | sed 's/-service$//')

echo "=== Running database migrations ==="

# Run the database migrations
echo "Running database migrations..."
TASK_ARN=$(aws ecs run-task --cluster ${ECS_CLUSTER_NAME} --task-definition ${ECS_TASK_DEFINITION} --launch-type EC2 --overrides '{"containerOverrides":[{"name":"'${ECS_TASK_DEFINITION}'","command":["npx","prisma","migrate","deploy"]}]}' --query 'tasks[0].taskArn' --output text)

echo "Waiting for migration task to complete..."
aws ecs wait tasks-stopped --cluster ${ECS_CLUSTER_NAME} --tasks ${TASK_ARN}

echo "=== Deployment completed successfully ==="
echo "You can access the application at: $(terraform output -raw application_url)"
echo ""
echo "Note: It may take a few minutes for the SSL certificate to be validated."
echo "You can check the status of the certificate in the AWS console:"
echo "https://console.aws.amazon.com/acm/home?region=${AWS_REGION}#/certificates/list" 