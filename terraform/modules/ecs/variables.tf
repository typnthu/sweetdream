variable "cluster_id" {
  description = "ID of the existing ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (for auto-scaling resource_id)"
  type        = string
}

variable "task_name" {
  description = "ECS task definition name"
  type        = string
}

variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "container_image" {
  description = "Docker image for the application"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB target group"
  type        = string
  default     = ""
}

variable "enable_load_balancer" {
  description = "Whether to attach service to load balancer"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_arn" {
  description = "ARN of service discovery service"
  type        = string
  default     = ""
}

variable "backend_url" {
  description = "Backend URL for frontend to connect"
  type        = string
  default     = ""
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket name for logs"
  type        = string
  default     = ""
}

variable "user_service_url" {
  description = "User Service URL for service-to-service communication"
  type        = string
  default     = ""
}

variable "order_service_url" {
  description = "Order Service URL for service-to-service communication"
  type        = string
  default     = ""
}

# Scaling Configuration
variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 4
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, 4096, 8192)"
  type        = number
  default     = 512
}

# CloudWatch Logs Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "enable_analytics_queries" {
  description = "Enable pre-built customer analytics queries"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}
