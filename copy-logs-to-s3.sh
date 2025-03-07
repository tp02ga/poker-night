#!/bin/bash

# Script to copy health check logs from a container to S3
# Usage: ./copy-logs-to-s3.sh <cluster-name> <task-id> <s3-bucket>

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <cluster-name> <task-id> <s3-bucket>"
    echo "Example: $0 poker-night-app-cluster 1234567890abcdef0 my-logs-bucket"
    exit 1
fi

CLUSTER_NAME=$1
TASK_ID=$2
S3_BUCKET=$3
CONTAINER_NAME="poker-night-app"
LOG_FILE="/tmp/container-healthcheck.log"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOCAL_FILE="healthcheck-${TASK_ID}-${TIMESTAMP}.log"

echo "Copying health check logs from task ${TASK_ID} to S3 bucket ${S3_BUCKET}..."

# Create a script to cat the log file
cat > get-logs.sh << EOL
#!/bin/sh
cat ${LOG_FILE}
EOL
chmod +x get-logs.sh

# Use ECS Exec to run the script and capture the output
aws ecs execute-command \
  --cluster ${CLUSTER_NAME} \
  --task ${TASK_ID} \
  --container ${CONTAINER_NAME} \
  --command "/bin/sh -c 'if [ -f ${LOG_FILE} ]; then cat ${LOG_FILE}; else echo \"Log file not found\"; fi'" \
  --interactive > ${LOCAL_FILE}

# Check if the log file was captured
if [ ! -s "${LOCAL_FILE}" ]; then
    echo "Failed to capture logs or log file is empty."
    exit 1
fi

# Upload the log file to S3
aws s3 cp ${LOCAL_FILE} s3://${S3_BUCKET}/${LOCAL_FILE}

# Clean up
rm ${LOCAL_FILE}

echo "Logs copied to s3://${S3_BUCKET}/${LOCAL_FILE}"
echo "You can download them with: aws s3 cp s3://${S3_BUCKET}/${LOCAL_FILE} ." 