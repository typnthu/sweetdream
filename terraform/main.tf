#main.tf
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
}

module "s3_products" {
  source      = "./modules/s3-products"
  bucket_name = var.s3_products_bucket_name
  environment = "production"
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
  ecs_security_group_id = module.vpc.ecs_security_group_id
}

module "ecs_backend" {
  source = "./modules/ecs"

  cluster_name               = var.cluster_name
  task_name                  = "${var.task_name}-backend"
  service_name               = "${var.service_name}-backend"
  container_image            = var.backend_image
  container_name             = "sweetdream-backend"
  container_port             = 3001
  private_subnet_ids         = module.vpc.private_subnets
  ecs_security_group_id      = module.vpc.ecs_security_group_id
  execution_role_arn         = module.iam.ecs_execution_role_arn
  task_role_arn              = module.iam.ecs_task_role_arn
  target_group_arn           = ""  # Backend not exposed via ALB
  enable_load_balancer       = false
  service_discovery_arn      = module.service_discovery.backend_service_arn
  enable_service_discovery   = true

  db_host     = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  s3_bucket   = module.s3.bucket_name
}

module "ecs_frontend" {
  source = "./modules/ecs"

  cluster_name               = var.cluster_name
  task_name                  = "${var.task_name}-frontend"
  service_name               = "${var.service_name}-frontend"
  container_image            = var.frontend_image
  container_name             = "sweetdream-frontend"
  container_port             = 3000
  private_subnet_ids         = module.vpc.private_subnets
  ecs_security_group_id      = module.vpc.ecs_security_group_id
  execution_role_arn         = module.iam.ecs_execution_role_arn
  task_role_arn              = module.iam.ecs_task_role_arn
  target_group_arn           = module.alb.frontend_target_group_arn
  enable_load_balancer       = true
  enable_service_discovery   = false

  # Frontend needs to know backend URL
  backend_url = "http://${module.service_discovery.backend_dns_name}:3001"

  db_host     = ""
  db_name     = ""
  db_username = ""
  db_password = ""
  s3_bucket   = ""
}
