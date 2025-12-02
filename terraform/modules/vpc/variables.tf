variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for VPC endpoints"
  type        = string
  default     = "us-east-1"
}
