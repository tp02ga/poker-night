# GitHub Actions CI/CD Setup Guide

This guide explains how to set up the GitHub Actions CI/CD pipeline for the Poker Night App to automatically build and deploy to Amazon ECS.

## Prerequisites

1. An AWS account with appropriate permissions
2. A GitHub repository for your project
3. AWS ECS cluster, service, and task definition already set up
4. ECS service configured to use the 'latest' tag for the container image

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

### 3. Add Database and Application Secrets

Add the following additional secrets for your application:

1. `MYSQL_USER`: Database username
2. `MYSQL_PASSWORD`: Database password
3. `MYSQL_ROOT_PASSWORD`: MySQL root password
4. `JWT_SECRET`: Secret key for JWT authentication
5. `GOOGLE_CLIENT_ID`: Google OAuth client ID (if used)
6. `GOOGLE_CLIENT_SECRET`: Google OAuth client secret (if used)
7. `NEXT_PUBLIC_APP_URL`: Public URL of your application

These secrets will be passed as build arguments to Docker during the build process.

## Customizing the Workflow

The workflow file (`.github/workflows/deploy.yml`) contains environment variables that you may need to customize:

```yaml
env:
  AWS_REGION: us-east-1 # Your AWS region
  ECR_REPOSITORY: dev-poker-night-app # Your ECR repository name
  ECS_CLUSTER: dev-poker-night-app-cluster # Your ECS cluster name
  ECS_SERVICE: dev-poker-night-app-service # Your ECS service name
  ECS_TASK_FAMILY: dev-poker-night-app # Your ECS task definition family
```

Update these values to match your AWS environment.

## ECS Service Configuration

For this deployment approach to work, your ECS service should be configured to:

1. Use the 'latest' tag for the container image
2. Have a task definition that references the ECR repository with the 'latest' tag

When the GitHub Actions workflow runs, it will:

1. Build and push a new image to ECR with the 'latest' tag
2. Force a new deployment of the ECS service
3. The ECS service will automatically use the new 'latest' image

## Environment Variables in ECS Task Definition

Make sure your ECS task definition includes the necessary environment variables for your application. You can set these in the task definition's container definition:

```json
"environment": [
  { "name": "MYSQL_USER", "value": "your_db_username" },
  { "name": "MYSQL_PASSWORD", "value": "your_db_password" },
  { "name": "MYSQL_ROOT_PASSWORD", "value": "your_root_password" },
  { "name": "JWT_SECRET", "value": "your_jwt_secret" },
  { "name": "GOOGLE_CLIENT_ID", "value": "your_google_client_id" },
  { "name": "GOOGLE_CLIENT_SECRET", "value": "your_google_client_secret" },
  { "name": "NEXT_PUBLIC_APP_URL", "value": "your_app_url" },
  { "name": "DATABASE_URL", "value": "mysql://your_db_username:your_db_password@your_db_host:3306/poker_game_planner" }
]
```

For sensitive values, consider using AWS Secrets Manager and reference them in your task definition.

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
6. Ensure all required environment variables are properly set in both GitHub secrets and ECS task definition
