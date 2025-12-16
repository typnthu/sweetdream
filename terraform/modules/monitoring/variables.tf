variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "blue_target_group_arn" {
  description = "ARN of blue target group"
  type        = string
}

variable "green_target_group_arn" {
  description = "ARN of green target group"
  type        = string
}