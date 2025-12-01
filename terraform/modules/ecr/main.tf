# ECR Repositories for Docker Images
# Use data sources for existing repositories

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

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = data.aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = data.aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "user_service" {
  repository = data.aws_ecr_repository.user_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "order_service" {
  repository = data.aws_ecr_repository.order_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
