#!/bin/bash

# Deploy Images to ECR - Development Environment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="409964509537"
ENVIRONMENT="dev"

# ECR Repository URLs
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-backend"
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-frontend"
USER_SERVICE_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-user-service"
ORDER_SERVICE_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-order-service"

echo -e "${GREEN}🚀 Starting deployment to ECR repositories...${NC}"

# Login to ECR
echo -e "${YELLOW}📝 Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Function to build and push image
build_and_push() {
    local service_name=$1
    local service_path=$2
    local repo_url=$3
    local tag=${4:-${ENVIRONMENT}}
    
    echo -e "${YELLOW}🔨 Building ${service_name}...${NC}"
    
    # Build image
    docker build -t ${service_name}:${tag} ${service_path}
    
    # Tag for ECR
    docker tag ${service_name}:${tag} ${repo_url}:${tag}
    docker tag ${service_name}:${tag} ${repo_url}:latest
    
    # Push to ECR
    echo -e "${YELLOW}📤 Pushing ${service_name} to ECR...${NC}"
    docker push ${repo_url}:${tag}
    docker push ${repo_url}:latest
    
    echo -e "${GREEN}✅ ${service_name} deployed successfully${NC}"
}

# Deploy each service
echo -e "${YELLOW}🏗️  Building and pushing services...${NC}"

# Backend Service
build_and_push "sweetdream-backend" "./be" ${BACKEND_REPO}

# Frontend Service  
build_and_push "sweetdream-frontend" "./fe" ${FRONTEND_REPO}

# User Service
build_and_push "sweetdream-user-service" "./user-service" ${USER_SERVICE_REPO}

# Order Service
build_and_push "sweetdream-order-service" "./order-service" ${ORDER_SERVICE_REPO}

echo -e "${GREEN}🎉 All services deployed to ECR successfully!${NC}"
echo -e "${GREEN}📋 Next steps:${NC}"
echo -e "   1. Update ECS services to use new images"
echo -e "   2. Test application at: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com"
echo -e "   3. Monitor deployment in AWS Console"