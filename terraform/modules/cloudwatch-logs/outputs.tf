output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.app.arn
}

output "analytics_queries" {
  description = "List of analytics query names"
  value = var.enable_analytics_queries ? [
    "${var.service_name}/product-views",
    "${var.service_name}/purchase-funnel",
    "${var.service_name}/search-trends",
    "${var.service_name}/customer-behavior",
    "${var.service_name}/api-performance",
    "${var.service_name}/slow-requests",
    "${var.service_name}/error-rate",
    "${var.service_name}/active-users",
    "${var.service_name}/session-duration",
    "${var.service_name}/cart-abandonment"
  ] : []
}
