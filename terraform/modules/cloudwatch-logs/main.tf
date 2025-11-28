# Simple CloudWatch Logs Module
# Creates log group and optional Insights queries for customer analytics

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

# ===== CUSTOMER ANALYTICS QUERIES =====

# 1. Most Viewed Products
resource "aws_cloudwatch_query_definition" "product_views" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/product-views"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /user_action/
    | filter @message like /Product Viewed/
    | parse @message /productName["\s:]+(?<product>[^"]+)/
    | stats count() as views by product
    | sort views desc
    | limit 20
  QUERY
}

# 2. Purchase Funnel
resource "aws_cloudwatch_query_definition" "purchase_funnel" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/purchase-funnel"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /user_action/
    | filter @message like /Product Viewed/ or @message like /Add to Cart/ or @message like /Checkout Started/ or @message like /Order Completed/
    | parse @message /message["\s:]+(?<action>[^"]+)/
    | stats count() by action
  QUERY
}

# 3. Search Trends
resource "aws_cloudwatch_query_definition" "search_trends" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/search-trends"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /Product Search/
    | parse @message /query["\s:]+(?<search>[^"]+)/
    | stats count() as searches by search
    | sort searches desc
    | limit 20
  QUERY
}

# 4. Customer Behavior by User
resource "aws_cloudwatch_query_definition" "customer_behavior" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/customer-behavior"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /user_action/
    | parse @message /userId["\s:]+(?<user>\d+)/
    | filter user > 0
    | stats count() as actions by user
    | sort actions desc
    | limit 50
  QUERY
}

# 5. API Response Times
resource "aws_cloudwatch_query_definition" "api_performance" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/api-performance"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /api_call/
    | parse @message /url["\s:]+(?<endpoint>[^"]+)/
    | parse @message /responseTime["\s:]+(?<time>\d+)/
    | stats avg(time) as avg_ms, max(time) as max_ms, count() as requests by endpoint
    | sort avg_ms desc
  QUERY
}

# 6. Slow Requests (>2 seconds)
resource "aws_cloudwatch_query_definition" "slow_requests" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/slow-requests"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /api_call/
    | parse @message /url["\s:]+(?<endpoint>[^"]+)/
    | parse @message /responseTime["\s:]+(?<time>\d+)/
    | filter time > 2000
    | sort time desc
    | limit 50
  QUERY
}

# 7. Error Rate by Hour
resource "aws_cloudwatch_query_definition" "error_rate" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/error-rate"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/ or @message like /"level":"error"/
    | stats count() as errors by bin(1h)
  QUERY
}

# 8. Active Users by Hour
resource "aws_cloudwatch_query_definition" "active_users" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/active-users"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /user_action/
    | parse @message /userId["\s:]+(?<user>\d+)/
    | filter user > 0
    | stats count_distinct(user) as active_users by bin(1h)
  QUERY
}

# 9. Session Duration
resource "aws_cloudwatch_query_definition" "session_duration" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/session-duration"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /user_action/
    | parse @message /sessionId["\s:]+(?<session>[^"]+)/
    | stats min(@timestamp) as start, max(@timestamp) as end by session
    | fields session, (end - start) / 1000 / 60 as duration_minutes
    | sort duration_minutes desc
    | limit 100
  QUERY
}

# 10. Cart Abandonment
resource "aws_cloudwatch_query_definition" "cart_abandonment" {
  count = var.enable_analytics_queries ? 1 : 0
  name  = "${var.service_name}/cart-abandonment"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /Add to Cart/ or @message like /Order Completed/
    | parse @message /sessionId["\s:]+(?<session>[^"]+)/
    | parse @message /message["\s:]+(?<action>[^"]+)/
    | stats count() by session, action
  QUERY
}
