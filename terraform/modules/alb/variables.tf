variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}


variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# Traffic Distribution Variables for Blue/Green Deployment
variable "frontend_blue_weight" {
  description = "Weight for frontend blue target group (0-100)"
  type        = number
  default     = 100
}

variable "frontend_green_weight" {
  description = "Weight for frontend green target group (0-100)"
  type        = number
  default     = 0
}

variable "user_service_blue_weight" {
  description = "Weight for user service blue target group (0-100)"
  type        = number
  default     = 100
}

variable "user_service_green_weight" {
  description = "Weight for user service green target group (0-100)"
  type        = number
  default     = 0
}

variable "order_service_blue_weight" {
  description = "Weight for order service blue target group (0-100)"
  type        = number
  default     = 100
}

variable "order_service_green_weight" {
  description = "Weight for order service green target group (0-100)"
  type        = number
  default     = 0
}
