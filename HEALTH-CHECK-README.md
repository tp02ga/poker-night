# Health Check Implementation

This document describes the health check implementation for the Poker Night App.

## Overview

The application includes a dedicated health check endpoint at `/api/health` that:

1. Verifies database connectivity
2. Returns appropriate HTTP status codes (200 for healthy, 503 for unhealthy)
3. Provides detailed health information in the response body

## Health Check Endpoint

The health check endpoint is implemented in `app/api/health/route.ts` and performs the following checks:

- Database connectivity: Executes a lightweight query to verify the database connection
- Returns a JSON response with health status information

### Sample Response (Healthy)

```json
{
  "status": "ok",
  "timestamp": "2023-06-01T12:34:56.789Z",
  "uptime": 3600,
  "environment": "production",
  "database": "connected"
}
```

### Sample Response (Unhealthy)

```json
{
  "status": "error",
  "timestamp": "2023-06-01T12:34:56.789Z",
  "error": "Database connection failed"
}
```

## AWS Configuration

The health check is configured in AWS as follows:

### Load Balancer Health Check

- Path: `/api/health`
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 2

### ECS Task Definition Health Check

- Command: `curl -f http://localhost:3000/api/health || exit 1`
- Interval: 30 seconds
- Timeout: 5 seconds
- Retries: 3
- Start period: 60 seconds

## Updating Existing AWS Resources

If you need to update existing AWS resources with the new health check configuration, use the provided scripts:

### Update Target Group Health Check

To update an existing target group with the new health check path:

```bash
./update-health-check.sh
```

This script will:

1. Source environment variables and outputs if available
2. Prompt for the target group name or ARN if not found
3. Update the target group with the new health check path
4. Verify the changes

### Update ECS Service with New Task Definition

After updating the task definition with the new health check, update the ECS service:

```bash
./update-ecs-service.sh
```

This script will:

1. Source environment variables and outputs if available
2. Prompt for cluster name, service name, and task family if not found
3. Get the latest task definition
4. Update the ECS service with the new task definition
5. Monitor the deployment status

## Troubleshooting

If health checks are failing:

1. Check if the application is running and accessible
2. Verify database connectivity
3. Check the application logs for any errors
4. Ensure the health check endpoint is responding with a 200 status code

## Updating Health Checks

If you need to modify the health check:

1. Update the implementation in `app/api/health/route.ts`
2. Update the AWS configuration in the deployment scripts:
   - `aws-deploy/08-create-load-balancer.sh`
   - `aws-deploy/09-create-ecs.sh`
   - `aws-deploy/aws-deploy/task-definition.json`
3. Run the update scripts to apply changes to existing resources
