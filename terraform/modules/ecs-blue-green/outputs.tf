# ECS Blue-Green Module Outputs

# Blue Service Outputs
output "blue_service_name" {
  description = "Name of the blue ECS service"
  value       = aws_ecs_service.blue.name
}

output "blue_service_arn" {
  description = "ARN of the blue ECS service"
  value       = aws_ecs_service.blue.id
}

output "blue_task_definition_arn" {
  description = "ARN of the blue task definition"
  value       = aws_ecs_task_definition.blue.arn
}

output "blue_log_group_name" {
  description = "Name of the blue CloudWatch log group"
  value       = aws_cloudwatch_log_group.blue.name
}

# Green Service Outputs
output "green_service_name" {
  description = "Name of the green ECS service"
  value       = aws_ecs_service.green.name
}

output "green_service_arn" {
  description = "ARN of the green ECS service"
  value       = aws_ecs_service.green.id
}

output "green_task_definition_arn" {
  description = "ARN of the green task definition"
  value       = aws_ecs_task_definition.green.arn
}

output "green_log_group_name" {
  description = "Name of the green CloudWatch log group"
  value       = aws_cloudwatch_log_group.green.name
}

# Combined Outputs
output "service_names" {
  description = "Map of blue and green service names"
  value = {
    blue  = aws_ecs_service.blue.name
    green = aws_ecs_service.green.name
  }
}

output "log_group_names" {
  description = "Map of blue and green log group names"
  value = {
    blue  = aws_cloudwatch_log_group.blue.name
    green = aws_cloudwatch_log_group.green.name
  }
}

# Deployment Status
output "deployment_status" {
  description = "Current deployment status"
  value = {
    blue_desired_count  = var.blue_desired_count
    green_desired_count = var.green_desired_count
    active_deployment   = var.blue_desired_count > 0 ? (var.green_desired_count > 0 ? "both" : "blue") : "green"
  }
}