# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "sweetdream-db-subnet-group-${substr(md5(join(",", var.private_subnet_ids)), 0, 8)}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "SweetDream DB Subnet Group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier            = "sweetdream-db"
  engine                = "postgres"
  engine_version        = "15.10"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.ecs_security_group_id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = true
  final_snapshot_identifier = "sweetdream-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "SweetDream PostgreSQL"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [final_snapshot_identifier]
  }
}
