#main.tf

# ===== ECR Repositories (must be created first) =====
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
}

module "vpc" {
  source     = "./modules/vpc"
  vpc_cidr   = var.vpc_cidr
  aws_region = var.aws_region
}

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
}

module "service_discovery" {
  source         = "./modules/service-discovery"
  namespace_name = "sweetdream.local"
  vpc_id         = module.vpc.vpc_id
}

module "alb" {
  source                = "./modules/alb"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id
}

module "secrets_manager" {
  source      = "./modules/secrets-manager"
  app_name    = "sweetdream"
  secret_name = "sweetdream-db-secret"
  db_username = var.db_username
  db_password = var.db_password
}

module "rds" {
  source                = "./modules/rds"
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.rds_security_group_id
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
  source = "./modules/ecs"

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

  # CloudWatch Logs & Analytics
  environment              = var.environment
  log_retention_days       = var.log_retention_days
  enable_analytics_queries = var.enable_customer_analytics
}

# ===== Backend Analytics (Export to S3) =====
module "backend_analytics" {
  count  = var.enable_customer_analytics ? 1 : 0
  source = "./modules/cloudwatch-analytics"

  service_name          = "${var.service_name}-backend"
  log_group_name        = "/ecs/sweetdream-${var.service_name}-backend"
  analytics_bucket_name = "${var.analytics_bucket_prefix}-backend-${var.environment}"
  export_format         = "json" # json or csv
  enable_lambda_export  = true   # Enable Lambda for automated exports

  # Filter only user action logs (optional - remove to export all logs)
  filter_pattern = ""

  tags = {
    Environment = var.environment
    Service     = "backend"
    Purpose     = "Customer Analytics"
  }
}

# ===== User Service (Customers & Authentication) =====
module "ecs_user_service" {
  source = "./modules/ecs"

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
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (not exposed via ALB, uses service discovery)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.user_service_arn

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket (not used by user service)
  s3_bucket = ""
}

# ===== Order Service (Order Processing) =====
module "ecs_order_service" {
  source = "./modules/ecs"

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
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (not exposed via ALB, uses service discovery)
  enable_load_balancer = false

  # Service Discovery (for internal communication)
  enable_service_discovery = true
  service_discovery_arn    = module.service_discovery.order_service_arn

  # Database Configuration
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # S3 Bucket (not used by order service)
  s3_bucket = ""

  # Service-to-Service Communication
  user_service_url = "http://${module.service_discovery.user_service_dns_name}:3003"
}

# ===== Frontend Service (Next.js Application) =====
module "ecs_frontend" {
  source = "./modules/ecs"

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

  # Scaling Configuration (Frontend needs more resources)
  desired_count = 2
  min_capacity  = 1
  max_capacity  = 6
  task_cpu      = 512
  task_memory   = 1024

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.ecs_security_group_id

  # IAM Roles
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  # Load Balancer (Frontend is exposed via ALB)
  enable_load_balancer = true
  target_group_arn     = module.alb.frontend_target_group_arn


  # Service Discovery (Frontend doesn't need it, uses ALB)
  enable_service_discovery = false

  # Database Configuration (Frontend doesn't need DB)
  db_host     = ""
  db_name     = ""
  db_username = ""
  db_password = ""

  # S3 Bucket (not used by frontend)
  s3_bucket = ""

  # Service-to-Service Communication URLs
  backend_url       = "http://${module.service_discovery.backend_dns_name}:3001"
  user_service_url  = "http://${module.service_discovery.user_service_dns_name}:3003"
  order_service_url = "http://${module.service_discovery.order_service_dns_name}:3002"

  # CloudWatch Logs & Analytics
  environment              = var.environment
  log_retention_days       = var.log_retention_days
  enable_analytics_queries = var.enable_customer_analytics
}

# ===== Order Service Analytics (Export to S3) =====
module "order_analytics" {
  count  = var.enable_customer_analytics ? 1 : 0
  source = "./modules/cloudwatch-analytics"

  service_name          = "${var.service_name}-order-service"
  log_group_name        = "/ecs/sweetdream-${var.service_name}-order-service"
  analytics_bucket_name = "${var.analytics_bucket_prefix}-order-${var.environment}"
  export_format         = "json" # json or csv
  enable_lambda_export  = true   # Enable Lambda for automated exports

  # Filter only user action logs (optional)
  filter_pattern = ""

  tags = {
    Environment = var.environment
    Service     = "order-service"
    Purpose     = "Customer Analytics"
  }
}

# ===== Bastion Host (Temporary - for RDS Access) =====
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "./modules/bastion"

  name_prefix           = var.service_name
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnets[0] # Private subnet - access via SSM
  rds_security_group_id = module.vpc.rds_security_group_id
  instance_type         = "t3.micro"

  # Database connection info
  db_host     = module.rds.db_address
  db_name     = var.db_name
  db_username = var.db_username

  # Optional: Create EIP for consistent public IP
  create_eip = false # No EIP needed with SSM

  # Optional: SSH key pair (if you want SSH access)
  create_key_pair = false

  tags = {
    Environment = var.environment
    Purpose     = "Database Access"
  }
}
