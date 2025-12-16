variable "vpc_id" {
  description = "ID of the VPC where ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID used by ECS Tasks"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (if null, HTTPS listener will not be created)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
  default     = "production"
}

variable "traffic_weights" {
  description = "Weight distribution for Blue/Green deployment across all services"

  type = object({
    frontend = object({
      blue  = number
      green = number
    })
    user_service = object({
      blue  = number
      green = number
    })
    order_service = object({
      blue  = number
      green = number
    })
  })

  default = {
    frontend = {
      blue  = 100
      green = 0
    }
    user_service = {
      blue  = 100
      green = 0
    }
    order_service = {
      blue  = 100
      green = 0
    }
  }

  # ✅ Validation 1: mỗi weight từ 0–100
  validation {
    condition = (
      var.traffic_weights.frontend.blue  >= 0 && var.traffic_weights.frontend.blue  <= 100 &&
      var.traffic_weights.frontend.green >= 0 && var.traffic_weights.frontend.green <= 100 &&
      var.traffic_weights.user_service.blue  >= 0 && var.traffic_weights.user_service.blue  <= 100 &&
      var.traffic_weights.user_service.green >= 0 && var.traffic_weights.user_service.green <= 100 &&
      var.traffic_weights.order_service.blue  >= 0 && var.traffic_weights.order_service.blue  <= 100 &&
      var.traffic_weights.order_service.green >= 0 && var.traffic_weights.order_service.green <= 100
    )
    error_message = "All blue/green weights must be between 0 and 100."
  }

  # ✅ Validation 2: blue + green = 100
  validation {
    condition = (
      var.traffic_weights.frontend.blue  + var.traffic_weights.frontend.green  == 100 &&
      var.traffic_weights.user_service.blue  + var.traffic_weights.user_service.green  == 100 &&
      var.traffic_weights.order_service.blue  + var.traffic_weights.order_service.green == 100
    )
    error_message = "Blue + Green weight must equal 100 for each service."
  }
}
