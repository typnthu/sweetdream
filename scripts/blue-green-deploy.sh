#!/bin/bash
# Blue-Green Deployment Script for SweetDream

set -e

# Configuration
TERRAFORM_DIR="terraform"
SERVICE_NAME="frontend"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Get current deployment status
get_current_status() {
    log_info "Getting current deployment status..."
    
    cd $TERRAFORM_DIR
    BLUE_COUNT=$(terraform output -json frontend_blue_green_counts | jq -r '.blue')
    GREEN_COUNT=$(terraform output -json frontend_blue_green_counts | jq -r '.green')
    BLUE_WEIGHT=$(terraform output -json blue_green_weights | jq -r '.frontend.blue')
    GREEN_WEIGHT=$(terraform output -json blue_green_weights | jq -r '.frontend.green')
    
    log_info "Current Status:"
    log_info "  Blue Tasks: $BLUE_COUNT, Traffic: $BLUE_WEIGHT%"
    log_info "  Green Tasks: $GREEN_COUNT, Traffic: $GREEN_WEIGHT%"
    
    if [ "$BLUE_WEIGHT" -gt "$GREEN_WEIGHT" ]; then
        ACTIVE_COLOR="blue"
        INACTIVE_COLOR="green"
    else
        ACTIVE_COLOR="green"
        INACTIVE_COLOR="blue"
    fi
    
    log_info "Active deployment: $ACTIVE_COLOR"
    cd ..
}

# Deploy new version to inactive environment
deploy_to_inactive() {
    local NEW_IMAGE=$1
    
    log_info "Deploying new image to $INACTIVE_COLOR environment..."
    log_info "Image: $NEW_IMAGE"
    
    cd $TERRAFORM_DIR
    
    # Update terraform.tfvars with new image and start inactive tasks
    if [ "$INACTIVE_COLOR" = "green" ]; then
        # Deploy to green
        cat > deploy.auto.tfvars << EOF
frontend_blue_green_counts = {
  blue  = $BLUE_COUNT
  green = 2
}
EOF
    else
        # Deploy to blue
        cat > deploy.auto.tfvars << EOF
frontend_blue_green_counts = {
  blue  = 2
  green = $GREEN_COUNT
}
EOF
    fi
    
    # Apply changes
    terraform apply -auto-approve
    
    log_info "Deployment to $INACTIVE_COLOR completed"
    cd ..
}

# Health check
health_check() {
    log_info "Performing health checks on $INACTIVE_COLOR environment..."
    
    # Get ALB DNS name
    cd $TERRAFORM_DIR
    ALB_DNS=$(terraform output -raw alb_dns_name)
    cd ..
    
    # Wait for tasks to be healthy
    log_info "Waiting for tasks to be healthy..."
    sleep 30
    
    # Perform health check
    for i in {1..10}; do
        if curl -f -s "http://$ALB_DNS/api/health" > /dev/null; then
            log_info "Health check passed"
            return 0
        fi
        log_warn "Health check attempt $i failed, retrying..."
        sleep 10
    done
    
    log_error "Health check failed after 10 attempts"
    return 1
}

# Shift traffic gradually
shift_traffic() {
    log_info "Starting gradual traffic shift to $INACTIVE_COLOR..."
    
    cd $TERRAFORM_DIR
    
    # Traffic shift stages: 10% -> 50% -> 100%
    STAGES=(10 50 100)
    
    for STAGE in "${STAGES[@]}"; do
        log_info "Shifting ${STAGE}% traffic to $INACTIVE_COLOR..."
        
        if [ "$INACTIVE_COLOR" = "green" ]; then
            cat > traffic.auto.tfvars << EOF
blue_green_weights = {
  frontend = {
    blue  = $((100 - STAGE))
    green = $STAGE
  }
  user_service = {
    blue  = 100
    green = 0
  }
  order_service = {
    blue  = 100
    green = 0
  }
}
EOF
        else
            cat > traffic.auto.tfvars << EOF
blue_green_weights = {
  frontend = {
    blue  = $STAGE
    green = $((100 - STAGE))
  }
  user_service = {
    blue  = 100
    green = 0
  }
  order_service = {
    blue  = 100
    green = 0
  }
}
EOF
        fi
        
        terraform apply -auto-approve
        
        log_info "Traffic shift to ${STAGE}% completed"
        
        # Wait and monitor
        if [ "$STAGE" -lt 100 ]; then
            log_info "Monitoring for 2 minutes..."
            sleep 120
            
            # Check for errors
            if ! health_check; then
                log_error "Health check failed during traffic shift"
                rollback
                exit 1
            fi
        fi
    done
    
    cd ..
}

# Complete deployment (stop old tasks)
complete_deployment() {
    log_info "Completing deployment - stopping old tasks..."
    
    cd $TERRAFORM_DIR
    
    if [ "$INACTIVE_COLOR" = "green" ]; then
        # Green is now active, stop blue
        cat > final.auto.tfvars << EOF
frontend_blue_green_counts = {
  blue  = 0
  green = 2
}
EOF
    else
        # Blue is now active, stop green
        cat > final.auto.tfvars << EOF
frontend_blue_green_counts = {
  blue  = 2
  green = 0
}
EOF
    fi
    
    terraform apply -auto-approve
    
    # Clean up temporary tfvars files
    rm -f deploy.auto.tfvars traffic.auto.tfvars final.auto.tfvars
    
    log_info "Deployment completed successfully!"
    cd ..
}

# Rollback function
rollback() {
    log_error "Rolling back deployment..."
    
    cd $TERRAFORM_DIR
    
    # Restore original traffic weights
    if [ "$ACTIVE_COLOR" = "blue" ]; then
        cat > rollback.auto.tfvars << EOF
blue_green_weights = {
  frontend = {
    blue  = 100
    green = 0
  }
  user_service = {
    blue  = 100
    green = 0
  }
  order_service = {
    blue  = 100
    green = 0
  }
}
EOF
    else
        cat > rollback.auto.tfvars << EOF
blue_green_weights = {
  frontend = {
    blue  = 0
    green = 100
  }
  user_service = {
    blue  = 100
    green = 0
  }
  order_service = {
    blue  = 100
    green = 0
  }
}
EOF
    fi
    
    terraform apply -auto-approve
    rm -f rollback.auto.tfvars deploy.auto.tfvars traffic.auto.tfvars
    
    log_info "Rollback completed"
    cd ..
}

# Main deployment function
main() {
    local NEW_IMAGE=$1
    
    if [ -z "$NEW_IMAGE" ]; then
        log_error "Usage: $0 <new-docker-image>"
        log_error "Example: $0 123456789012.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:v2.0.0"
        exit 1
    fi
    
    log_info "Starting Blue-Green deployment for SweetDream"
    log_info "New image: $NEW_IMAGE"
    
    check_prerequisites
    get_current_status
    deploy_to_inactive "$NEW_IMAGE"
    
    if health_check; then
        shift_traffic
        complete_deployment
        log_info "🎉 Blue-Green deployment completed successfully!"
    else
        log_error "❌ Deployment failed health checks"
        rollback
        exit 1
    fi
}

# Run main function
main "$@"