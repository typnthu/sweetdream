# CloudWatch Analytics Module - Scheduled Daily Export (Cost-Effective)
# Exports logs once per day instead of real-time to save costs

# ===== S3 Bucket for Analytics Data =====
resource "aws_s3_bucket" "analytics" {
  bucket = var.analytics_bucket_name

  # Prevent accidental deletion of analytics data
  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, {
    Name    = "Customer Analytics Data"
    Purpose = "CloudWatch Logs Export"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Lifecycle - Move to cheaper storage after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 Bucket Policy - Allow CloudWatch to write
resource "aws_s3_bucket_policy" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudWatchLogsWrite"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.analytics.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudWatchLogsAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl"
        ]
        Resource = aws_s3_bucket.analytics.arn
      }
    ]
  })
}

# ===== Lambda Function for Scheduled Export =====

# IAM Role for Lambda
resource "aws_iam_role" "export_lambda" {
  count = var.enable_lambda_export ? 1 : 0
  name  = "${var.service_name}-export-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "export_lambda" {
  count = var.enable_lambda_export ? 1 : 0
  name  = "${var.service_name}-export-lambda-policy"
  role  = aws_iam_role.export_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.analytics.arn,
          "${aws_s3_bucket.analytics.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.service_name}-export-*"
      }
    ]
  })
}

# Create zip file for user action export Lambda
data "archive_file" "user_action_lambda_zip" {
  count       = var.enable_lambda_export ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda_user_action_export.py"
  output_path = "${path.module}/lambda_user_action_export.zip"
}

# Lambda Function for user action log export
resource "aws_lambda_function" "export_logs" {
  count            = var.enable_lambda_export ? 1 : 0
  filename         = data.archive_file.user_action_lambda_zip[0].output_path
  function_name    = "${var.service_name}-export-logs"
  role             = aws_iam_role.export_lambda[0].arn
  handler          = "lambda_user_action_export.handler"
  runtime          = "python3.11"
  timeout          = 900 # 15 minutes for CloudWatch Insights queries
  memory_size      = 256 # More memory for processing
  source_code_hash = data.archive_file.user_action_lambda_zip[0].output_base64sha256

  environment {
    variables = {
      LOG_GROUP_NAME = var.log_group_name
      S3_BUCKET      = aws_s3_bucket.analytics.id
      S3_PREFIX      = "user-actions"
      EXPORT_FORMAT  = var.export_format
    }
  }

  tags = var.tags
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "export_lambda" {
  count             = var.enable_lambda_export ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.export_logs[0].function_name}"
  retention_in_days = 7

  tags = var.tags
}

# EventBridge Rule - Daily at 9:00 AM Vietnam time (2:00 AM UTC)
resource "aws_cloudwatch_event_rule" "daily_export" {
  count               = var.enable_lambda_export ? 1 : 0
  name                = "${var.service_name}-daily-export"
  description         = "Trigger daily user action log export to S3 at 9:00 AM Vietnam time"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = var.tags
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "export_lambda" {
  count     = var.enable_lambda_export ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_export[0].name
  target_id = "ExportLambda"
  arn       = aws_lambda_function.export_logs[0].arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_lambda_export ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.export_logs[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_export[0].arn
}

# ===== CloudWatch Insights Queries for Analysis =====

# 1. Product Views by User
resource "aws_cloudwatch_query_definition" "product_views_by_user" {
  name = "${var.service_name}/analytics/product-views-by-user"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, userId, productId, productName, price, category
    | filter category = "user_action" and message = "Product Viewed"
    | parse @message /userId["\s:]+(?<userId>\d+)/
    | parse @message /productId["\s:]+(?<productId>\d+)/
    | parse @message /productName["\s:]+(?<productName>[^"]+)/
    | parse @message /price["\s:]+(?<price>[\d.]+)/
    | parse @message /category["\s:]+(?<productCategory>[^"]+)/
    | stats count() as views by userId, productId, productName, price, productCategory
    | sort views desc
  QUERY
}

# 2. Products Added to Cart
resource "aws_cloudwatch_query_definition" "cart_additions" {
  name = "${var.service_name}/analytics/cart-additions"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, userId, productId, productName, size, quantity, price
    | filter category = "user_action" and message = "Add to Cart"
    | parse @message /userId["\s:]+(?<userId>\d+)/
    | parse @message /productId["\s:]+(?<productId>\d+)/
    | parse @message /productName["\s:]+(?<productName>[^"]+)/
    | parse @message /size["\s:]+(?<size>[^"]+)/
    | parse @message /quantity["\s:]+(?<quantity>\d+)/
    | parse @message /price["\s:]+(?<price>[\d.]+)/
    | stats sum(quantity) as total_quantity, count() as add_count by productId, productName, size, price
    | sort total_quantity desc
  QUERY
}

# 3. Products Purchased
resource "aws_cloudwatch_query_definition" "purchases" {
  name = "${var.service_name}/analytics/purchases"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, userId, orderId, productId, productName, size, quantity, price, totalAmount
    | filter category = "user_action" and message = "Order Completed"
    | parse @message /userId["\s:]+(?<userId>\d+)/
    | parse @message /orderId["\s:]+(?<orderId>\d+)/
    | parse @message /productId["\s:]+(?<productId>\d+)/
    | parse @message /productName["\s:]+(?<productName>[^"]+)/
    | parse @message /size["\s:]+(?<size>[^"]+)/
    | parse @message /quantity["\s:]+(?<quantity>\d+)/
    | parse @message /price["\s:]+(?<price>[\d.]+)/
    | parse @message /totalAmount["\s:]+(?<totalAmount>[\d.]+)/
    | stats sum(quantity) as units_sold, sum(totalAmount) as revenue by productId, productName, size, price
    | sort revenue desc
  QUERY
}

# 4. Customer Purchase Frequency
resource "aws_cloudwatch_query_definition" "customer_frequency" {
  name = "${var.service_name}/analytics/customer-frequency"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, userId, userName, totalAmount
    | filter category = "user_action" and message = "Order Completed"
    | parse @message /userId["\s:]+(?<userId>\d+)/
    | parse @message /userName["\s:]+(?<userName>[^"]+)/
    | parse @message /totalAmount["\s:]+(?<totalAmount>[\d.]+)/
    | stats count() as order_count, sum(totalAmount) as total_spent, avg(totalAmount) as avg_order_value by userId, userName
    | sort order_count desc
  QUERY
}

# 5. Best Selling Products
resource "aws_cloudwatch_query_definition" "best_sellers" {
  name = "${var.service_name}/analytics/best-sellers"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, productId, productName, category, quantity, price
    | filter category = "user_action" and message = "Order Completed"
    | parse @message /productId["\s:]+(?<productId>\d+)/
    | parse @message /productName["\s:]+(?<productName>[^"]+)/
    | parse @message /category["\s:]+(?<productCategory>[^"]+)/
    | parse @message /quantity["\s:]+(?<quantity>\d+)/
    | parse @message /price["\s:]+(?<price>[\d.]+)/
    | stats sum(quantity) as units_sold, sum(quantity * price) as revenue by productId, productName, productCategory
    | sort units_sold desc
    | limit 50
  QUERY
}

# 6. Product Category Performance
resource "aws_cloudwatch_query_definition" "category_performance" {
  name = "${var.service_name}/analytics/category-performance"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, category, quantity, price
    | filter category = "user_action" and message = "Order Completed"
    | parse @message /category["\s:]+(?<productCategory>[^"]+)/
    | parse @message /quantity["\s:]+(?<quantity>\d+)/
    | parse @message /price["\s:]+(?<price>[\d.]+)/
    | stats sum(quantity) as units_sold, sum(quantity * price) as revenue, count() as order_count by productCategory
    | sort revenue desc
  QUERY
}

# 7. Size Preferences
resource "aws_cloudwatch_query_definition" "size_preferences" {
  name = "${var.service_name}/analytics/size-preferences"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, size, quantity
    | filter category = "user_action" and message = "Order Completed"
    | parse @message /size["\s:]+(?<size>[^"]+)/
    | parse @message /quantity["\s:]+(?<quantity>\d+)/
    | stats sum(quantity) as units_sold, count() as order_count by size
    | sort units_sold desc
  QUERY
}

# 8. Conversion Funnel with Details
resource "aws_cloudwatch_query_definition" "conversion_funnel_detailed" {
  name = "${var.service_name}/analytics/conversion-funnel-detailed"

  log_group_names = [var.log_group_name]

  query_string = <<-QUERY
    fields @timestamp, message, userId, productId
    | filter category = "user_action"
    | filter message in ["Product Viewed", "Add to Cart", "Checkout Started", "Order Completed"]
    | parse @message /userId["\s:]+(?<userId>\d+)/
    | parse @message /productId["\s:]+(?<productId>\d+)/
    | stats count() as count, count_distinct(userId) as unique_users by message
    | sort message asc
  QUERY
}

