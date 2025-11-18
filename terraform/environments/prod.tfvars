# Production Environment Configuration

vpc_cidr = "10.1.0.0/16"

cluster_name = "sweetdream-cluster-prod"
task_name    = "sweetdream-task-prod"
service_name = "sweetdream-service-prod"

db_name     = "sweetdream_prod"
db_username = "admin"
# db_password should be set via environment variable or GitHub secret

s3_bucket_name          = "sweetdream-logs-data-prod"
s3_products_bucket_name = "sweetdream-products-prod"

# These will be updated by CI/CD
backend_image  = "nginx:latest"
frontend_image = "nginx:latest"
