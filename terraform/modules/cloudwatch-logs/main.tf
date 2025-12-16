# Simple CloudWatch Logs Module
# Creates log group for ECS services

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.retention_days

  lifecycle {
    prevent_destroy = false
    ignore_changes  = []
  }

  tags = merge(var.tags, {
    Name = var.log_group_name
  })
}


