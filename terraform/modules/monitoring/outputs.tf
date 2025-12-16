output "sns_topic_arn" {
  description = "ARN of SNS topic for deployment alerts"
  value       = aws_sns_topic.deployment_alerts.arn
}

output "dashboard_url" {
  description = "URL of CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.blue_green_dashboard.dashboard_name}"
}