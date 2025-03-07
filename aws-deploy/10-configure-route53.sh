#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

# Load ALB outputs
source aws-deploy/outputs/alb-outputs.txt

echo "Configuring Route 53 DNS records..."

# Create A record for apex domain pointing to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
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
  }'

echo "A record created for apex domain: $DOMAIN_NAME"

# Create A record for www subdomain pointing to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
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
  }'

echo "A record created for www subdomain: www.$DOMAIN_NAME"

echo "Route 53 DNS records configured successfully!" 