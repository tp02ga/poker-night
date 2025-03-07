#!/bin/bash

# Disable path conversion in Git Bash
export MSYS_NO_PATHCONV=1

# Source environment variables
source aws-deploy/env-vars.sh

# Load VPC outputs
source aws-deploy/outputs/vpc-outputs.txt

# Load certificate outputs
source aws-deploy/outputs/cert-outputs.txt

echo "Creating Application Load Balancer..."

# Create Application Load Balancer
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name $LB_NAME \
  --subnets $PUBLIC_SUBNET_1_ID $PUBLIC_SUBNET_2_ID \
  --security-groups $ALB_SG_ID \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "Application Load Balancer created: $ALB_ARN"
echo "ALB_ARN=$ALB_ARN" >> aws-deploy/outputs/alb-outputs.txt

# Get the ALB DNS name
ALB_DNS_NAME=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS Name: $ALB_DNS_NAME"
echo "ALB_DNS_NAME=$ALB_DNS_NAME" >> aws-deploy/outputs/alb-outputs.txt

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
  --name $TG_NAME \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /api/health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group created: $TG_ARN"
echo "TG_ARN=$TG_ARN" >> aws-deploy/outputs/alb-outputs.txt

# Create HTTPS listener
HTTPS_LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERTIFICATE_ARN \
  --ssl-policy ELBSecurityPolicy-2016-08 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "HTTPS Listener created: $HTTPS_LISTENER_ARN"
echo "HTTPS_LISTENER_ARN=$HTTPS_LISTENER_ARN" >> aws-deploy/outputs/alb-outputs.txt

# Create HTTP listener with redirect to HTTPS
HTTP_LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,Host='#{host}',Path='/#{path}',Query='#{query}',StatusCode=HTTP_301}" \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "HTTP Listener created with redirect to HTTPS: $HTTP_LISTENER_ARN"
echo "HTTP_LISTENER_ARN=$HTTP_LISTENER_ARN" >> aws-deploy/outputs/alb-outputs.txt

echo "Application Load Balancer setup completed!" 