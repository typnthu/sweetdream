output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs_app.name
}

output "codedeploy_app_id" {
  description = "ID of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs_app.id
}

output "deployment_groups" {
  description = "Map of deployment group names"
  value = {
    for k, v in aws_codedeploy_deployment_group.ecs_deployment_group : k => v.deployment_group_name
  }
}

output "service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for CodeDeploy artifacts"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.codedeploy_artifacts[0].bucket : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.codedeploy_logs.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = var.enable_notifications ? aws_sns_topic.deployment_notifications[0].arn : null
}