provider "aws" {
  region = var.aws_region
  
  # Add retry logic for API calls
  retry_mode = "standard"
  
  # Increase the max_retries (default is 3)
  max_retries = 10
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# RDS Module
module "rds" {
  source = "../../modules/rds"
  
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
  
  depends_on = [module.vpc]
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"
  
  environment = var.environment
  app_name    = var.app_name
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"
  
  environment         = var.environment
  app_name            = var.app_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  ecr_repository_url  = module.ecr.repository_url
  container_port      = var.container_port
  database_url        = "mysql://${var.db_username}:${var.db_password}@${module.rds.db_endpoint}/${var.db_name}"
  jwt_secret          = var.jwt_secret
  google_client_id    = var.google_client_id
  google_client_secret = var.google_client_secret
  domain_name         = var.domain_name
  instance_type       = var.instance_type
  
  depends_on = [module.vpc, module.rds, module.ecr]
}

# Route53 and ACM Module
module "dns" {
  source = "../../modules/dns"
  
  domain_name = var.domain_name
  environment = var.environment
  app_name    = var.app_name
  alb_dns_name = module.ecs.alb_dns_name
  alb_zone_id  = module.ecs.alb_zone_id
  certificate_arn = module.ecs.certificate_arn
  certificate_validation_options = module.ecs.certificate_validation_options
  
  depends_on = [module.ecs]
} 