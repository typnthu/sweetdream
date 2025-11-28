output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.cloudwatch_logs.log_group_name
}

output "analytics_queries" {
  description = "List of analytics query names"
  value       = module.cloudwatch_logs.analytics_queries
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}
