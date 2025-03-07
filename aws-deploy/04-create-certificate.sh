#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

echo "Creating Route 53 hosted zone for domain: $DOMAIN_NAME"

# Create Route 53 hosted zone
ROUTE53_ZONE_ID=$(aws route53 create-hosted-zone \
  --name $DOMAIN_NAME \
  --caller-reference "$(date +%s)" \
  --hosted-zone-config Comment="Hosted zone for $DOMAIN_NAME" \
  --query 'HostedZone.Id' \
  --output text)

# Extract just the zone ID without the /hostedzone/ prefix
ROUTE53_ZONE_ID=${ROUTE53_ZONE_ID#/hostedzone/}

echo "Route 53 hosted zone created: $ROUTE53_ZONE_ID"
echo "ROUTE53_ZONE_ID=$ROUTE53_ZONE_ID" >> aws-deploy/outputs/route53-outputs.txt

# Update env-vars.sh with the new Route 53 zone ID
sed -i "s/export ROUTE53_ZONE_ID=.*/export ROUTE53_ZONE_ID=$ROUTE53_ZONE_ID/" aws-deploy/env-vars.sh

echo "Route 53 zone ID updated in env-vars.sh"
echo "IMPORTANT: You need to update your domain's nameservers at your domain registrar."
echo "Retrieving nameservers..."

# Get nameservers for the hosted zone
NAMESERVERS=$(aws route53 get-hosted-zone \
  --id $ROUTE53_ZONE_ID \
  --query 'DelegationSet.NameServers' \
  --output text)

echo "Please update your domain's nameservers at your domain registrar to:"
echo "$NAMESERVERS"
echo "Wait for DNS propagation before proceeding (this can take up to 48 hours)."
echo "Press Enter to continue with certificate creation..."
read -p ""

echo "Creating SSL certificate for domain: $DOMAIN_NAME"

# Request a certificate
CERTIFICATE_ARN=$(aws acm request-certificate \
  --domain-name $DOMAIN_NAME \
  --validation-method DNS \
  --subject-alternative-names "www.${DOMAIN_NAME}" \
  --query 'CertificateArn' \
  --output text)

echo "Certificate requested: $CERTIFICATE_ARN"
echo "CERTIFICATE_ARN=$CERTIFICATE_ARN" >> aws-deploy/outputs/cert-outputs.txt

# Get the DNS validation records
sleep 5  # Wait a bit for the certificate to be created
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

echo "Creating DNS validation records in Route 53..."

# Create DNS validation record for the apex domain
aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
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
  }'

# Create DNS validation record for the www subdomain
aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
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
  }'

echo "DNS validation records created"
echo "Waiting for certificate validation (this may take up to 30 minutes)..."

# Wait for certificate validation
aws acm wait certificate-validated \
  --certificate-arn $CERTIFICATE_ARN

echo "Certificate validated successfully!" 