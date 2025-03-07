#!/bin/bash

# Script to configure AWS CLI with access key and secret key
echo "AWS CLI Configuration Script"
echo "==========================="
echo

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Prompt for AWS credentials
echo "Please enter your AWS credentials:"
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo
read -p "Default region name [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
read -p "Default output format [json]: " AWS_OUTPUT_FORMAT
AWS_OUTPUT_FORMAT=${AWS_OUTPUT_FORMAT:-json}

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region "$AWS_REGION"
aws configure set default.output "$AWS_OUTPUT_FORMAT"

# Verify configuration
echo "Verifying AWS CLI configuration..."
if aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI configured successfully!"
    echo "Account information:"
    aws sts get-caller-identity
else
    echo "Error: Failed to verify AWS credentials. Please check your access key and secret key."
    exit 1
fi

echo
echo "AWS CLI configuration completed. You can now proceed with the deployment scripts."
echo "Next step: Run ./aws-deploy/01-setup.sh" 