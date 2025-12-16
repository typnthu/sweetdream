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

output "codedeploy_app_name" {
  description = "Production CodeDeploy application name"
  value       = module.ecs_frontend_codedeploy.codedeploy_app_name
}

output "ecr_repositories" {
  description = "Production ECR repository URLs"
  value       = module.ecr.all_repository_urls
}

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}

output "frontend_task_definition_arn" {
  description = "Frontend task definition ARN"
  value       = aws_ecs_task_definition.frontend.arn
}