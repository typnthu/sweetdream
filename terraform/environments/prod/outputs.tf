# Production Environment Outputs

output "alb_url" {
  description = "Production ALB URL"
  value       = var.acm_certificate_arn != null ? "https://${module.alb.alb_dns_name}" : "http://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "Production ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Production ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_repositories" {
  description = "Production ECR repository URLs"
  value       = module.ecr.all_repository_urls
}

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}

output "backend_service_name" {
  description = "Backend service name"
  value       = module.ecs_backend.service_name
}

output "frontend_service_name" {
  description = "Frontend service name"
  value       = module.ecs_frontend.service_name
}

output "user_service_name" {
  description = "User service name"
  value       = module.ecs_user_service.service_name
}

output "order_service_name" {
  description = "Order service name"
  value       = module.ecs_order_service.service_name
}
