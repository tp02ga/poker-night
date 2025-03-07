#!/bin/bash

# Set your domain name here
DOMAIN_NAME="purely-functional.net"
HEALTH_ENDPOINT="/api/health"
INTERVAL_SECONDS=10
DURATION_MINUTES=30

# Calculate total checks
TOTAL_CHECKS=$((DURATION_MINUTES * 60 / INTERVAL_SECONDS))

echo "=== HEALTH CHECK MONITORING ==="
echo "Monitoring $DOMAIN_NAME$HEALTH_ENDPOINT"
echo "Interval: $INTERVAL_SECONDS seconds"
echo "Duration: $DURATION_MINUTES minutes ($TOTAL_CHECKS checks)"
echo "Press Ctrl+C to stop monitoring"
echo "==================================="

# Create a log file with timestamp
LOG_FILE="health-check-$(date +%Y%m%d-%H%M%S).log"
echo "Logging to $LOG_FILE"

# Initialize counters
success_count=0
failure_count=0

# Function to make a health check request
check_health() {
  local check_num=$1
  local start_time=$(date +%s.%N)
  
  # Make the request and capture the response
  response=$(curl -s -w "\n%{http_code}" "$DOMAIN_NAME$HEALTH_ENDPOINT")
  
  # Extract status code (last line) and response body (everything else)
  status_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  
  # Calculate request time
  local end_time=$(date +%s.%N)
  local elapsed=$(echo "$end_time - $start_time" | bc)
  
  # Log the result
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  if [ "$status_code" == "200" ]; then
    success_count=$((success_count + 1))
    echo "[$timestamp] CHECK #$check_num: SUCCESS ($status_code) - Time: ${elapsed}s"
    echo "[$timestamp] CHECK #$check_num: SUCCESS ($status_code) - Time: ${elapsed}s" >> "$LOG_FILE"
    echo "$body" | grep -E '"database"|"memory"|"error"' >> "$LOG_FILE"
  else
    failure_count=$((failure_count + 1))
    echo "[$timestamp] CHECK #$check_num: FAILURE ($status_code) - Time: ${elapsed}s"
    echo "[$timestamp] CHECK #$check_num: FAILURE ($status_code) - Time: ${elapsed}s" >> "$LOG_FILE"
    echo "$body" >> "$LOG_FILE"
  fi
  
  echo "---" >> "$LOG_FILE"
  
  # Calculate and display success rate
  total=$((success_count + failure_count))
  success_rate=$(echo "scale=2; $success_count * 100 / $total" | bc)
  echo "Success rate: $success_count/$total ($success_rate%)"
}

# Main monitoring loop
check_num=1
while [ $check_num -le $TOTAL_CHECKS ]; do
  check_health $check_num
  check_num=$((check_num + 1))
  sleep $INTERVAL_SECONDS
done

echo "=== MONITORING COMPLETE ==="
echo "Total checks: $((success_count + failure_count))"
echo "Successful: $success_count"
echo "Failed: $failure_count"
echo "Success rate: $(echo "scale=2; $success_count * 100 / ($success_count + $failure_count)" | bc)%"
echo "Detailed logs saved to $LOG_FILE" 