# Blue-Green Deployment with AWS CodeDeploy for ECS
# This module sets up CodeDeploy for blue-green deployments

# CodeDeploy Application
resource "aws_codedeploy_app" "ecs_app" {
  compute_platform = "ECS"
  name             = "${var.project_name}-codedeploy-app"

  tags = var.tags
}

# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.project_name}-codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for CodeDeploy ECS
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_service_role.name
}

# Additional policy for CodeDeploy to manage ECS and ALB
resource "aws_iam_role_policy" "codedeploy_additional_policy" {
  name = "${var.project_name}-codedeploy-additional-policy"
  role = aws_iam_role.codedeploy_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:DescribeServices",
          "ecs:UpdateServicePrimaryTaskSet",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms",
          "sns:Publish",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeDeploy Deployment Group for each service
resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
  for_each               = var.ecs_services
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${each.key}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = var.deployment_config_name

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = each.value.service_name
  }

  dynamic "load_balancer_info" {
    for_each = each.value.target_group_name != "" ? [1] : []
    content {
      target_group_info {
        name = each.value.target_group_name
      }
    }
  }

  # Optional: Add alarm configuration for automatic rollback
  dynamic "alarm_configuration" {
    for_each = var.enable_alarm_rollback ? [1] : []
    content {
      enabled = true
      alarms  = var.rollback_alarms
    }
  }

  tags = var.tags
}

# S3 Bucket for CodeDeploy artifacts (optional)
resource "aws_s3_bucket" "codedeploy_artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = "${var.project_name}-codedeploy-artifacts-${random_id.bucket_suffix[0].hex}"

  tags = var.tags
}

resource "random_id" "bucket_suffix" {
  count       = var.create_artifacts_bucket ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "codedeploy_artifacts_versioning" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.codedeploy_artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codedeploy_artifacts_encryption" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.codedeploy_artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for CodeDeploy
resource "aws_cloudwatch_log_group" "codedeploy_logs" {
  name              = "/aws/codedeploy/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# SNS Topic for deployment notifications (optional)
resource "aws_sns_topic" "deployment_notifications" {
  count = var.enable_notifications ? 1 : 0
  name  = "${var.project_name}-deployment-notifications"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "deployment_email" {
  count     = var.enable_notifications && var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.deployment_notifications[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}