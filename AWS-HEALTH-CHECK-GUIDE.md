# AWS Health Check Troubleshooting Guide

This guide will help you diagnose health check issues in the AWS Console.

## 1. Check Target Group Health Status

1. Go to the **EC2 Dashboard** in AWS Console
2. In the left navigation pane, under **Load Balancing**, click on **Target Groups**
3. Select your target group (likely named `poker-night-app-tg`)
4. Click on the **Targets** tab
5. Look at the **Health Status** column for your targets

If targets are showing as "unhealthy", this confirms there's an issue with the health check.

## 2. Check CloudWatch Logs for Application Errors

1. Go to the **CloudWatch** service in AWS Console
2. In the left navigation pane, click on **Log groups**
3. Find the log group for your ECS service (typically `/ecs/poker-night-app`)
4. Click on the most recent log stream
5. Look for any errors related to:
   - The `/api/health` endpoint
   - Database connection issues
   - Application startup problems

## 3. Check ECS Task Status

1. Go to the **ECS** service in AWS Console
2. Click on your cluster (likely named `poker-night-app-cluster`)
3. Click on the **Tasks** tab
4. Look for any stopped tasks and check their **Stopped reason**
5. For running tasks, click on the task ID to see details
6. Check the **Health Status** and **Last Status** of the containers

## 4. Verify Security Group Settings

1. Go to the **EC2 Dashboard** in AWS Console
2. In the left navigation pane, click on **Security Groups**
3. Find the security group used by your ECS tasks
4. Check that it allows:
   - Inbound traffic on port 3000 from the ALB security group
   - Outbound traffic to your RDS database (port 3306)

## 5. Check RDS Database Connectivity

1. Go to the **RDS** service in AWS Console
2. Click on your database instance
3. Check the **Status** to ensure it's "Available"
4. Verify the **Security group** allows connections from your ECS tasks
5. Check the **Connectivity & security** tab to ensure the endpoint is correct

## 6. Test the Health Check Endpoint Using a Diagnostic Task

If you can't directly SSH into your containers, you can run a diagnostic task:

```bash
./run-diagnostic-task.sh
```

This script will:

1. Create a diagnostic task based on your current task definition
2. Override the command to test the health check endpoint and database connection
3. Run the task and show you where to find the logs

## 7. Common Health Check Issues and Solutions

### Issue: Database Connection Failures

**Symptoms:**

- Health check endpoint returns 503 status code
- Logs show database connection errors

**Solutions:**

- Verify the DATABASE_URL environment variable is correct
- Check that the RDS security group allows connections from ECS tasks
- Ensure the database is running and accessible

### Issue: Application Not Starting Correctly

**Symptoms:**

- Tasks are stopping shortly after starting
- Logs show startup errors

**Solutions:**

- Check for syntax errors in your code
- Verify all required environment variables are set
- Check for memory issues (the container might be running out of memory)

### Issue: Health Check Path Mismatch

**Symptoms:**

- Health check fails but application is running
- No errors in application logs

**Solutions:**

- Verify the health check path in the target group matches the endpoint in your application
- Check that the application is listening on the correct port (3000)

## 8. Using AWS CLI for Diagnostics

If you prefer using the AWS CLI, you can run the diagnostic script:

```bash
./diagnose-health-check.sh
```

This will provide comprehensive information about your health check configuration and status.
