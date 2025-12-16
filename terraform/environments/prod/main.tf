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

# ===== User Service CloudWatch Log Group =====
resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/sweetdream-user-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "SweetDream User Service Logs"
    Environment = var.environment
  }
}

# ===== User Service Task Definition for CodeDeploy =====
resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.task_name}-user-service"
  execution_role_arn       = module.iam.ecs_execution_role_arn
  task_role_arn            = module.iam.ecs_task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "sweetdream-user-service"
    image     = local.user_service_image
    essential = true

    portMappings = [{
      containerPort = 3003
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = "3003"
      },
      {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@${module.rds.db_address}:5432/${var.db_name}"
      },
      {
        name  = "FRONTEND_URL"
        value = "https://${module.alb.alb_dns_name}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/sweetdream-user-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "SweetDream User Service Task Definition"
  }
}

# ===== User Service (CodeDeploy Blue/Green) =====
module "ecs_user_service_codedeploy" {
  source = "../../modules/ecs-codedeploy-blue-green"

  # Service Configuration
  service_name        = "${var.service_name}-user-service"
  cluster_name        = aws_ecs_cluster.main.name
  cluster_id          = aws_ecs_cluster.main.id
  task_definition_arn = aws_ecs_task_definition.user_service.arn
  container_name      = "sweetdream-user-service"
  container_port      = 3003

  # Target Groups
  target_group_blue_arn   = module.alb.user_service_blue_target_group_arn
  target_group_blue_name  = module.alb.user_service_blue_target_group_name
  target_group_green_arn  = module.alb.user_service_green_target_group_arn
  target_group_green_name = module.alb.user_service_green_target_group_name

  # ALB Listener
  alb_listener_arn = module.alb.http_listener_arn

  # CodeDeploy Role
  codedeploy_role_arn = module.iam.codedeploy_ecs_role_arn

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Configuration
  desired_count = 2
  task_cpu      = 512
  task_memory   = 1024
  environment   = var.environment

  # Ensure ALB listener rules are created first
  depends_on = [
    module.alb
  ]
}

# ===== Order Service CloudWatch Log Group =====
resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/sweetdream-order-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "SweetDream Order Service Logs"
    Environment = var.environment
  }
}

# ===== Order Service Task Definition for CodeDeploy =====
resource "aws_ecs_task_definition" "order_service" {
  family                   = "${var.task_name}-order-service"
  execution_role_arn       = module.iam.ecs_execution_role_arn
  task_role_arn            = module.iam.ecs_task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = "sweetdream-order-service"
    image     = local.order_service_image
    essential = true

    portMappings = [{
      containerPort = 3002
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = "3002"
      },
      {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@${module.rds.db_address}:5432/${var.db_name}"
      },
      {
        name  = "USER_SERVICE_URL"
        value = "http://${module.service_discovery.user_service_dns_name}:3003"
      },
      {
        name  = "FRONTEND_URL"
        value = "https://${module.alb.alb_dns_name}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/sweetdream-order-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "SweetDream Order Service Task Definition"
  }
}

# ===== Order Service (CodeDeploy Blue/Green) =====
module "ecs_order_service_codedeploy" {
  source = "../../modules/ecs-codedeploy-blue-green"

  # Service Configuration
  service_name        = "${var.service_name}-order-service"
  cluster_name        = aws_ecs_cluster.main.name
  cluster_id          = aws_ecs_cluster.main.id
  task_definition_arn = aws_ecs_task_definition.order_service.arn
  container_name      = "sweetdream-order-service"
  container_port      = 3002

  # Target Groups
  target_group_blue_arn   = module.alb.order_service_blue_target_group_arn
  target_group_blue_name  = module.alb.order_service_blue_target_group_name
  target_group_green_arn  = module.alb.order_service_green_target_group_arn
  target_group_green_name = module.alb.order_service_green_target_group_name

  # ALB Listener
  alb_listener_arn = module.alb.http_listener_arn

  # CodeDeploy Role
  codedeploy_role_arn = module.iam.codedeploy_ecs_role_arn

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Configuration
  desired_count = 2
  task_cpu      = 512
  task_memory   = 1024
  environment   = var.environment

  # Ensure ALB listener rules are created first
  depends_on = [
    module.alb
  ]
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
        value = "http://${module.alb.alb_dns_name}"
      },
      {
        name  = "ORDER_SERVICE_URL"
        value = "http://${module.alb.alb_dns_name}"
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

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Configuration
  desired_count = 2
  task_cpu      = 512
  task_memory   = 1024
  environment   = var.environment

  # Ensure ALB listener rules are created first
  depends_on = [
    module.alb
  ]
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