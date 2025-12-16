output "ecs_execution_role_arn" {
  description = "ARN of ECS execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "codedeploy_ecs_role_arn" {
  description = "ARN of CodeDeploy ECS role"
  value       = aws_iam_role.codedeploy_ecs.arn
}
