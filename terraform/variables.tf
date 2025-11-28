variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "ECS cluster name"
  default     = "sweetdream-cluster"
}

variable "task_name" {
  description = "ECS task definition name"
  default     = "sweetdream-task"
}

variable "service_name" {
  description = "ECS service name"
  default     = "sweetdream-service"
}

variable "backend_image" {
  description = "Docker image for the backend application"
  default     = "nginx:latest"
}

variable "frontend_image" {
  description = "Docker image for the frontend application"
  default     = "nginx:latest"
}

variable "user_service_image" {
  description = "Docker image for the user service"
  default     = "nginx:latest"
}

variable "order_service_image" {
  description = "Docker image for the order service"
  default     = "nginx:latest"
}

variable "db_name" {
  description = "Database name"
  default     = "sweetdream"
}

variable "db_username" {
  description = "Database username"
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for logs and user data"
  default     = "sweetdream-logs-data"
}

# CloudWatch Monitoring
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "your-email@example.com"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_customer_analytics" {
  description = "Enable customer analytics queries in CloudWatch Insights"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "analytics_bucket_prefix" {
  description = "Prefix for analytics S3 bucket names (must be globally unique)"
  type        = string
  default     = "sweetdream-analytics"
}

# Blue/Green Deployment
variable "traffic_distribution" {
  description = "Blue/Green deployment: 'blue' (current production) or 'green' (new version)"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.traffic_distribution)
    error_message = "Must be either 'blue' or 'green' for blue/green deployment"
  }
}

variable "enable_bastion" {
  description = "Enable bastion host for RDS access"
  type        = bool
  default     = false
}
