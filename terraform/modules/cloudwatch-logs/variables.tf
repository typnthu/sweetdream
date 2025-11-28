variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "service_name" {
  description = "Service name for query definitions"
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}

variable "enable_analytics_queries" {
  description = "Enable pre-built customer analytics queries"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
