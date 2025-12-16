#!/bin/bash
# Quick Rollback Script for SweetDream Blue-Green Deployment

set -e

# Configuration
TERRAFORM_DIR="terraform"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current status and determine rollback target
get_rollback_target() {
    log_info "Determining rollback target..."
    
    cd $TERRAFORM_DIR
    BLUE_WEIGHT=$(terraform output -json blue_green_weights | jq -r '.frontend.blue')
    GREEN_WEIGHT=$(terraform output -json blue_green_weights | jq -r '.frontend.green')
    
    if [ "$BLUE_WEIGHT" -gt "$GREEN_WEIGHT" ]; then
        CURRENT_ACTIVE="blue"
        ROLLBACK_TO="green"
    else
        CURRENT_ACTIVE="green"
        ROLLBACK_TO="blue"
    fi
    
    log_info "Current active: $CURRENT_ACTIVE"
    log_info "Rolling back to: $ROLLBACK_TO"
    cd ..
}

# Perform instant rollback
instant_rollback() {
    log_warn "🚨 PERFORMING INSTANT ROLLBACK 🚨"
    
    cd $TERRAFORM_DIR
    
    if [ "$ROLLBACK_TO" = "blue" ]; then
        cat > emergency-rollback.auto.tfvars << EOF
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
        cat > emergency-rollback.auto.tfvars << EOF
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
    rm -f emergency-rollback.auto.tfvars
    
    log_info "✅ Instant rollback completed!"
    log_info "All traffic is now routed to $ROLLBACK_TO environment"
    cd ..
}

# Verify rollback
verify_rollback() {
    log_info "Verifying rollback..."
    
    cd $TERRAFORM_DIR
    ALB_DNS=$(terraform output -raw alb_dns_name)
    cd ..
    
    # Health check
    for i in {1..5}; do
        if curl -f -s "http://$ALB_DNS/api/health" > /dev/null; then
            log_info "✅ Health check passed after rollback"
            return 0
        fi
        log_warn "Health check attempt $i failed, retrying..."
        sleep 5
    done
    
    log_error "❌ Health check failed after rollback"
    return 1
}

# Main rollback function
main() {
    log_warn "🚨 EMERGENCY ROLLBACK INITIATED 🚨"
    
    # Confirmation
    read -p "Are you sure you want to rollback? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Rollback cancelled"
        exit 0
    fi
    
    get_rollback_target
    instant_rollback
    
    if verify_rollback; then
        log_info "🎉 Rollback completed successfully!"
        log_info "System is now running on $ROLLBACK_TO environment"
    else
        log_error "❌ Rollback verification failed"
        log_error "Manual intervention may be required"
        exit 1
    fi
}

# Run main function
main "$@"