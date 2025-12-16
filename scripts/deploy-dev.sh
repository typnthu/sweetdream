#!/bin/bash
# Deploy to Development Environment (us-west-2)

set -e

# Configuration
ENVIRONMENT="dev"
REGION="us-east-1"
TERRAFORM_DIR="terraform/environments/dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

main() {
    log_info "Deploying SweetDream to Development Environment"
    log_info "Region: $REGION"
    log_info "Environment: $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan
    
    # Apply deployment
    log_info "Applying deployment..."
    terraform apply -auto-approve
    
    # Show outputs
    log_info "Deployment completed! Outputs:"
    terraform output
    
    log_info "Development environment deployed successfully!"
    log_info "Access your app at: $(terraform output -raw dev_alb_url)"
}

main "$@"