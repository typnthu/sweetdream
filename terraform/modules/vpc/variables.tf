variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
  default     = ""
}
