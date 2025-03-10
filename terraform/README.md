# Terraform Infrastructure for Poker Night App

This directory contains Terraform code to deploy the Poker Night App to AWS ECS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- Docker installed locally
- A registered domain name in Route53 (purely-functional.net)

## Infrastructure Components

The Terraform code creates the following AWS resources:

- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- RDS MySQL database (publicly accessible for demo purposes)
- ECR repository for Docker images
- ECS cluster with EC2 instances (t3.micro)
- Application Load Balancer
- Route53 DNS records
- AWS Certificate Manager SSL certificate
- IAM roles and policies
- CloudWatch Log Group
- AWS Secrets Manager for environment variables

## Directory Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── terraform.tfvars (not in git - contains sensitive data)
├── modules/
│   ├── vpc/
│   ├── rds/
│   ├── ecr/
│   ├── ecs/
│   └── dns/
└── README.md
```

## Managing Sensitive Information

This project uses terraform.tfvars to store sensitive information. This file is not committed to Git.

1. Copy the example file:

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

2. Edit the terraform.tfvars file and fill in your own values:

```
db_password = "your-db-password"
jwt_secret = "your-jwt-secret"
google_client_id = "your-google-client-id"
google_client_secret = "your-google-client-secret"
```

## Deployment Steps

### 1. Set Up Sensitive Variables

Make sure you have created the terraform.tfvars file as described above.

### 2. Build and Push Docker Image

Before applying the Terraform code, you need to build and push the Docker image to ECR:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Build the Docker image
docker build -t poker-night-app .

# Tag the image
docker tag poker-night-app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/dev-poker-night-app:latest

# Push the image
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/dev-poker-night-app:latest
```

### 3. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan
```

### 5. Apply the Terraform Code

```bash
terraform apply
```

### 6. Automated Deployment

Alternatively, you can use the provided deployment script:

```bash
./terraform/deploy.sh
```

This script will:

- Check for the terraform.tfvars file
- Build and push your Docker image to ECR
- Deploy the infrastructure using Terraform
- Run the database migrations

### 7. Access the Application

After the deployment is complete, you can access the application at:

```
https://purely-functional.net
```

## Database Migration

After the infrastructure is deployed, you need to run the database migrations:

```bash
# Get the ECS task ARN
TASK_ARN=$(aws ecs run-task --cluster dev-poker-night-app-cluster --task-definition dev-poker-night-app --launch-type EC2 --overrides '{"containerOverrides":[{"name":"dev-poker-night-app","command":["npx","prisma","migrate","deploy"]}]}' --query 'tasks[0].taskArn' --output text)

# Wait for the task to complete
aws ecs wait tasks-stopped --cluster dev-poker-night-app-cluster --tasks $TASK_ARN
```

## Clean Up

To destroy all resources created by Terraform, you have two options:

### Option 1: Using the destroy script

```bash
# Make the script executable
chmod +x terraform/destroy.sh

# Run the script
./terraform/destroy.sh
```

This script will:

1. Ask for confirmation before proceeding
2. Initialize Terraform
3. Create a destruction plan
4. Ask for final confirmation
5. Destroy all resources
6. Optionally remove local Terraform state files

### Option 2: Manual destruction

```bash
# Change to the Terraform directory
cd terraform/environments/dev

# Initialize Terraform (if not already done)
terraform init

# Destroy all resources
terraform destroy
```

This will prompt you to confirm the destruction of all resources.

### Important Notes

- Destroying the infrastructure will delete all data in the RDS database
- If you have any important data, make sure to back it up before destroying the infrastructure
- Some resources like S3 buckets with objects or RDS instances with deletion protection may require manual intervention

## Notes

- The RDS instance is publicly accessible for demo purposes. In a production environment, it should be placed in a private subnet.
- The database password is set in terraform.tfvars and not committed to Git.
- The EC2 instances are t3.micro for cost optimization (free tier eligible).
- The domain name is set to "purely-functional.net". Make sure you have registered this domain in Route53 before applying the Terraform code.
