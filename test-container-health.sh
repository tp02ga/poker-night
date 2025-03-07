#!/bin/bash

# Script to test if the container-health endpoint is accessible
# Usage: ./test-container-health.sh <cluster-name> <task-id>

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <cluster-name> <task-id>"
    echo "Example: $0 poker-night-app-cluster 1234567890abcdef0"
    exit 1
fi

CLUSTER_NAME=$1
TASK_ID=$2
CONTAINER_NAME="poker-night-app"

echo "Testing container-health endpoint in task ${TASK_ID}..."

# Create a test script
cat > test-endpoint.sh << EOL
#!/bin/sh
echo "Testing container-health endpoint..."
echo "Curl with verbose output:"
curl -v http://localhost:3000/api/container-health

echo "\nTesting if Next.js server is running:"
ps aux | grep node

echo "\nChecking network ports:"
netstat -tulpn | grep 3000

echo "\nTesting root endpoint:"
curl -v http://localhost:3000/
EOL
chmod +x test-endpoint.sh

# Use ECS Exec to run the test script
aws ecs execute-command \
  --cluster ${CLUSTER_NAME} \
  --task ${TASK_ID} \
  --container ${CONTAINER_NAME} \
  --command "/bin/sh -c 'curl -v http://localhost:3000/api/container-health'" \
  --interactive

echo "Test completed." 