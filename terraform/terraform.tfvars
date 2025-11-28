# VPC Configuration
#vpc_cidr = "10.0.0.0/16"

# ECS Configuration
#cluster_name = "sweetdream-cluster"
#task_name    = "sweetdream-task"
#service_name = "sweetdream-service"

# Docker Images - Automatically fetched from ECR repositories
# No need to specify - Terraform gets them dynamically from AWS ECR

# Database Configuration
db_name     = "sweetdream"
db_username = "dbadmin"
db_password = "admin123!"

# Customer Analytics Configuration
enable_customer_analytics = true                   # Enabled - S3 + CloudWatch Insights only
analytics_bucket_prefix   = "sweetdream-analytics" # Must be globally unique - change if needed

# Bastion Host (for RDS access)
enable_bastion = true # Enabled - for database access via SSM
