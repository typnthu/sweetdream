# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.namespace_name
  description = "Private DNS namespace for ECS service discovery"
  vpc         = var.vpc_id

  tags = {
    Name = "SweetDream Service Discovery"
  }
}

# Service Discovery Service for Backend
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "SweetDream Backend Service Discovery"
  }
}
