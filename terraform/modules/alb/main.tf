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

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name        = "sweetdream-backend-tg"
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
    Name = "SweetDream Backend Target Group"
  }
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "sweetdream-frontend-tg"
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
    Name = "SweetDream Frontend Target Group"
  }
}

# HTTP Listener - Only routes to Frontend
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
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
