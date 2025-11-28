# Variables for CloudWatch Analytics Module

variable "service_name" {
  description = "Name of the service (e.g., backend, frontend)"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name to export from"
  type        = string
}

variable "analytics_bucket_name" {
  description = "S3 bucket name for analytics data export"
  type        = string
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern (empty = all logs, or filter for specific patterns)"
  type        = string
  default     = ""
}

variable "export_schedule" {
  description = "Schedule expression for daily export (cron or rate)"
  type        = string
  default     = "cron(0 17 * * ? *)" # Daily at 0:00 AM Vietnam time (17:00 UTC)
}

variable "export_format" {
  description = "Export format for user action logs (json or csv)"
  type        = string
  default     = "json"
  validation {
    condition     = contains(["json", "csv"], var.export_format)
    error_message = "Export format must be either 'json' or 'csv'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_lambda_export" {
  description = "Enable Lambda function for automated log export to S3"
  type        = bool
  default     = false
}
