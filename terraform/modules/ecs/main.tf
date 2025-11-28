# CloudWatch Log Group (using separate module for easier management)
module "cloudwatch_logs" {
  source = "../cloudwatch-logs"

  log_group_name          = "/ecs/sweetdream-${var.service_name}"
  service_name            = var.service_name
  retention_days          = var.log_retention_days
  enable_analytics_queries = var.enable_analytics_queries

  tags = {
    Name        = "SweetDream ECS Logs - ${var.service_name}"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.task_name
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = concat(
      var.db_host != "" ? [
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}/${var.db_name}"
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket
        }
      ] : [],
      var.backend_url != "" ? [
        {
          name  = "BACKEND_API_URL"
          value = var.backend_url
        }
      ] : [],
      var.user_service_url != "" ? [
        {
          name  = "USER_SERVICE_URL"
          value = var.user_service_url
        }
      ] : [],
      var.order_service_url != "" ? [
        {
          name  = "ORDER_SERVICE_URL"
          value = var.order_service_url
        }
      ] : [],
      var.backend_url != "" || var.user_service_url != "" || var.order_service_url != "" ? [
        {
          name  = "NEXT_PUBLIC_API_URL"
          value = "/api/proxy"
        }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.cloudwatch_logs.log_group_name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "SweetDream Task Definition"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = var.service_discovery_arn
    }
  }

  tags = {
    Name = "SweetDream ECS Service"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "cpu" {
  name               = "sweetdream-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "memory" {
  name               = "sweetdream-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
