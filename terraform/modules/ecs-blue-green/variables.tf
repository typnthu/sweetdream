# ECS Blue-Green Module Variables

variable "cluster_id" {
  description = "ID of the existing ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (for auto-scaling resource_id)"
  type        = string
}

variable "service_base_name" {
  description = "Base name for ECS services (will append -blue/-green)"
  type        = string
}

variable "task_base_name" {
  description = "Base name for ECS task definitions (will append -blue/-green)"
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

# Blue/Green Images
variable "blue_image" {
  description = "Docker image for blue deployment"
  type        = string
}

variable "green_image" {
  description = "Docker image for green deployment"
  type        = string
  default     = ""  # Empty means same as blue
}

# Blue/Green Target Groups
variable "blue_target_group_arn" {
  description = "ARN of blue target group"
  type        = string
}

variable "green_target_group_arn" {
  description = "ARN of green target group"
  type        = string
}

# Blue/Green Desired Counts
variable "blue_desired_count" {
  description = "Desired number of blue tasks"
  type        = number
  default     = 2
}

variable "green_desired_count" {
  description = "Desired number of green tasks"
  type        = number
  default     = 0  # Start with 0 green tasks
}

# Network Configuration
variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# IAM Roles
variable "execution_role_arn" {
  description = "ARN of ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

# Environment Variables
variable "environment_variables" {
  description = "Environment variables for containers"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Scaling Configuration
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

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

# Service Discovery (optional)
variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = false
}

variable "blue_service_discovery_arn" {
  description = "ARN of blue service discovery service"
  type        = string
  default     = ""
}

variable "green_service_discovery_arn" {
  description = "ARN of green service discovery service"
  type        = string
  default     = ""
}