# CloudWatch Monitoring for Blue-Green Deployment

# SNS Topic for Alerts
resource "aws_sns_topic" "deployment_alerts" {
  name = "sweetdream-deployment-alerts"

  tags = {
    Name        = "SweetDream Deployment Alerts"
    Environment = var.environment
  }
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.deployment_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarms for Blue Environment
resource "aws_cloudwatch_metric_alarm" "blue_high_error_rate" {
  alarm_name          = "sweetdream-blue-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors blue environment error rate"
  alarm_actions       = [aws_sns_topic.deployment_alerts.arn]

  dimensions = {
    TargetGroup = var.blue_target_group_arn
  }

  tags = {
    Name        = "Blue Environment Error Rate"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "green_high_error_rate" {
  alarm_name          = "sweetdream-green-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors green environment error rate"
  alarm_actions       = [aws_sns_topic.deployment_alerts.arn]

  dimensions = {
    TargetGroup = var.green_target_group_arn
  }

  tags = {
    Name        = "Green Environment Error Rate"
    Environment = var.environment
  }
}

# CloudWatch Alarms for Response Time
resource "aws_cloudwatch_metric_alarm" "blue_high_response_time" {
  alarm_name          = "sweetdream-blue-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors blue environment response time"
  alarm_actions       = [aws_sns_topic.deployment_alerts.arn]

  dimensions = {
    TargetGroup = var.blue_target_group_arn
  }

  tags = {
    Name        = "Blue Environment Response Time"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "green_high_response_time" {
  alarm_name          = "sweetdream-green-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors green environment response time"
  alarm_actions       = [aws_sns_topic.deployment_alerts.arn]

  dimensions = {
    TargetGroup = var.green_target_group_arn
  }

  tags = {
    Name        = "Green Environment Response Time"
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "blue_green_dashboard" {
  dashboard_name = "SweetDream-BlueGreen-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", var.blue_target_group_arn],
            [".", ".", ".", var.green_target_group_arn]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Request Count - Blue vs Green"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", var.blue_target_group_arn],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", var.green_target_group_arn],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "HTTP Response Codes - Blue vs Green"
          period  = 300
        }
      }
    ]
  })
}