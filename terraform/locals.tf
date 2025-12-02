# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  # AWS account info
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # ECR image URIs (from ECR module)
  backend_image       = "${module.ecr.backend_repository_url}:latest"
  frontend_image      = "${module.ecr.frontend_repository_url}:latest"
  user_service_image  = "${module.ecr.user_service_repository_url}:latest"
  order_service_image = "${module.ecr.order_service_repository_url}:latest"
}
