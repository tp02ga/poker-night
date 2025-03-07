#!/bin/bash

# Source environment variables
source aws-deploy/env-vars.sh

echo "Creating VPC infrastructure..."

# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${APP_NAME}-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC created: $VPC_ID"
echo "VPC_ID=$VPC_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Enable DNS hostnames for the VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames "{\"Value\":true}"

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${APP_NAME}-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "Internet Gateway created: $IGW_ID"
echo "IGW_ID=$IGW_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

echo "Internet Gateway attached to VPC"

# Create public subnets
PUBLIC_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_1_CIDR \
  --availability-zone ${AWS_REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${APP_NAME}-public-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)

PUBLIC_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_2_CIDR \
  --availability-zone ${AWS_REGION}b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${APP_NAME}-public-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnet 1 created: $PUBLIC_SUBNET_1_ID"
echo "Public Subnet 2 created: $PUBLIC_SUBNET_2_ID"
echo "PUBLIC_SUBNET_1_ID=$PUBLIC_SUBNET_1_ID" >> aws-deploy/outputs/vpc-outputs.txt
echo "PUBLIC_SUBNET_2_ID=$PUBLIC_SUBNET_2_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_2_ID \
  --map-public-ip-on-launch

# Create private subnets
PRIVATE_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_1_CIDR \
  --availability-zone ${AWS_REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${APP_NAME}-private-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_2_CIDR \
  --availability-zone ${AWS_REGION}b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${APP_NAME}-private-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Private Subnet 1 created: $PRIVATE_SUBNET_1_ID"
echo "Private Subnet 2 created: $PRIVATE_SUBNET_2_ID"
echo "PRIVATE_SUBNET_1_ID=$PRIVATE_SUBNET_1_ID" >> aws-deploy/outputs/vpc-outputs.txt
echo "PRIVATE_SUBNET_2_ID=$PRIVATE_SUBNET_2_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Create a public route table
PUBLIC_RTB_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${APP_NAME}-public-rtb}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Public Route Table created: $PUBLIC_RTB_ID"
echo "PUBLIC_RTB_ID=$PUBLIC_RTB_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Create route to Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_RTB_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate public subnets with the public route table
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RTB_ID \
  --subnet-id $PUBLIC_SUBNET_1_ID

aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RTB_ID \
  --subnet-id $PUBLIC_SUBNET_2_ID

echo "Public subnets associated with public route table"

# Create a private route table
PRIVATE_RTB_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${APP_NAME}-private-rtb}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Private Route Table created: $PRIVATE_RTB_ID"
echo "PRIVATE_RTB_ID=$PRIVATE_RTB_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Associate private subnets with the private route table
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RTB_ID \
  --subnet-id $PRIVATE_SUBNET_1_ID

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RTB_ID \
  --subnet-id $PRIVATE_SUBNET_2_ID

echo "Private subnets associated with private route table"

# Create security group for RDS
RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name ${APP_NAME}-rds-sg \
  --description "Security group for RDS instance" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

echo "RDS Security Group created: $RDS_SG_ID"
echo "RDS_SG_ID=$RDS_SG_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Allow MySQL traffic from anywhere (for demo purposes)
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 3306 \
  --cidr 0.0.0.0/0

# Create security group for ECS
ECS_SG_ID=$(aws ec2 create-security-group \
  --group-name ${APP_NAME}-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

echo "ECS Security Group created: $ECS_SG_ID"
echo "ECS_SG_ID=$ECS_SG_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Allow HTTP and HTTPS traffic
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Allow traffic on port 3000 (NextJS app)
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

# Create security group for ALB
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name ${APP_NAME}-alb-sg \
  --description "Security group for Application Load Balancer" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

echo "ALB Security Group created: $ALB_SG_ID"
echo "ALB_SG_ID=$ALB_SG_ID" >> aws-deploy/outputs/vpc-outputs.txt

# Allow HTTP and HTTPS traffic to ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Allow traffic from ALB to ECS
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 3000 \
  --source-group $ALB_SG_ID

echo "VPC infrastructure created successfully!" 