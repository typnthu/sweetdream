variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}
