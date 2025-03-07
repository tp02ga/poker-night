# AWS ECS Deployment Scripts for Poker Night App

This directory contains scripts to deploy the Poker Night App to AWS ECS. The scripts create all the necessary AWS resources in the proper order, including VPC, RDS, ECS, and more.

## Prerequisites

Before running these scripts, make sure you have the following:

1. AWS CLI installed and configured with appropriate credentials
2. Docker installed and running
3. `jq` command-line tool installed (for JSON processing)
4. Bash shell environment
5. AWS account with permissions to create all required resources
6. A registered domain name that you can configure nameservers for

## Windows Users (Git Bash)

If you're using Git Bash on Windows, the scripts include `export MSYS_NO_PATHCONV=1` to disable path conversion. This prevents Git Bash from converting forward slashes (`/`) in parameters to Windows paths, which can cause issues with AWS CLI commands.

If you encounter any path-related errors, you can manually set this environment variable before running the scripts:

```bash
export MSYS_NO_PATHCONV=1
```

## Environment Variables

The deployment scripts use environment variables defined in `env-vars.sh`. You can modify this file to customize your deployment.

## Deployment Steps

The deployment process is divided into several steps, each handled by a separate script:

0. **00-configure-aws-cli.sh**: Configures AWS CLI with your access key and secret key
1. **01-setup.sh**: Configures AWS CLI and sets up environment variables
2. **02-create-vpc.sh**: Creates VPC, subnets, internet gateway, and security groups
3. **03-create-rds.sh**: Creates RDS MySQL database
4. **04-create-certificate.sh**: Creates Route 53 hosted zone and SSL certificate with AWS Certificate Manager
5. **05-create-secrets.sh**: Creates AWS Secrets Manager secrets for environment variables
6. **06-create-ecr-push-image.sh**: Creates ECR repository and pushes Docker image
7. **07-create-iam-role.sh**: Creates IAM roles and policies for ECS tasks
8. **08-create-load-balancer.sh**: Creates Application Load Balancer
9. **09-create-ecs.sh**: Creates ECS cluster, task definition, and service
10. **10-configure-route53.sh**: Configures Route 53 DNS records

## Domain Configuration

During the deployment process (step 4), the script will:

1. Create a Route 53 hosted zone for your domain
2. Display the nameservers assigned to your hosted zone
3. Prompt you to update your domain's nameservers at your domain registrar
4. Wait for you to confirm before proceeding with certificate creation

This step is crucial for DNS validation of your SSL certificate. You must update your domain's nameservers at your domain registrar for the certificate validation to succeed. DNS propagation can take up to 48 hours, but often completes within a few hours.

## Running the Deployment

To deploy the application, first make the scripts executable:

```bash
chmod +x aws-deploy/*.sh
```

Then run the master deployment script:

```bash
./aws-deploy/deploy.sh
```

This will execute all the steps in sequence, starting with configuring your AWS credentials. The deployment process may take 30-45 minutes to complete, primarily due to the time required for RDS instance creation and certificate validation.

## AWS Credentials

The first script (`00-configure-aws-cli.sh`) will prompt you for your AWS credentials:

- AWS Access Key ID
- AWS Secret Access Key
- Default region (defaults to us-east-1)
- Default output format (defaults to json)

Make sure you have these credentials ready before starting the deployment. You can create an IAM user with programmatic access in your AWS account to get these credentials.

## Cleaning Up

When you're done with the application, you can clean up all AWS resources by running the cleanup script:

```bash
./aws-deploy/cleanup.sh
```

This will delete all the resources created by the deployment scripts.

## Outputs

During the deployment, various resource identifiers and endpoints are stored in the `aws-deploy/outputs/` directory. These files are used by subsequent scripts and can be referenced if you need to manually interact with any of the resources.

## Troubleshooting

If any step fails, you can examine the error message and rerun the specific script after fixing the issue. Each script is designed to be idempotent where possible, but you may need to clean up partially created resources in some cases.

## Security Note

The scripts create a publicly accessible RDS instance for demonstration purposes. In a production environment, you would typically place the RDS instance in a private subnet and use a bastion host or VPN for access.

Additionally, the scripts use hardcoded passwords and secrets. In a production environment, you should use more secure methods for managing secrets, such as AWS Secrets Manager with automatic rotation.
