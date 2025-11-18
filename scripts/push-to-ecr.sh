#!/bin/bash

# SweetDream - Push Docker Images to AWS ECR
# This script builds and pushes both frontend and backend images to ECR

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
BACKEND_REPO="sweetdream-backend"
FRONTEND_REPO="sweetdream-frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS_ACCOUNT_ID is set
if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_error "AWS_ACCOUNT_ID is not set"
    echo "Usage: AWS_ACCOUNT_ID=123456789012 ./scripts/push-to-ecr.sh"
    exit 1
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

print_info "Starting deployment to AWS ECR"
print_info "Region: $AWS_REGION"
print_info "Account: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Login to ECR
print_info "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

if [ $? -ne 0 ]; then
    print_error "Failed to login to ECR"
    exit 1
fi

print_info "Successfully logged in to ECR"
echo ""

# Step 2: Create ECR repositories if they don't exist
print_info "Checking ECR repositories..."

for REPO in $BACKEND_REPO $FRONTEND_REPO; do
    if ! aws ecr describe-repositories --repository-names $REPO --region $AWS_REGION > /dev/null 2>&1; then
        print_warning "Repository $REPO does not exist. Creating..."
        aws ecr create-repository \
            --repository-name $REPO \
            --region $AWS_REGION \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        print_info "Created repository: $REPO"
    else
        print_info "Repository $REPO already exists"
    fi
done

echo ""

# Step 3: Build and push backend
print_info "Building backend Docker image..."
cd be

docker build -t $BACKEND_REPO:latest .

if [ $? -ne 0 ]; then
    print_error "Failed to build backend image"
    exit 1
fi

print_info "Tagging backend image..."
docker tag $BACKEND_REPO:latest $ECR_REGISTRY/$BACKEND_REPO:latest
docker tag $BACKEND_REPO:latest $ECR_REGISTRY/$BACKEND_REPO:$(date +%Y%m%d-%H%M%S)

print_info "Pushing backend image to ECR..."
docker push $ECR_REGISTRY/$BACKEND_REPO:latest
docker push $ECR_REGISTRY/$BACKEND_REPO:$(date +%Y%m%d-%H%M%S)

if [ $? -ne 0 ]; then
    print_error "Failed to push backend image"
    exit 1
fi

print_info "Backend image pushed successfully!"
cd ..
echo ""

# Step 4: Build and push frontend
print_info "Building frontend Docker image..."
cd fe

docker build -t $FRONTEND_REPO:latest .

if [ $? -ne 0 ]; then
    print_error "Failed to build frontend image"
    exit 1
fi

print_info "Tagging frontend image..."
docker tag $FRONTEND_REPO:latest $ECR_REGISTRY/$FRONTEND_REPO:latest
docker tag $FRONTEND_REPO:latest $ECR_REGISTRY/$FRONTEND_REPO:$(date +%Y%m%d-%H%M%S)

print_info "Pushing frontend image to ECR..."
docker push $ECR_REGISTRY/$FRONTEND_REPO:latest
docker push $ECR_REGISTRY/$FRONTEND_REPO:$(date +%Y%m%d-%H%M%S)

if [ $? -ne 0 ]; then
    print_error "Failed to push frontend image"
    exit 1
fi

print_info "Frontend image pushed successfully!"
cd ..
echo ""

# Summary
print_info "=========================================="
print_info "Deployment Summary"
print_info "=========================================="
echo ""
echo "Backend Image:"
echo "  - $ECR_REGISTRY/$BACKEND_REPO:latest"
echo ""
echo "Frontend Image:"
echo "  - $ECR_REGISTRY/$FRONTEND_REPO:latest"
echo ""
print_info "All images pushed successfully to ECR!"
print_info "You can now update your ECS task definitions with these images."
echo ""
print_info "Next steps:"
echo "  1. Update Terraform variables with ECR image URIs"
echo "  2. Run 'terraform apply' to deploy ECS services"
echo "  3. Or use the GitHub Actions workflow for automated deployment"
