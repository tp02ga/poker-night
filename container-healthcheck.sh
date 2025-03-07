#!/bin/sh

# Container health check script
# This script provides better logging for container health checks

# Log file
LOG_FILE="/tmp/container-healthcheck.log"

# Function to log to both file and stdout (for CloudWatch)
log() {
  echo "$(date): $1" >> $LOG_FILE
  echo "HEALTHCHECK: $1" >&2  # Log to stderr which goes to CloudWatch
}

# Log the start of the health check
log "Starting container health check"

# Try the health check
RESPONSE=$(curl -s -f -o /dev/null -w "%{http_code}" http://localhost:3000/api/container-health)
RESULT=$?

# Log the result
if [ $RESULT -eq 0 ] && [ "$RESPONSE" = "200" ]; then
  log "Health check successful (HTTP $RESPONSE)"
  exit 0
else
  log "Health check failed (HTTP $RESPONSE, exit code $RESULT)"
  
  # Try to get more diagnostic information
  log "Diagnostic information:"
  
  log "Network status:"
  # Use netstat from busybox-extras instead of net-tools
  netstat -tulpn >> $LOG_FILE 2>&1
  
  log "Process status:"
  ps aux >> $LOG_FILE 2>&1
  
  log "Curl verbose output:"
  CURL_OUTPUT=$(curl -v http://localhost:3000/api/container-health 2>&1)
  echo "$CURL_OUTPUT" >> $LOG_FILE
  echo "HEALTHCHECK CURL: $CURL_OUTPUT" >&2  # Also send to CloudWatch
  
  # Additional diagnostic information
  log "Node.js process:"
  ps | grep node >> $LOG_FILE 2>&1
  
  log "Container IP and network info:"
  ip addr >> $LOG_FILE 2>&1 || log "ip command not available"
  
  log "DNS resolution test:"
  nslookup localhost >> $LOG_FILE 2>&1 || log "nslookup command not available"
  
  # Test if the container-health endpoint exists
  log "Testing if endpoint exists:"
  curl -s -I http://localhost:3000/api/container-health >> $LOG_FILE 2>&1
  
  # Test if the application is running at all
  log "Testing root endpoint:"
  curl -s -I http://localhost:3000/ >> $LOG_FILE 2>&1
  
  exit 1
fi 