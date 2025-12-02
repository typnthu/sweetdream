resource "aws_secretsmanager_secret" "db_credentials" {
  name        = var.secret_name
  description = "Database credentials for ${var.app_name}"

  tags = {
    Name = "${var.app_name}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
