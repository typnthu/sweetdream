# ECS Blue-Green Deployment Module

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "blue" {
  name              = "/ecs/sweetdream-${var.service_base_name}-blue"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "SweetDream ECS Logs - ${var.service_base_name}-blue"
    Environment = var.environment
    Deployment  = "Blue"
  }
}

resource "aws_cloudwatch_log_group" "green" {
  name              = "/ecs/sweetdream-${var.service_base_name}-green"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "SweetDream ECS Logs - ${var.service_base_name}-green"
    Environment = var.environment
    Deployment  = "Green"
  }
}

# Blue Task Definition
resource "aws_ecs_task_definition" "blue" {
  family                   = "${var.task_base_name}-blue"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)

  lifecycle {
    create_before_destroy = true
  }

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.blue_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = var.environment_variables

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.blue.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name       = "SweetDream Blue Task Definition"
    Deployment = "Blue"
  }
}

# Green Task Definition
resource "aws_ecs_task_definition" "green" {
  family                   = "${var.task_base_name}-green"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)

  lifecycle {
    create_before_destroy = true
  }

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.green_image != "" ? var.green_image : var.blue_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = var.environment_variables

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.green.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name       = "SweetDream Green Task Definition"
    Deployment = "Green"
  }
}

# Blue ECS Service
resource "aws_ecs_service" "blue" {
  name            = "${var.service_base_name}-blue"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.blue.arn
  desired_count   = var.blue_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.blue_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery && var.blue_service_discovery_arn != "" ? [1] : []
    content {
      registry_arn = var.blue_service_discovery_arn
    }
  }

  tags = {
    Name       = "SweetDream Blue ECS Service"
    Deployment = "Blue"
  }

  depends_on = [aws_ecs_task_definition.blue]
}

# Green ECS Service
resource "aws_ecs_service" "green" {
  name            = "${var.service_base_name}-green"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.green.arn
  desired_count   = var.green_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.green_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery && var.green_service_discovery_arn != "" ? [1] : []
    content {
      registry_arn = var.green_service_discovery_arn
    }
  }

  tags = {
    Name       = "SweetDream Green ECS Service"
    Deployment = "Green"
  }

  depends_on = [aws_ecs_task_definition.green]
}

# Auto Scaling Target - Blue
resource "aws_appautoscaling_target" "blue" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.blue.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Target - Green
resource "aws_appautoscaling_target" "green" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.green.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - Blue CPU
resource "aws_appautoscaling_policy" "blue_cpu" {
  name               = "${var.service_base_name}-blue-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.blue.resource_id
  scalable_dimension = aws_appautoscaling_target.blue.scalable_dimension
  service_namespace  = aws_appautoscaling_target.blue.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Green CPU
resource "aws_appautoscaling_policy" "green_cpu" {
  name               = "${var.service_base_name}-green-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.green.resource_id
  scalable_dimension = aws_appautoscaling_target.green.scalable_dimension
  service_namespace  = aws_appautoscaling_target.green.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Blue Memory
resource "aws_appautoscaling_policy" "blue_memory" {
  name               = "${var.service_base_name}-blue-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.blue.resource_id
  scalable_dimension = aws_appautoscaling_target.blue.scalable_dimension
  service_namespace  = aws_appautoscaling_target.blue.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Green Memory
resource "aws_appautoscaling_policy" "green_memory" {
  name               = "${var.service_base_name}-green-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.green.resource_id
  scalable_dimension = aws_appautoscaling_target.green.scalable_dimension
  service_namespace  = aws_appautoscaling_target.green.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}