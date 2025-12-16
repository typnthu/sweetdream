# Development Environment Outputs

output "alb_url" {
  description = "Development ALB URL"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "Development ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Development ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_repositories" {
  description = "Development ECR repository URLs"
  value       = module.ecr.all_repository_urls
}

output "vpc_id" {
  description = "Development VPC ID"
  value       = data.aws_vpc.existing.id
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = module.ecs_frontend.service_name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = module.ecs_backend.service_name
}

output "user_service_name" {
  description = "User service ECS service name"
  value       = module.ecs_user_service.service_name
}

output "order_service_name" {
  description = "Order service ECS service name"
  value       = module.ecs_order_service.service_name
}