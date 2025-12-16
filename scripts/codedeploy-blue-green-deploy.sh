#!/bin/bash
# CodeDeploy Blue-Green Deployment Script for SweetDream

set -e

# Configuration
REGION="us-east-1"
APP_NAME="sweetdream-frontend-codedeploy"
DEPLOYMENT_GROUP="sweetdream-frontend-deployment-group"
CLUSTER_NAME="sweetdream-cluster"
SERVICE_NAME="sweetdream-service-frontend"

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

# Create deployment
create_deployment() {
    local NEW_IMAGE=$1
    local TASK_DEFINITION_ARN=$2
    
    log_info "Creating CodeDeploy deployment..."
    log_info "New image: $NEW_IMAGE"
    
    # Create appspec.yaml content
    cat > appspec.yaml << EOF
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "$TASK_DEFINITION_ARN"
        LoadBalancerInfo:
          ContainerName: "sweetdream-frontend"
          ContainerPort: 3000
EOF

    # Create deployment
    DEPLOYMENT_ID=$(aws deploy create-deployment \
        --application-name "$APP_NAME" \
        --deployment-group-name "$DEPLOYMENT_GROUP" \
        --revision revisionType=AppSpecContent,appSpecContent="{\"content\":\"$(cat appspec.yaml | base64 -w 0)\"}" \
        --region "$REGION" \
        --query 'deploymentId' \
        --output text)
    
    log_info "Deployment created with ID: $DEPLOYMENT_ID"
    
    # Monitor deployment
    monitor_deployment "$DEPLOYMENT_ID"
    
    # Cleanup
    rm -f appspec.yaml
}

# Monitor deployment
monitor_deployment() {
    local DEPLOYMENT_ID=$1
    
    log_info "Monitoring deployment: $DEPLOYMENT_ID"
    
    while true; do
        STATUS=$(aws deploy get-deployment \
            --deployment-id "$DEPLOYMENT_ID" \
            --region "$REGION" \
            --query 'deploymentInfo.status' \
            --output text)
        
        case $STATUS in
            "Created"|"Queued"|"InProgress")
                log_info "Deployment status: $STATUS"
                sleep 30
                ;;
            "Succeeded")
                log_info "🎉 Deployment completed successfully!"
                break
                ;;
            "Failed"|"Stopped")
                log_error "❌ Deployment failed with status: $STATUS"
                exit 1
                ;;
            *)
                log_warn "Unknown deployment status: $STATUS"
                sleep 30
                ;;
        esac
    done
}

# Main deployment function
main() {
    local NEW_IMAGE=$1
    local TASK_DEFINITION_ARN=$2
    
    if [ -z "$NEW_IMAGE" ] || [ -z "$TASK_DEFINITION_ARN" ]; then
        log_error "Usage: $0 <new-docker-image> <task-definition-arn>"
        log_error "Example: $0 123456789012.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:v2.0.0 arn:aws:ecs:us-east-1:123456789012:task-definition/sweetdream-task-frontend:2"
        exit 1
    fi
    
    log_info "Starting CodeDeploy Blue-Green deployment for SweetDream Frontend"
    
    check_prerequisites
    create_deployment "$NEW_IMAGE" "$TASK_DEFINITION_ARN"
    
    log_info "🚀 CodeDeploy Blue-Green deployment completed!"
}

# Run main function
main "$@"