output "secret_arn" {
  description = "ARN of the created secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}
