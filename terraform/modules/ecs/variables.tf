variable "cluster_name" {
  description = "ECS cluster name"
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
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket name for logs"
  type        = string
}
