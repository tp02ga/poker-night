#!/bin/bash

# Disable path conversion in Git Bash (for Windows)
export MSYS_NO_PATHCONV=1

# Source environment variables
source aws-deploy/env-vars.sh

# Load outputs if they exist
if [ -f aws-deploy/outputs/ecs-outputs.txt ]; then
  source aws-deploy/outputs/ecs-outputs.txt
fi

if [ -f aws-deploy/outputs/alb-outputs.txt ]; then
  source aws-deploy/outputs/alb-outputs.txt
fi

if [ -f aws-deploy/outputs/iam-outputs.txt ]; then
  source aws-deploy/outputs/iam-outputs.txt
fi

if [ -f aws-deploy/outputs/ecr-outputs.txt ]; then
  source aws-deploy/outputs/ecr-outputs.txt
fi

if [ -f aws-deploy/outputs/secrets-outputs.txt ]; then
  source aws-deploy/outputs/secrets-outputs.txt
fi

if [ -f aws-deploy/outputs/cert-outputs.txt ]; then
  source aws-deploy/outputs/cert-outputs.txt
fi

if [ -f aws-deploy/outputs/rds-outputs.txt ]; then
  source aws-deploy/outputs/rds-outputs.txt
fi

if [ -f aws-deploy/outputs/vpc-outputs.txt ]; then
  source aws-deploy/outputs/vpc-outputs.txt
fi

if [ -f aws-deploy/outputs/route53-outputs.txt ]; then
  source aws-deploy/outputs/route53-outputs.txt
fi

echo "Starting cleanup of AWS resources..."

# Step 1: Delete Route 53 DNS records
echo "Deleting Route 53 DNS records..."
aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "'"$DOMAIN_NAME"'",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "Z35SXDOTRQ7X7K",
            "DNSName": "'"$ALB_DNS_NAME"'",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }' || echo "Failed to delete apex domain record, continuing..."

aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "'"www.$DOMAIN_NAME"'",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "Z35SXDOTRQ7X7K",
            "DNSName": "'"$ALB_DNS_NAME"'",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }' || echo "Failed to delete www subdomain record, continuing..."

# Delete certificate validation records
echo "Deleting certificate validation records..."
# We need to get the validation record details again
if [ ! -z "$CERTIFICATE_ARN" ]; then
  VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn $CERTIFICATE_ARN \
    --query 'Certificate.DomainValidationOptions')

  # Extract validation details
  DOMAIN_NAME_VALUE=$(echo $VALIDATION_RECORDS | jq -r '.[0].ResourceRecord.Name')
  DOMAIN_NAME_TYPE=$(echo $VALIDATION_RECORDS | jq -r '.[0].ResourceRecord.Type')
  DOMAIN_NAME_RECORD=$(echo $VALIDATION_RECORDS | jq -r '.[0].ResourceRecord.Value')

  WWW_DOMAIN_NAME_VALUE=$(echo $VALIDATION_RECORDS | jq -r '.[1].ResourceRecord.Name')
  WWW_DOMAIN_NAME_TYPE=$(echo $VALIDATION_RECORDS | jq -r '.[1].ResourceRecord.Type')
  WWW_DOMAIN_NAME_RECORD=$(echo $VALIDATION_RECORDS | jq -r '.[1].ResourceRecord.Value')

  # Delete validation records
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ROUTE53_ZONE_ID \
    --change-batch '{
      "Changes": [
        {
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "'"$DOMAIN_NAME_VALUE"'",
            "Type": "'"$DOMAIN_NAME_TYPE"'",
            "TTL": 300,
            "ResourceRecords": [
              {
                "Value": "'"$DOMAIN_NAME_RECORD"'"
              }
            ]
          }
        }
      ]
    }' || echo "Failed to delete apex domain validation record, continuing..."

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ROUTE53_ZONE_ID \
    --change-batch '{
      "Changes": [
        {
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "'"$WWW_DOMAIN_NAME_VALUE"'",
            "Type": "'"$WWW_DOMAIN_NAME_TYPE"'",
            "TTL": 300,
            "ResourceRecords": [
              {
                "Value": "'"$WWW_DOMAIN_NAME_RECORD"'"
              }
            ]
          }
        }
      ]
    }' || echo "Failed to delete www subdomain validation record, continuing..."
fi

# Step 2: Delete ECS service and cluster
echo "Deleting ECS service..."
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --desired-count 0 || echo "Failed to update service, continuing..."

aws ecs delete-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --force || echo "Failed to delete service, continuing..."

echo "Deleting ECS cluster..."
aws ecs delete-cluster \
  --cluster $ECS_CLUSTER_NAME || echo "Failed to delete cluster, continuing..."

# Step 3: Delete ALB and target group
echo "Deleting ALB listeners..."
aws elbv2 delete-listener \
  --listener-arn $HTTPS_LISTENER_ARN || echo "Failed to delete HTTPS listener, continuing..."

aws elbv2 delete-listener \
  --listener-arn $HTTP_LISTENER_ARN || echo "Failed to delete HTTP listener, continuing..."

echo "Deleting ALB..."
aws elbv2 delete-load-balancer \
  --load-balancer-arn $ALB_ARN || echo "Failed to delete ALB, continuing..."

echo "Deleting target group..."
aws elbv2 delete-target-group \
  --target-group-arn $TG_ARN || echo "Failed to delete target group, continuing..."

# Step 4: Delete IAM roles and policies
echo "Detaching and deleting IAM policies..."
aws iam detach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn $SECRETS_POLICY_ARN || echo "Failed to detach secrets policy, continuing..."

aws iam detach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn $LOGS_POLICY_ARN || echo "Failed to detach logs policy, continuing..."

aws iam detach-role-policy \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || echo "Failed to detach ECS task execution policy, continuing..."

aws iam delete-policy \
  --policy-arn $SECRETS_POLICY_ARN || echo "Failed to delete secrets policy, continuing..."

aws iam delete-policy \
  --policy-arn $LOGS_POLICY_ARN || echo "Failed to delete logs policy, continuing..."

echo "Deleting IAM roles..."
aws iam delete-role \
  --role-name $ECS_TASK_EXECUTION_ROLE_NAME || echo "Failed to delete task execution role, continuing..."

aws iam delete-role \
  --role-name $ECS_TASK_ROLE_NAME || echo "Failed to delete task role, continuing..."

# Step 5: Delete ECR repository
echo "Deleting ECR repository..."
aws ecr delete-repository \
  --repository-name $ECR_REPO_NAME \
  --force || echo "Failed to delete ECR repository, continuing..."

# Step 6: Delete Secrets Manager secret
echo "Deleting Secrets Manager secret..."
aws secretsmanager delete-secret \
  --secret-id $SECRET_ARN \
  --force-delete-without-recovery || echo "Failed to delete secret, continuing..."

# Step 7: Delete ACM certificate
echo "Deleting ACM certificate..."
aws acm delete-certificate \
  --certificate-arn $CERTIFICATE_ARN || echo "Failed to delete certificate, continuing..."

# Step 8: Delete RDS instance
echo "Deleting RDS instance..."
aws rds delete-db-instance \
  --db-instance-identifier $RDS_INSTANCE_ID \
  --skip-final-snapshot || echo "Failed to delete RDS instance, continuing..."

echo "Waiting for RDS instance to be deleted..."
aws rds wait db-instance-deleted \
  --db-instance-identifier $RDS_INSTANCE_ID || echo "Failed to wait for RDS instance deletion, continuing..."

echo "Deleting DB subnet group..."
aws rds delete-db-subnet-group \
  --db-subnet-group-name ${APP_NAME}-db-subnet-group || echo "Failed to delete DB subnet group, continuing..."

# Step 9: Delete VPC resources
echo "Deleting security groups..."
aws ec2 delete-security-group \
  --group-id $ALB_SG_ID || echo "Failed to delete ALB security group, continuing..."

aws ec2 delete-security-group \
  --group-id $ECS_SG_ID || echo "Failed to delete ECS security group, continuing..."

aws ec2 delete-security-group \
  --group-id $RDS_SG_ID || echo "Failed to delete RDS security group, continuing..."

echo "Deleting route tables..."
aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables --route-table-ids $PUBLIC_RTB_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text) || echo "Failed to disassociate public route table 1, continuing..."

aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables --route-table-ids $PUBLIC_RTB_ID --query 'RouteTables[0].Associations[1].RouteTableAssociationId' --output text) || echo "Failed to disassociate public route table 2, continuing..."

aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables --route-table-ids $PRIVATE_RTB_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text) || echo "Failed to disassociate private route table 1, continuing..."

aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables --route-table-ids $PRIVATE_RTB_ID --query 'RouteTables[0].Associations[1].RouteTableAssociationId' --output text) || echo "Failed to disassociate private route table 2, continuing..."

aws ec2 delete-route \
  --route-table-id $PUBLIC_RTB_ID \
  --destination-cidr-block 0.0.0.0/0 || echo "Failed to delete public route, continuing..."

aws ec2 delete-route-table \
  --route-table-id $PUBLIC_RTB_ID || echo "Failed to delete public route table, continuing..."

aws ec2 delete-route-table \
  --route-table-id $PRIVATE_RTB_ID || echo "Failed to delete private route table, continuing..."

echo "Detaching and deleting Internet Gateway..."
aws ec2 detach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID || echo "Failed to detach Internet Gateway, continuing..."

aws ec2 delete-internet-gateway \
  --internet-gateway-id $IGW_ID || echo "Failed to delete Internet Gateway, continuing..."

echo "Deleting subnets..."
aws ec2 delete-subnet \
  --subnet-id $PUBLIC_SUBNET_1_ID || echo "Failed to delete public subnet 1, continuing..."

aws ec2 delete-subnet \
  --subnet-id $PUBLIC_SUBNET_2_ID || echo "Failed to delete public subnet 2, continuing..."

aws ec2 delete-subnet \
  --subnet-id $PRIVATE_SUBNET_1_ID || echo "Failed to delete private subnet 1, continuing..."

aws ec2 delete-subnet \
  --subnet-id $PRIVATE_SUBNET_2_ID || echo "Failed to delete private subnet 2, continuing..."

echo "Deleting VPC..."
aws ec2 delete-vpc \
  --vpc-id $VPC_ID || echo "Failed to delete VPC, continuing..."

# Step 10: Delete Route 53 hosted zone
echo "Deleting Route 53 hosted zone..."
aws route53 delete-hosted-zone \
  --id $ROUTE53_ZONE_ID || echo "Failed to delete Route 53 hosted zone, continuing..."

echo "Cleanup completed!" 