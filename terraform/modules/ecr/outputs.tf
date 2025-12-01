output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.backend.arn
}

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "user_service_repository_url" {
  description = "URL of the user service ECR repository"
  value       = aws_ecr_repository.user_service.repository_url
}

output "user_service_repository_arn" {
  description = "ARN of the user service ECR repository"
  value       = aws_ecr_repository.user_service.arn
}

output "order_service_repository_url" {
  description = "URL of the order service ECR repository"
  value       = aws_ecr_repository.order_service.repository_url
}

output "order_service_repository_arn" {
  description = "ARN of the order service ECR repository"
  value       = aws_ecr_repository.order_service.arn
}

output "all_repository_urls" {
  description = "Map of all ECR repository URLs"
  value = {
    backend       = aws_ecr_repository.backend.repository_url
    frontend      = aws_ecr_repository.frontend.repository_url
    user_service  = aws_ecr_repository.user_service.repository_url
    order_service = aws_ecr_repository.order_service.repository_url
  }
}
