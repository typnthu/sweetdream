# Bastion Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for bastion (should be private subnet with NAT)"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS security group ID to allow access from bastion"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_host" {
  description = "RDS database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "create_key_pair" {
  description = "Whether to create SSH key pair"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for bastion access"
  type        = string
  default     = ""
}

variable "create_eip" {
  description = "Whether to create Elastic IP for bastion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
