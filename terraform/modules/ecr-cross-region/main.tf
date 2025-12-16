# Cross-Region ECR Replication
# This module sets up ECR replication between regions

# ECR Replication Configuration
resource "aws_ecr_replication_configuration" "cross_region" {
  count = var.enable_cross_region_replication ? 1 : 0
  
  replication_configuration {
    rule {
      destination {
        region      = var.destination_region
        registry_id = var.destination_account_id
      }
      
      # Repository filter (optional)
      dynamic "repository_filter" {
        for_each = length(var.repository_filters) > 0 ? var.repository_filters : []
        content {
          filter      = repository_filter.value.filter
          filter_type = repository_filter.value.filter_type
        }
      }
    }
  }
}

# Cross-region ECR access policy
resource "aws_ecr_repository_policy" "cross_region_policy" {
  for_each   = var.enable_cross_region_access ? var.ecr_repositories : {}
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossRegionPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.destination_account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.destination_region
          }
        }
      }
    ]
  })
}

# SSM Parameter to store cross-region ECR info
resource "aws_ssm_parameter" "cross_region_ecr_info" {
  count = var.enable_cross_region_replication ? 1 : 0
  name  = "/${var.project_name}/ecr/cross-region-info"
  type  = "String"
  
  value = jsonencode({
    source_region      = var.source_region
    destination_region = var.destination_region
    account_id         = var.destination_account_id
    repositories       = keys(var.ecr_repositories)
  })

  tags = var.tags
}