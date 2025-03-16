# Setting Up AWS Secrets Manager for ECS

This guide explains how to securely manage sensitive information using AWS Secrets Manager with Amazon ECS.

## Overview

Instead of storing sensitive information in environment variables or build arguments, we'll use AWS Secrets Manager to securely store and retrieve secrets at runtime. This approach offers several advantages:

1. Secrets are not stored in the Docker image or its layers
2. Secrets can be rotated without rebuilding the image
3. Access to secrets can be tightly controlled with IAM policies
4. Secrets are encrypted at rest and in transit

## Step 1: Create Secrets in AWS Secrets Manager

Our CI/CD pipeline will automatically create or update the following secrets:

1. `/dev-poker-night-app/database` - Contains database credentials
2. `/dev-poker-night-app/auth` - Contains authentication secrets

You can also manually create these secrets:

1. Go to the AWS Secrets Manager console
2. Click "Store a new secret"
3. Select "Other type of secret"
4. Add the key-value pairs for your secrets
5. Name the secret with the appropriate prefix (e.g., `/dev-poker-night-app/database`)
6. Complete the creation process

## Step 2: Update ECS Task Definition to Use Secrets

Update your ECS task definition to reference secrets from AWS Secrets Manager instead of using environment variables directly:

```json
{
  "containerDefinitions": [
    {
      "name": "app",
      "image": "your-ecr-repo/dev-poker-night-app:latest",
      "secrets": [
        {
          "name": "MYSQL_USER",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/database:MYSQL_USER::"
        },
        {
          "name": "MYSQL_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/database:MYSQL_PASSWORD::"
        },
        {
          "name": "MYSQL_ROOT_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/database:MYSQL_ROOT_PASSWORD::"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/auth:JWT_SECRET::"
        },
        {
          "name": "GOOGLE_CLIENT_ID",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/auth:GOOGLE_CLIENT_ID::"
        },
        {
          "name": "GOOGLE_CLIENT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/auth:GOOGLE_CLIENT_SECRET::"
        },
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:region:account-id:secret:/dev-poker-night-app/database:DATABASE_URL::"
        }
      ],
      "environment": [
        {
          "name": "NEXT_PUBLIC_APP_URL",
          "value": "your-app-url"
        },
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ]
    }
  ]
}
```

Replace `region` and `account-id` with your AWS region and account ID.

## Step 3: Update ECS Task Execution Role

The ECS task execution role needs permission to read the secrets from AWS Secrets Manager. Attach the following policy to your task execution role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:*:*:secret:/dev-poker-night-app/*"]
    }
  ]
}
```

## Step 4: Create a Complete DATABASE_URL Secret

Since the DATABASE_URL needs to be constructed from multiple secrets, you should create a separate secret for it:

1. Go to the AWS Secrets Manager console
2. Create a new secret with the key `DATABASE_URL`
3. Set the value to `mysql://username:password@your-db-host:3306/poker_game_planner`
4. Replace `username`, `password`, and `your-db-host` with your actual database credentials and host

## Local Development

For local development, continue using the `.env` file with Docker Compose. The Docker Compose setup remains unchanged, as it's only used for development and not for production deployments.

## Security Best Practices

1. Use the principle of least privilege when granting IAM permissions
2. Regularly rotate your secrets
3. Enable encryption at rest for your secrets
4. Monitor access to your secrets using AWS CloudTrail
5. Consider using automatic rotation for database credentials
