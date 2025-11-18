# Development Environment Configuration

vpc_cidr = "10.0.0.0/16"

cluster_name = "sweetdream-cluster-dev"
task_name    = "sweetdream-task-dev"
service_name = "sweetdream-service-dev"

db_name     = "sweetdream_dev"
db_username = "admin"
# db_password should be set via environment variable or GitHub secret

s3_bucket_name          = "sweetdream-logs-data-dev"
s3_products_bucket_name = "sweetdream-products-dev"

# These will be updated by CI/CD
backend_image  = "nginx:latest"
frontend_image = "nginx:latest"
