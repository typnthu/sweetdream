#!/bin/bash
# Deploy to Production Environment (us-east-1)

set -e

# Configuration
ENVIRONMENT="prod"
REGION="us-east-2"
TERRAFORM_DIR="terraform/environments/prod"

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
    log_info "Deploying SweetDream to Production Environment"
    log_info "Region: $REGION"
    log_info "Environment: $ENVIRONMENT"
    
    # Confirmation for production
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_warn "Production deployment cancelled"
        exit 0
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan
    
    # Final confirmation
    read -p "Review the plan above. Continue with production deployment? (yes/no): " final_confirm
    if [ "$final_confirm" != "yes" ]; then
        log_warn "Production deployment cancelled"
        exit 0
    fi
    
    # Apply deployment
    log_info "Applying deployment..."
    terraform apply -auto-approve
    
    # Show outputs
    log_info "Deployment completed! Outputs:"
    terraform output
    
    log_info "Production environment deployed successfully!"
    log_info "Access your app at: $(terraform output -raw prod_alb_url)"
}

main "$@"