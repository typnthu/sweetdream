#!/bin/bash

# Complete deployment script for SweetDream application
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍰 SweetDream Application Deployment${NC}"
echo -e "${BLUE}====================================${NC}"

# Configuration
IMAGE_TAG=${1:-dev}
DEPLOY_METHOD=${2:-manual}  # manual or codedeploy

echo -e "${GREEN}📋 Deployment Configuration:${NC}"
echo -e "   Image Tag: ${IMAGE_TAG}"
echo -e "   Deploy Method: ${DEPLOY_METHOD}"
echo -e "   Environment: Development (us-east-1)"
echo ""

# Step 1: Build and push images
echo -e "${YELLOW}Step 1: Building and pushing Docker images...${NC}"
chmod +x ./scripts/deploy-images.sh
./scripts/deploy-images.sh

echo ""

# Step 2: Deploy based on method
if [ "$DEPLOY_METHOD" = "codedeploy" ]; then
    echo -e "${YELLOW}Step 2: Deploying with CodeDeploy (Blue-Green)...${NC}"
    
    # Update backend services manually
    chmod +x ./scripts/update-ecs-services.sh
    ./scripts/update-ecs-services.sh
    
    # Deploy frontend with CodeDeploy
    chmod +x ./scripts/codedeploy-frontend.sh
    ./scripts/codedeploy-frontend.sh ${IMAGE_TAG}
    
else
    echo -e "${YELLOW}Step 2: Deploying with manual ECS update...${NC}"
    chmod +x ./scripts/update-ecs-services.sh
    ./scripts/update-ecs-services.sh
    
    # Update frontend manually
    echo -e "${YELLOW}🔄 Updating frontend service...${NC}"
    aws ecs update-service \
        --region us-east-1 \
        --cluster sweetdream-dev-cluster \
        --service sweetdream-dev-service-frontend \
        --force-new-deployment \
        --query 'service.serviceName' \
        --output text
fi

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📋 Application Details:${NC}"
echo -e "   🌐 URL: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com"
echo -e "   🔍 Backend API: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com/api"
echo -e "   📊 AWS Console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/sweetdream-dev-cluster"
echo ""
echo -e "${YELLOW}🔧 Useful commands:${NC}"
echo -e "   Check service status: aws ecs describe-services --region us-east-1 --cluster sweetdream-dev-cluster --services sweetdream-dev-service-frontend"
echo -e "   View logs: aws logs tail /ecs/sweetdream-frontend --region us-east-1 --follow"
echo -e "   Scale service: aws ecs update-service --region us-east-1 --cluster sweetdream-dev-cluster --service sweetdream-dev-service-frontend --desired-count 3"