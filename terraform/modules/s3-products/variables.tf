variable "bucket_name" {
  description = "Name of the S3 bucket for product images"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
