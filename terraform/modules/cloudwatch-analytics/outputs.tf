# Outputs for CloudWatch Analytics Module

output "s3_bucket_name" {
  description = "S3 bucket name for analytics data"
  value       = aws_s3_bucket.analytics.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.analytics.arn
}

output "lambda_function_name" {
  description = "Lambda function name for manual export (null if disabled)"
  value       = var.enable_lambda_export ? aws_lambda_function.export_logs[0].function_name : null
}

output "lambda_function_arn" {
  description = "Lambda function ARN (null if disabled)"
  value       = var.enable_lambda_export ? aws_lambda_function.export_logs[0].arn : null
}

output "analytics_queries" {
  description = "List of CloudWatch Insights query names"
  value = [
    "${var.service_name}/analytics/product-views-by-user",
    "${var.service_name}/analytics/cart-additions",
    "${var.service_name}/analytics/purchases",
    "${var.service_name}/analytics/customer-frequency",
    "${var.service_name}/analytics/best-sellers",
    "${var.service_name}/analytics/category-performance",
    "${var.service_name}/analytics/size-preferences",
    "${var.service_name}/analytics/conversion-funnel-detailed"
  ]
}
