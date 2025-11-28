# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECR repositories
data "aws_ecr_repository" "backend" {
  name = "sweetdream-backend"
}

data "aws_ecr_repository" "frontend" {
  name = "sweetdream-frontend"
}

data "aws_ecr_repository" "user_service" {
  name = "sweetdream-user-service"
}

data "aws_ecr_repository" "order_service" {
  name = "sweetdream-order-service"
}

# Local values
locals {
  # AWS account info
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # ECR image URIs (dynamically retrieved)
  backend_image       = "${data.aws_ecr_repository.backend.repository_url}:latest"
  frontend_image      = "${data.aws_ecr_repository.frontend.repository_url}:latest"
  user_service_image  = "${data.aws_ecr_repository.user_service.repository_url}:latest"
  order_service_image = "${data.aws_ecr_repository.order_service.repository_url}:latest"

  # Blue/Green deployment traffic distribution
  traffic_dist_map = {
    blue = {
      blue_weight  = 100
      green_weight = 0
    }
    green = {
      blue_weight  = 0
      green_weight = 100
    }
  }

  selected_distribution = local.traffic_dist_map[var.traffic_distribution]
}
