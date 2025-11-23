variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "ECS cluster name"
  default     = "sweetdream-cluster"
}

variable "task_name" {
  description = "ECS task definition name"
  default     = "sweetdream-task"
}

variable "service_name" {
  description = "ECS service name"
  default     = "sweetdream-service"
}

variable "backend_image" {
  description = "Docker image for the backend application"
  default     = "nginx:latest"
}

variable "frontend_image" {
  description = "Docker image for the frontend application"
  default     = "nginx:latest"
}

variable "user_service_image" {
  description = "Docker image for the user service"
  default     = "nginx:latest"
}

variable "order_service_image" {
  description = "Docker image for the order service"
  default     = "nginx:latest"
}

variable "db_name" {
  description = "Database name"
  default     = "sweetdream"
}

variable "db_username" {
  description = "Database username"
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for logs and user data"
  default     = "sweetdream-logs-data"
}

variable "s3_products_bucket_name" {
  description = "S3 bucket name for product images"
  default     = "sweetdream-products"
}