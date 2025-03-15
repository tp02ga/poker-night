# CI/CD Pipeline for Poker Night App

This repository includes a complete CI/CD pipeline using GitHub Actions to automate testing, building, and deploying the Poker Night App to Amazon ECS.

## Pipeline Overview

The CI/CD pipeline consists of two main workflows:

1. **Test Workflow** (`.github/workflows/test.yml`)

   - Triggered on push to main, pull requests to main, or manual trigger
   - Runs linting and tests to ensure code quality
   - Must pass before deployment can proceed

2. **Deploy Workflow** (`.github/workflows/deploy.yml`)
   - Triggered after successful test workflow, on push to main, or manual trigger
   - Builds a Docker image and pushes it to Amazon ECR
   - Updates the ECS task definition with the new image
   - Deploys the updated task definition to ECS
   - Waits for the service to stabilize

## Workflow Diagram

```
Code Push to Main → Test Workflow → Deploy Workflow → ECS Deployment
                                  ↓
Pull Request      → Test Workflow
```

## Setup Instructions

To set up the CI/CD pipeline, follow the detailed instructions in [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md).

## AWS Authentication

The GitHub Actions workflows authenticate with AWS using access keys stored as GitHub secrets:

- `AWS_ACCESS_KEY_ID`: The access key ID for an IAM user with appropriate permissions
- `AWS_SECRET_ACCESS_KEY`: The secret access key for the IAM user

A least-privilege IAM policy is provided in `github-actions-iam-policy.json` that should be attached to the IAM user.

## Environment Variables

The deployment workflow uses the following environment variables:

- `AWS_REGION`: The AWS region where your resources are located
- `ECR_REPOSITORY`: The name of your ECR repository
- `ECS_CLUSTER`: The name of your ECS cluster
- `ECS_SERVICE`: The name of your ECS service
- `ECS_TASK_FAMILY`: The family name of your ECS task definition

These variables are defined in the workflow file and can be customized as needed.

## Manual Deployment

You can manually trigger the deployment workflow from the "Actions" tab in GitHub. This is useful for deploying specific commits or when you need to redeploy without code changes.

## Monitoring Deployments

You can monitor the progress of your deployments in the "Actions" tab of your GitHub repository. The workflow will wait for the ECS service to stabilize before completing.
