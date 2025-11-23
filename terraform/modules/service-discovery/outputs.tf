output "namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "backend_service_id" {
  description = "ID of the backend service discovery service"
  value       = aws_service_discovery_service.backend.id
}

output "backend_service_arn" {
  description = "ARN of the backend service discovery service"
  value       = aws_service_discovery_service.backend.arn
}

output "backend_dns_name" {
  description = "DNS name for the backend service"
  value       = "backend.${aws_service_discovery_private_dns_namespace.main.name}"
}

output "user_service_id" {
  description = "ID of the user service discovery service"
  value       = aws_service_discovery_service.user_service.id
}

output "user_service_arn" {
  description = "ARN of the user service discovery service"
  value       = aws_service_discovery_service.user_service.arn
}

output "user_service_dns_name" {
  description = "DNS name for the user service"
  value       = "user-service.${aws_service_discovery_private_dns_namespace.main.name}"
}

output "order_service_id" {
  description = "ID of the order service discovery service"
  value       = aws_service_discovery_service.order_service.id
}

output "order_service_arn" {
  description = "ARN of the order service discovery service"
  value       = aws_service_discovery_service.order_service.arn
}

output "order_service_dns_name" {
  description = "DNS name for the order service"
  value       = "order-service.${aws_service_discovery_private_dns_namespace.main.name}"
}
