# GitHub Actions CI/CD Setup Guide

This guide explains how to set up the GitHub Actions CI/CD pipeline for the Poker Night App to automatically build and deploy to Amazon ECS.

## Prerequisites

1. An AWS account with appropriate permissions
2. A GitHub repository for your project
3. AWS ECS cluster, service, and task definition already set up
4. ECS service configured to use the 'latest' tag for the container image
5. AWS Secrets Manager secret already configured in your task definition

## Setting Up AWS Credentials for GitHub Actions

GitHub Actions needs permissions to interact with AWS services. We'll use AWS access keys stored as GitHub secrets.

### 1. Create an IAM User with Appropriate Permissions

1. Go to the AWS IAM console
2. Navigate to "Users" and click "Add user"
3. Enter a name for the user (e.g., `github-actions-poker-night`)
4. Select "Programmatic access" for the access type
5. Click "Next: Permissions"
6. Create a custom policy using the provided `github-actions-iam-policy.json` file:
   - Go to IAM > Policies > Create policy
   - Switch to the JSON tab
   - Copy the contents of `github-actions-iam-policy.json`
   - Name the policy (e.g., `GitHubActionsECSDeployPolicy`)
7. Attach this policy to the user
8. Complete the user creation process
9. Save the Access Key ID and Secret Access Key that are generated

### 2. Add AWS Credentials to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Add the following secrets:
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: The Access Key ID from the IAM user you created
5. Click "Add secret"
6. Add another secret:
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: The Secret Access Key from the IAM user you created
7. Click "Add secret"

### 3. Add Application Secrets

Add the following additional secrets for your application:

1. `DATABASE_URL`: Complete database connection string
2. `JWT_SECRET`: Secret key for JWT authentication
3. `GOOGLE_CLIENT_ID`: Google OAuth client ID (if used)
4. `GOOGLE_CLIENT_SECRET`: Google OAuth client secret (if used)
5. `NEXT_PUBLIC_APP_URL`: Public URL of your application

These secrets will be updated in AWS Secrets Manager during the CI/CD process to match your GitHub secrets.

## Customizing the Workflow

The workflow file (`.github/workflows/deploy.yml`) contains environment variables that you may need to customize:

```yaml
env:
  AWS_REGION: us-east-1 # Your AWS region
  ECR_REPOSITORY: dev-poker-night-app # Your ECR repository name
  ECS_CLUSTER: dev-poker-night-app-cluster # Your ECS cluster name
  ECS_SERVICE: dev-poker-night-app-service # Your ECS service name
  ECS_TASK_FAMILY: dev-poker-night-app # Your ECS task definition family
  SECRETS_NAME: dev-poker-night-app-environment-vars # Your Secrets Manager secret name
```

Update these values to match your AWS environment.

## ECS Service Configuration

Your ECS service is already configured to:

1. Use the 'latest' tag for the container image
2. Reference secrets from AWS Secrets Manager in the task definition

The CI/CD pipeline will:

1. Build and push a new image to ECR with the 'latest' tag
2. Update the secrets in AWS Secrets Manager with values from GitHub secrets
3. Force a new deployment of the ECS service
4. The ECS service will automatically use the new 'latest' image and updated secrets

## Secure Secrets Management

This setup maintains a secure approach for handling sensitive information:

1. Secrets are stored in GitHub Actions secrets for the CI/CD process
2. During deployment, secrets are updated in AWS Secrets Manager
3. The ECS task definition references secrets from AWS Secrets Manager
4. No sensitive information is stored in Docker images or environment variables

## Triggering the Workflow

The workflow is configured to run automatically when:

- Code is pushed to the `main` branch
- Manually triggered via the "Actions" tab in GitHub

## Monitoring Deployments

You can monitor the progress of your deployments in the "Actions" tab of your GitHub repository.

## Troubleshooting

If the workflow fails, check the following:

1. Verify that the IAM user has the necessary permissions
2. Ensure that the environment variables in the workflow match your AWS resources
3. Check the GitHub Actions logs for specific error messages
4. Verify that the AWS credentials are correctly stored as GitHub secrets
5. Confirm that your ECS service is configured to use the 'latest' tag
6. Ensure the Secrets Manager secret name is correct
