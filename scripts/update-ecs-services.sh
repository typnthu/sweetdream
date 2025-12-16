#!/bin/bash

# Update ECS Services with new images
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="409964509537"
CLUSTER_NAME="sweetdream-dev-cluster"
ENVIRONMENT="dev"

echo -e "${GREEN}🔄 Updating ECS services with new images...${NC}"

# Function to update ECS service
update_service() {
    local service_name=$1
    local task_family=$2
    
    echo -e "${YELLOW}🔄 Updating ${service_name}...${NC}"
    
    # Force new deployment
    aws ecs update-service \
        --region ${AWS_REGION} \
        --cluster ${CLUSTER_NAME} \
        --service ${service_name} \
        --force-new-deployment \
        --query 'service.serviceName' \
        --output text
    
    echo -e "${GREEN}✅ ${service_name} update initiated${NC}"
}

# Update all services
echo -e "${YELLOW}📋 Updating ECS services...${NC}"

# Backend Service
update_service "sweetdream-dev-service-backend" "sweetdream-dev-task-backend"

# User Service
update_service "sweetdream-dev-service-user-service" "sweetdream-dev-task-user-service"

# Order Service
update_service "sweetdream-dev-service-order-service" "sweetdream-dev-task-order-service"

# Frontend Service (CodeDeploy managed)
echo -e "${YELLOW}🔄 Frontend service uses CodeDeploy - manual deployment needed${NC}"
echo -e "${YELLOW}   Use AWS Console or AWS CLI to create CodeDeploy deployment${NC}"

echo -e "${GREEN}🎉 ECS services update completed!${NC}"
echo -e "${GREEN}📋 Monitor deployment status:${NC}"
echo -e "   aws ecs describe-services --region ${AWS_REGION} --cluster ${CLUSTER_NAME} --services sweetdream-dev-service-backend sweetdream-dev-service-user-service sweetdream-dev-service-order-service"

# Wait for services to stabilize
echo -e "${YELLOW}⏳ Waiting for services to stabilize...${NC}"
aws ecs wait services-stable \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --services sweetdream-dev-service-backend sweetdream-dev-service-user-service sweetdream-dev-service-order-service

echo -e "${GREEN}✅ All services are stable and running!${NC}"
echo -e "${GREEN}🌐 Application URL: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com${NC}"