# Development Environment Variables

variable "aws_region" {
  description = "AWS region for development environment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "sweetdream-dev-cluster"
}

variable "task_name" {
  description = "ECS task definition name"
  type        = string
  default     = "sweetdream-dev-task"
}

variable "service_name" {
  description = "ECS service name"
  type        = string
  default     = "sweetdream-dev-service"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "sweetdream"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for logs and user data"
  type        = string
  default     = "sweetdream-logs-data-dev"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "dev-alerts@sweetdream.com"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 3
}

variable "enable_bastion" {
  description = "Enable bastion host for RDS access"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = null
}