# Development Environment - US-West-2
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "sweetdream-terraform-state-dev"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
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

# Use existing VPC instead of creating new one
data "aws_vpc" "existing" {
  id = "vpc-036b4659e08935b92"
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

data "aws_security_group" "existing_ecs" {
  id = "sg-0efe98ed68d343ac0"
}

module "iam" {
  source = "../../modules/iam"
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.s3_bucket_name
}

module "service_discovery" {
  source         = "../../modules/service-discovery"
  namespace_name = "sweetdream.local"
  vpc_id         = data.aws_vpc.existing.id
}

module "alb" {
  source                = "../../modules/alb"
  vpc_id                = data.aws_vpc.existing.id
  public_subnet_ids     = data.aws_subnets.public.ids
  ecs_security_group_id = data.aws_security_group.existing_ecs.id
  acm_certificate_arn   = var.acm_certificate_arn

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

# RDS Database was deleted during migration - using hardcoded connection string

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
  min_capacity  = 1
  max_capacity  = 4
  task_cpu      = 256
  task_memory   = 512

  # Network Configuration
  private_subnet_ids    = data.aws_subnets.private.ids
  ecs_security_group_id = data.aws_security_group.existing_ecs.id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (Backend uses service discovery, not ALB)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.backend_service_arn

  # Database Configuration (using existing RDS instance)
  db_host     = "sweetdream-db.csn0cigocj2w.us-east-1.rds.amazonaws.com"
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket
  s3_bucket = module.s3.bucket_name

  # CloudWatch Logs
  environment        = var.environment
  log_retention_days = var.log_retention_days
}

# ===== User Service (Customers & Authentication) =====
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
  min_capacity  = 1
  max_capacity  = 4
  task_cpu      = 256
  task_memory   = 512

  # Network Configuration
  private_subnet_ids    = data.aws_subnets.private.ids
  ecs_security_group_id = data.aws_security_group.existing_ecs.id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (not exposed via ALB, uses service discovery)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.user_service_arn

  # Database Configuration (using existing RDS instance)
  db_host     = "sweetdream-db.csn0cigocj2w.us-east-1.rds.amazonaws.com"
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket (not used by user service)
  s3_bucket = ""
}

# ===== Order Service (Order Processing) =====
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
  min_capacity  = 1
  max_capacity  = 4
  task_cpu      = 256
  task_memory   = 512

  # Network Configuration
  private_subnet_ids    = data.aws_subnets.private.ids
  ecs_security_group_id = data.aws_security_group.existing_ecs.id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (not exposed via ALB, uses service discovery)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.order_service_arn

  # Database Configuration (using existing RDS instance)
  db_host     = "sweetdream-db.csn0cigocj2w.us-east-1.rds.amazonaws.com"
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket (not used by order service)
  s3_bucket = ""

  # Service-to-Service Communication
  user_service_url = "http://${module.service_discovery.user_service_dns_name}:3003"
}

# ===== Frontend CloudWatch Log Group =====
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/sweetdream-frontend"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "SweetDream Frontend Logs"
    Environment = var.environment
  }
}

# ===== Frontend Task Definition for CodeDeploy =====
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.task_name}-frontend"
  execution_role_arn       = module.iam.ecs_execution_role_arn
  task_role_arn            = module.iam.ecs_task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "sweetdream-frontend"
    image     = local.frontend_image
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NEXT_PUBLIC_API_URL"
        value = "/api/proxy"
      },
      {
        name  = "BACKEND_API_URL"
        value = "http://${module.service_discovery.backend_dns_name}:3001"
      },
      {
        name  = "USER_SERVICE_URL"
        value = "http://${module.service_discovery.user_service_dns_name}:3003"
      },
      {
        name  = "ORDER_SERVICE_URL"
        value = "http://${module.service_discovery.order_service_dns_name}:3002"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/sweetdream-frontend"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "SweetDream Frontend Task Definition"
  }
}

# ===== Frontend Service (CodeDeploy Blue/Green) =====
module "ecs_frontend_codedeploy" {
  source = "../../modules/ecs-codedeploy-blue-green"

  # Service Configuration
  service_name        = "${var.service_name}-frontend"
  cluster_name        = aws_ecs_cluster.main.name
  cluster_id          = aws_ecs_cluster.main.id
  task_definition_arn = aws_ecs_task_definition.frontend.arn
  container_name      = "sweetdream-frontend"
  container_port      = 3000

  # Target Groups
  target_group_blue_arn   = module.alb.frontend_blue_target_group_arn
  target_group_blue_name  = module.alb.frontend_blue_target_group_name
  target_group_green_arn  = module.alb.frontend_green_target_group_arn
  target_group_green_name = module.alb.frontend_green_target_group_name

  # ALB Listener
  alb_listener_arn = module.alb.http_listener_arn

  # CodeDeploy Role
  codedeploy_role_arn = module.iam.codedeploy_ecs_role_arn

  # Network Configuration (use existing VPC subnets to match backend services)
  private_subnet_ids    = data.aws_subnets.private.ids
  ecs_security_group_id = data.aws_security_group.existing_ecs.id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Configuration
  desired_count = 2
  task_cpu      = 512
  task_memory   = 1024
  environment   = var.environment
}

# ===== Bastion Host (for dev debugging) =====
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "../../modules/bastion"

  name_prefix           = var.service_name
  vpc_id                = data.aws_vpc.existing.id
  subnet_id             = data.aws_subnets.private.ids[0]
  rds_security_group_id = data.aws_security_group.existing_ecs.id
  instance_type         = "t3.micro"

  # Database connection info (using existing RDS instance)
  db_host     = "sweetdream-db.csn0cigocj2w.us-east-1.rds.amazonaws.com"
  db_name     = var.db_name
  db_username = var.db_username

  create_eip      = false
  create_key_pair = false

  tags = {
    Environment = var.environment
    Purpose     = "Database Access"
  }
}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # ECR image URIs (from ECR module)
  backend_image       = "${module.ecr.backend_repository_url}:dev"
  frontend_image      = "${module.ecr.frontend_repository_url}:dev"
  user_service_image  = "${module.ecr.user_service_repository_url}:dev"
  order_service_image = "${module.ecr.order_service_repository_url}:dev"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}