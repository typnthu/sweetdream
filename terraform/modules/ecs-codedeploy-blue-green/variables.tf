variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "Port of the container"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN for production traffic"
  type        = string
}

variable "target_group_blue_arn" {
  description = "ARN of the blue target group (used by ECS service)"
  type        = string
}

variable "target_group_blue_name" {
  description = "NAME of the blue target group (used by CodeDeploy)"
  type        = string
}

variable "target_group_green_name" {
  description = "NAME of the green target group (used by CodeDeploy)"
  type        = string
}

variable "target_group_green_arn" {
  description = "ARN of the green target group"
  type        = string
}

variable "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy service role"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task"
  type        = number
  default     = 512
}