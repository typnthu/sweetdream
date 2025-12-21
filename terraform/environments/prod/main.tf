# Production Environment - US-West-2
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "sweetdream-terraform-state-prod"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "SweetDream"
      ManagedBy   = "Terraform"
      Region      = var.aws_region
    }
  }
}

# ===== ECR Repositories (must be created first) =====
module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
}

module "vpc" {
  source     = "../../modules/vpc"
  vpc_cidr   = var.vpc_cidr
  aws_region = var.aws_region
}

module "iam" {
  source      = "../../modules/iam"
  environment = var.environment
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.s3_bucket_name
}

module "service_discovery" {
  source         = "../../modules/service-discovery"
  namespace_name = "sweetdream.local"
  vpc_id         = module.vpc.vpc_id
}

module "alb" {
  source                = "../../modules/alb"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id
  acm_certificate_arn   = var.acm_certificate_arn
  environment           = var.environment

  traffic_weights = {
    frontend = {
      blue  = 100
      green = 0
    }
    user_service = {
      blue  = 100
      green = 0
    }
    order_service = {
      blue  = 100
      green = 0
    }
  }
}

module "secrets_manager" {
  source      = "../../modules/secrets-manager"
  app_name    = "sweetdream"
  secret_name = "sweetdream-db-secret"
  db_username = var.db_username
  db_password = var.db_password
}

module "rds" {
  source                = "../../modules/rds"
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id
  rds_security_group_id = module.vpc.rds_security_group_id
}

# ===== ECS Cluster (Shared by all 4 services) =====
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ===== Backend Service (Products & Categories) =====
module "ecs_backend" {
  source = "../../modules/ecs"

  # Cluster Configuration
  cluster_id   = aws_ecs_cluster.main.id
  cluster_name = aws_ecs_cluster.main.name

  # Service Configuration
  task_name      = "${var.task_name}-backend"
  service_name   = "${var.service_name}-backend"
  container_name = "sweetdream-backend"
  container_port = 3001

  # Container Image (dynamically from ECR)
  container_image = local.backend_image

  # Scaling Configuration
  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10
  task_cpu      = 512
  task_memory   = 1024

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (Backend uses service discovery, not ALB)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.backend_service_arn

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket
  s3_bucket = module.s3.bucket_name

  # CloudWatch Logs
  environment        = var.environment
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region
}

# ===== User Service (Rolling Update) =====
module "ecs_user_service" {
  source = "../../modules/ecs"

  # Cluster Configuration
  cluster_id   = aws_ecs_cluster.main.id
  cluster_name = aws_ecs_cluster.main.name

  # Service Configuration
  task_name      = "${var.task_name}-user-service"
  service_name   = "${var.service_name}-user-service"
  container_name = "sweetdream-user-service"
  container_port = 3003

  # Container Image (dynamically from ECR)
  container_image = local.user_service_image

  # Scaling Configuration
  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10
  task_cpu      = 512
  task_memory   = 1024

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer
  enable_load_balancer = true
  target_group_arn     = module.alb.user_service_blue_target_group_arn

  # Service Discovery (disabled for ALB services)
  enable_service_discovery = false
  service_discovery_arn    = ""

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket
  s3_bucket = module.s3.bucket_name

  # CloudWatch Logs
  environment        = var.environment
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region
}

# ===== Order Service (Rolling Update) =====
module "ecs_order_service" {
  source = "../../modules/ecs"

  # Cluster Configuration
  cluster_id   = aws_ecs_cluster.main.id
  cluster_name = aws_ecs_cluster.main.name

  # Service Configuration
  task_name      = "${var.task_name}-order-service"
  service_name   = "${var.service_name}-order-service"
  container_name = "sweetdream-order-service"
  container_port = 3002

  # Container Image (dynamically from ECR)
  container_image = local.order_service_image

  # Scaling Configuration
  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10
  task_cpu      = 512
  task_memory   = 1024

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer
  enable_load_balancer = true
  target_group_arn     = module.alb.order_service_blue_target_group_arn

  # Service Discovery (disabled for ALB services)
  enable_service_discovery = false
  service_discovery_arn    = ""

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket
  s3_bucket = module.s3.bucket_name

  # CloudWatch Logs
  environment        = var.environment
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region
}

# ===== Frontend Service (Rolling Update) =====
module "ecs_frontend" {
  source = "../../modules/ecs"

  # Cluster Configuration
  cluster_id   = aws_ecs_cluster.main.id
  cluster_name = aws_ecs_cluster.main.name

  # Service Configuration
  task_name      = "${var.task_name}-frontend"
  service_name   = "${var.service_name}-frontend"
  container_name = "sweetdream-frontend"
  container_port = 3000

  # Container Image (dynamically from ECR)
  container_image = local.frontend_image

  # Scaling Configuration
  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10
  task_cpu      = 512
  task_memory   = 1024

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer
  enable_load_balancer = true
  target_group_arn     = module.alb.frontend_blue_target_group_arn

  # Service Discovery (disabled for ALB services)
  enable_service_discovery = false
  service_discovery_arn    = ""

  # Service URLs for frontend
  backend_url         = "http://${module.service_discovery.backend_dns_name}:3001"
  user_service_url    = "http://${module.alb.alb_dns_name}"
  order_service_url   = "http://${module.alb.alb_dns_name}"

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket
  s3_bucket = module.s3.bucket_name

  # CloudWatch Logs
  environment        = var.environment
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region
}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # ECR image URIs (from ECR module)
  backend_image       = "${module.ecr.backend_repository_url}:latest"
  frontend_image      = "${module.ecr.frontend_repository_url}:latest"
  user_service_image  = "${module.ecr.user_service_repository_url}:latest"
  order_service_image = "${module.ecr.order_service_repository_url}:latest"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}