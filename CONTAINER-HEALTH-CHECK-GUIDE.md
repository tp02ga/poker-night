# Container Health Check Debugging Guide

This guide provides comprehensive information on debugging container health check issues in AWS ECS.

## Understanding Container Health Checks

In AWS ECS, there are two types of health checks:

1. **Load Balancer Health Checks**: These are performed by the ALB/NLB and check if the container is responding to HTTP requests.
2. **Container Health Checks**: These are performed by the ECS agent inside the container and check if the application is healthy.

These health checks can behave differently because they run in different contexts.

## Common Issues with Container Health Checks

### 1. Network Context Differences

The container health check runs from inside the container, while the load balancer health check comes from outside. This can lead to different network behaviors.

### 2. Command Execution Environment

The `CMD-SHELL` might be executing in a different environment than expected. For example, it might not have access to the same environment variables or tools.

### 3. Timing Issues

The container might not be fully ready when the health check runs. This is especially common with applications that take time to initialize.

## Solutions

### Solution 1: Simplify the Health Check Command

Sometimes, adding too many options to the curl command can cause issues. Try simplifying the command:

```json
"healthCheck": {
  "command": [
    "CMD-SHELL",
    "curl -f http://localhost:3000/api/health || exit 1"
  ]
}
```

### Solution 2: Create a Dedicated Health Check Endpoint

Create a super simple endpoint specifically for container health checks:

```typescript
// app/api/container-health/route.ts
import { NextResponse } from "next/server";

export async function GET() {
  return new NextResponse("OK", { status: 200 });
}
```

### Solution 3: Use a Health Check Script

Using a script provides better logging and diagnostic information:

```bash
#!/bin/sh
# container-healthcheck.sh

# Log file
LOG_FILE="/tmp/container-healthcheck.log"

# Log the start of the health check
echo "$(date): Starting container health check" >> $LOG_FILE

# Try the health check
RESPONSE=$(curl -s -f -o /dev/null -w "%{http_code}" http://localhost:3000/api/container-health)
RESULT=$?

# Log the result
if [ $RESULT -eq 0 ] && [ "$RESPONSE" = "200" ]; then
  echo "$(date): Health check successful (HTTP $RESPONSE)" >> $LOG_FILE
  exit 0
else
  echo "$(date): Health check failed (HTTP $RESPONSE, exit code $RESULT)" >> $LOG_FILE
  exit 1
fi
```

### Solution 4: Increase Health Check Grace Period

Give your application more time to start up:

```json
"healthCheck": {
  "command": ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 120  // Increase this value
}
```

### Solution 5: Check Container Logs

Look at the container logs to see if there are any errors during startup:

```bash
aws logs get-log-events --log-group-name /ecs/your-app --log-stream-name your-stream
```

## Accessing Container Health Check Logs

If you're using the health check script approach, you can access the logs by:

1. Connecting to the container using ECS Exec:

   ```bash
   aws ecs execute-command --cluster your-cluster --task your-task --container your-container --command "/bin/bash" --interactive
   ```

2. Viewing the log file:
   ```bash
   cat /tmp/container-healthcheck.log
   ```

## Recommended Approach

1. Create a dedicated health check endpoint
2. Use a health check script with logging
3. Increase the start period to give your application time to initialize
4. Update your Dockerfile to include the necessary tools
5. Deploy and monitor the logs

By following these steps, you should be able to diagnose and fix container health check issues.
