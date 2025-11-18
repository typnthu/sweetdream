# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the application (Frontend only - Backend is internal)"
  value       = "http://${module.alb.alb_dns_name}"
}

# Service Discovery Outputs
output "backend_internal_dns" {
  description = "Internal DNS name for backend service (accessible only within VPC)"
  value       = module.service_discovery.backend_dns_name
}

# RDS Outputs
output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_backend.cluster_name
}

output "ecs_backend_service_name" {
  description = "ECS backend service name"
  value       = module.ecs_backend.service_name
}

output "ecs_frontend_service_name" {
  description = "ECS frontend service name"
  value       = module.ecs_frontend.service_name
}

# S3 Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for logs"
  value       = module.s3.bucket_name
}

output "s3_products_bucket_name" {
  description = "S3 bucket name for product images"
  value       = module.s3_products.bucket_name
}

output "s3_products_bucket_url" {
  description = "URL for S3 products bucket"
  value       = "https://${module.s3_products.bucket_regional_domain_name}"
}
