output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# Blue/Green Target Group ARNs
output "backend_blue_target_group_arn" {
  description = "ARN of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.arn
}

output "backend_green_target_group_arn" {
  description = "ARN of the backend green target group"
  value       = aws_lb_target_group.backend_green.arn
}

output "frontend_blue_target_group_arn" {
  description = "ARN of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.arn
}

output "frontend_green_target_group_arn" {
  description = "ARN of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.arn
}

# Legacy outputs for backward compatibility (default to blue)
output "backend_target_group_arn" {
  description = "ARN of the backend target group (blue by default)"
  value       = aws_lb_target_group.backend_blue.arn
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group (blue by default)"
  value       = aws_lb_target_group.frontend_blue.arn
}

# Target Group Names
output "frontend_blue_target_group_name" {
  description = "Name of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.name
}

output "frontend_green_target_group_name" {
  description = "Name of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.name
}

output "backend_blue_target_group_name" {
  description = "Name of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.name
}

output "backend_green_target_group_name" {
  description = "Name of the backend green target group"
  value       = aws_lb_target_group.backend_green.name
}

# User Service Target Groups
output "user_service_blue_target_group_arn" {
  description = "ARN of the user service blue target group"
  value       = aws_lb_target_group.user_service_blue.arn
}

output "user_service_green_target_group_arn" {
  description = "ARN of the user service green target group"
  value       = aws_lb_target_group.user_service_green.arn
}

output "user_service_blue_target_group_name" {
  description = "Name of the user service blue target group"
  value       = aws_lb_target_group.user_service_blue.name
}

output "user_service_green_target_group_name" {
  description = "Name of the user service green target group"
  value       = aws_lb_target_group.user_service_green.name
}

# Order Service Target Groups
output "order_service_blue_target_group_arn" {
  description = "ARN of the order service blue target group"
  value       = aws_lb_target_group.order_service_blue.arn
}

output "order_service_green_target_group_arn" {
  description = "ARN of the order service green target group"
  value       = aws_lb_target_group.order_service_green.arn
}

output "order_service_blue_target_group_name" {
  description = "Name of the order service blue target group"
  value       = aws_lb_target_group.order_service_blue.name
}

output "order_service_green_target_group_name" {
  description = "Name of the order service green target group"
  value       = aws_lb_target_group.order_service_green.name
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

# Listener Rules for Dependencies
output "user_service_listener_rule_http_arn" {
  description = "ARN of the user service HTTP listener rule"
  value       = var.environment == "production" ? aws_lb_listener_rule.user_service_rule_http[0].arn : null
}

output "order_service_listener_rule_http_arn" {
  description = "ARN of the order service HTTP listener rule"
  value       = var.environment == "production" ? aws_lb_listener_rule.order_service_rule_http[0].arn : null
}
