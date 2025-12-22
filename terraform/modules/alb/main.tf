# Security Group for ALB (created here since it needs to be referenced)
resource "aws_security_group" "alb" {
  name        = "sweetdream-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "sweetdream-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "sweetdream-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name        = "SweetDream ALB"
    Environment = "production"
  }
}

# Backend Target Groups (Blue/Green)
resource "aws_lb_target_group" "backend_blue" {
  name        = "sweetdream-backend-blue-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Backend Blue Target Group"
  }
}

resource "aws_lb_target_group" "backend_green" {
  name        = "sweetdream-backend-green-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Backend Green Target Group"
  }
}

# Frontend Target Groups (Blue/Green)
resource "aws_lb_target_group" "frontend_blue" {
  name        = "sweetdream-frontend-blue-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Frontend Blue Target Group"
  }
}

resource "aws_lb_target_group" "frontend_green" {
  name        = "sweetdream-frontend-green-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Frontend Green Target Group"
  }
}

# User Service Target Groups (Blue/Green)
resource "aws_lb_target_group" "user_service_blue" {
  name        = "sweetdream-user-svc-blue-tg"
  port        = 3003
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream User Service Blue Target Group"
  }

  depends_on = [aws_lb.main]
}

resource "aws_lb_target_group" "user_service_green" {
  name        = "sweetdream-user-svc-green-tg"
  port        = 3003
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream User Service Green Target Group"
  }

  depends_on = [aws_lb.main]
}

# Order Service Target Groups (Blue/Green)
resource "aws_lb_target_group" "order_service_blue" {
  name        = "sweetdream-order-svc-blue-tg"
  port        = 3002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Order Service Blue Target Group"
  }

  depends_on = [aws_lb.main]
}

resource "aws_lb_target_group" "order_service_green" {
  name        = "sweetdream-order-svc-green-tg"
  port        = 3002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "SweetDream Order Service Green Target Group"
  }

  depends_on = [aws_lb.main]
}

# HTTP Listener - Weighted routing for Blue/Green
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.frontend_blue.arn
        weight = var.traffic_weights.frontend.blue
      }

      target_group {
        arn    = aws_lb_target_group.frontend_green.arn
        weight = var.traffic_weights.frontend.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  depends_on = [
    aws_lb_target_group.frontend_blue,
    aws_lb_target_group.frontend_green
  ]
}

resource "aws_lb_listener" "https" {
  count             = var.acm_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.frontend_blue.arn
        weight = var.traffic_weights.frontend.blue
      }

      target_group {
        arn    = aws_lb_target_group.frontend_green.arn
        weight = var.traffic_weights.frontend.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  depends_on = [
    aws_lb_target_group.frontend_blue,
    aws_lb_target_group.frontend_green
  ]
}

# Security Group Rule to allow ALB to communicate with ECS
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = var.ecs_security_group_id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB to communicate with ECS"
}
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.ecs_security_group_id
  description              = "Allow ALB to access ECS services"
}

# Backend API routing rule for HTTP - Disabled in production (uses service discovery)
# resource "aws_lb_listener_rule" "backend_rule_http" {
#   count        = var.environment == "production" ? 1 : 0
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 10
#
#   action {
#     type = "forward"
#     
#     forward {
#       target_group {
#         arn    = aws_lb_target_group.backend_blue.arn
#         weight = var.traffic_weights.frontend.blue  # Use frontend weights for backend API
#       }
#       
#       target_group {
#         arn    = aws_lb_target_group.backend_green.arn
#         weight = var.traffic_weights.frontend.green
#       }
#       
#       stickiness {
#         enabled  = false
#         duration = 1
#       }
#     }
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }

# Backend API routing rule for HTTPS - Disabled in production (uses service discovery)
# resource "aws_lb_listener_rule" "backend_rule_https" {
#   count        = var.acm_certificate_arn != null && var.environment == "production" ? 1 : 0
#   listener_arn = aws_lb_listener.https[0].arn
#   priority     = 10
#
#   action {
#     type = "forward"
#     
#     forward {
#       target_group {
#         arn    = aws_lb_target_group.backend_blue.arn
#         weight = var.traffic_weights.frontend.blue  # Use frontend weights for backend API
#       }
#       
#       target_group {
#         arn    = aws_lb_target_group.green.arn
#         weight = var.traffic_weights.frontend.green
#       }
#       
#       stickiness {
#         enabled  = false
#         duration = 1
#       }
#     }
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }

# User Service API routing rule for HTTP - Blue/Green weighted (Production only)
resource "aws_lb_listener_rule" "user_service_rule_http" {
  count        = var.environment == "production" ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.user_service_blue.arn
        weight = var.traffic_weights.user_service.blue
      }

      target_group {
        arn    = aws_lb_target_group.user_service_green.arn
        weight = var.traffic_weights.user_service.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/users/*", "/api/auth/*", "/api/customers/*", "/api/customers"]
    }
  }
}

# Order Service API routing rule for HTTP - Blue/Green weighted (Production only)
resource "aws_lb_listener_rule" "order_service_rule_http" {
  count        = var.environment == "production" ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.order_service_blue.arn
        weight = var.traffic_weights.order_service.blue
      }

      target_group {
        arn    = aws_lb_target_group.order_service_green.arn
        weight = var.traffic_weights.order_service.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/orders/*", "/api/orders"]
    }
  }
}

# User Service API routing rule for HTTPS (if certificate exists) - Blue/Green weighted (Production only)
resource "aws_lb_listener_rule" "user_service_rule_https" {
  count        = var.acm_certificate_arn != null && var.environment == "production" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 20

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.user_service_blue.arn
        weight = var.traffic_weights.user_service.blue
      }

      target_group {
        arn    = aws_lb_target_group.user_service_green.arn
        weight = var.traffic_weights.user_service.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/users/*", "/api/auth/*", "/api/customers/*", "/api/customers"]
    }
  }
}

# Order Service API routing rule for HTTPS (if certificate exists) - Blue/Green weighted (Production only)
resource "aws_lb_listener_rule" "order_service_rule_https" {
  count        = var.acm_certificate_arn != null && var.environment == "production" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 30

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.order_service_blue.arn
        weight = var.traffic_weights.order_service.blue
      }

      target_group {
        arn    = aws_lb_target_group.order_service_green.arn
        weight = var.traffic_weights.order_service.green
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/orders/*", "/api/orders"]
    }
  }
}