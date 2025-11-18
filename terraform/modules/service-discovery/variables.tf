variable "namespace_name" {
  description = "Name of the service discovery namespace"
  type        = string
  default     = "sweetdream.local"
}

variable "vpc_id" {
  description = "VPC ID for the private DNS namespace"
  type        = string
}
