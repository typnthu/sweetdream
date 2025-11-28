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
  value       = aws_ecs_cluster.main.name
}

output "ecs_backend_service_name" {
  description = "ECS backend service name"
  value       = module.ecs_backend.service_name
}

output "ecs_frontend_service_name" {
  description = "ECS frontend service name"
  value       = module.ecs_frontend.service_name
}

# CloudWatch Analytics Outputs
output "analytics_queries" {
  description = "Customer analytics query names (if enabled)"
  value = var.enable_customer_analytics ? {
    backend  = module.ecs_backend.analytics_queries
    frontend = module.ecs_frontend.analytics_queries
  } : null
}

output "log_groups" {
  description = "CloudWatch log group names"
  value = {
    backend  = module.ecs_backend.log_group_name
    frontend = module.ecs_frontend.log_group_name
  }
}

# S3 Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for logs"
  value       = module.s3.bucket_name
}


# ECR Image URIs (Dynamically Retrieved)
output "ecr_backend_image" {
  description = "Backend Docker image URI"
  value       = local.backend_image
}

output "ecr_frontend_image" {
  description = "Frontend Docker image URI"
  value       = local.frontend_image
}

output "ecr_user_service_image" {
  description = "User Service Docker image URI"
  value       = local.user_service_image
}

output "ecr_order_service_image" {
  description = "Order Service Docker image URI"
  value       = local.order_service_image
}

# CloudWatch Simple Setup Outputs (no longer using full monitoring)
# Queries are managed by the cloudwatch-logs module within each ECS service

# Customer Analytics S3 Buckets
output "analytics_s3_buckets" {
  description = "S3 buckets for customer analytics data export"
  value = var.enable_customer_analytics ? {
    backend = try(module.backend_analytics[0].s3_bucket_name, null)
    order   = try(module.order_analytics[0].s3_bucket_name, null)
  } : null
}

# Customer Analytics Lambda Functions
output "analytics_lambda_functions" {
  description = "Lambda functions for scheduled log export to S3"
  value = var.enable_customer_analytics ? {
    backend = try(module.backend_analytics[0].lambda_function_name, null)
    order   = try(module.order_analytics[0].lambda_function_name, null)
  } : null
}

# Customer Analytics Queries
output "analytics_query_names" {
  description = "CloudWatch Insights query names for customer analytics"
  value = var.enable_customer_analytics ? {
    backend = try(module.backend_analytics[0].analytics_queries, [])
    order   = try(module.order_analytics[0].analytics_queries, [])
  } : null
}

# Bastion Host
output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = var.enable_bastion ? module.bastion[0].instance_id : null
}

output "bastion_public_ip" {
  description = "Bastion host public IP address"
  value       = var.enable_bastion ? module.bastion[0].instance_public_ip : null
}

output "bastion_connect_command" {
  description = "Command to connect to bastion via SSM Session Manager"
  value       = var.enable_bastion ? module.bastion[0].connect_command : null
}

output "bastion_db_info" {
  description = "Database connection information from bastion"
  value       = var.enable_bastion ? module.bastion[0].db_connection_info : null
  sensitive   = true
}
