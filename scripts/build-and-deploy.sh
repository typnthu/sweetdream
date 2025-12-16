#!/bin/bash

# Complete Build and Deploy Script for SweetDream
# This script creates ECR repositories, builds Docker images, and pushes them to ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
AWS_REGION="us-east-1"

# Override region for production
if [ "$ENVIRONMENT" = "prod" ]; then
    AWS_REGION="us-east-2"
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}ERROR: Unable to get AWS Account ID. Check AWS credentials.${NC}"
    exit 1
fi

# ECR Repository URLs
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-backend"
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-frontend"
USER_SERVICE_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-user-service"
ORDER_SERVICE_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-order-service"

echo -e "${BLUE}SweetDream Build and Deploy Script${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}Region: $AWS_REGION${NC}"
echo -e "${YELLOW}Image Tag: $IMAGE_TAG${NC}"
echo -e "${YELLOW}AWS Account: $AWS_ACCOUNT_ID${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}ERROR: Docker is not installed${NC}"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}ERROR: Docker is not running${NC}"
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}ERROR: AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}ERROR: AWS credentials not configured${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites met${NC}"
}

# Function to create ECR repository if it doesn't exist
create_ecr_repository() {
    local repo_name=$1
    
    echo -e "${YELLOW}Checking ECR repository: $repo_name${NC}"
    
    # Check if repository exists
    if aws ecr describe-repositories --repository-names "$repo_name" --region "$AWS_REGION" &> /dev/null; then
        echo -e "${GREEN}Repository $repo_name already exists${NC}"
    else
        echo -e "${YELLOW}Creating ECR repository: $repo_name${NC}"
        aws ecr create-repository \
            --repository-name "$repo_name" \
            --region "$AWS_REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256 > /dev/null
        
        # Set lifecycle policy to keep only 10 images
        aws ecr put-lifecycle-policy \
            --repository-name "$repo_name" \
            --region "$AWS_REGION" \
            --lifecycle-policy-text '{
                "rules": [
                    {
                        "rulePriority": 1,
                        "description": "Keep only 10 images",
                        "selection": {
                            "tagStatus": "any",
                            "countType": "imageCountMoreThan",
                            "countNumber": 10
                        },
                        "action": {
                            "type": "expire"
                        }
                    }
                ]
            }' > /dev/null
        
        echo -e "${GREEN}Repository $repo_name created successfully${NC}"
    fi
}

# Function to login to ECR
ecr_login() {
    echo -e "${YELLOW}Logging in to ECR...${NC}"
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    echo -e "${GREEN}ECR login successful${NC}"
}

# Function to build and push image
build_and_push() {
    local service_name=$1
    local service_path=$2
    local repo_url=$3
    local tag=$4
    
    echo -e "${BLUE}Building and pushing $service_name...${NC}"
    
    # Build image
    echo -e "${YELLOW}Building Docker image for $service_name...${NC}"
    docker build -t "${service_name}:${tag}" "$service_path"
    
    # Tag for ECR
    docker tag "${service_name}:${tag}" "${repo_url}:${tag}"
    docker tag "${service_name}:${tag}" "${repo_url}:latest"
    
    # Push to ECR
    echo -e "${YELLOW}Pushing $service_name to ECR...${NC}"
    docker push "${repo_url}:${tag}"
    docker push "${repo_url}:latest"
    
    echo -e "${GREEN}$service_name deployed successfully${NC}"
    echo ""
}

# Function to clean up local images
cleanup_images() {
    echo -e "${YELLOW}Cleaning up local Docker images...${NC}"
    
    # Remove local images to save space
    docker rmi "sweetdream-backend:${IMAGE_TAG}" 2>/dev/null || true
    docker rmi "sweetdream-frontend:${IMAGE_TAG}" 2>/dev/null || true
    docker rmi "sweetdream-user-service:${IMAGE_TAG}" 2>/dev/null || true
    docker rmi "sweetdream-order-service:${IMAGE_TAG}" 2>/dev/null || true
    
    # Clean up dangling images
    docker image prune -f > /dev/null 2>&1 || true
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Function to display deployment summary
show_summary() {
    echo -e "${GREEN}Deployment Summary:${NC}"
    echo -e "Environment: $ENVIRONMENT"
    echo -e "Region: $AWS_REGION"
    echo -e "Image Tag: $IMAGE_TAG"
    echo ""
    echo -e "${GREEN}ECR Repository URLs:${NC}"
    echo -e "Backend:      $BACKEND_REPO"
    echo -e "Frontend:     $FRONTEND_REPO"
    echo -e "User Service: $USER_SERVICE_REPO"
    echo -e "Order Service: $ORDER_SERVICE_REPO"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "1. Update ECS task definitions to use new images"
    echo -e "2. Deploy infrastructure: cd terraform/environments/$ENVIRONMENT && terraform apply"
    echo -e "3. Test application endpoints"
    echo -e "4. Monitor deployment in AWS Console"
}

# Main execution
main() {
    echo -e "${BLUE}Starting complete build and deployment process...${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Create ECR repositories
    echo -e "${BLUE}Setting up ECR repositories...${NC}"
    create_ecr_repository "sweetdream-backend"
    create_ecr_repository "sweetdream-frontend"
    create_ecr_repository "sweetdream-user-service"
    create_ecr_repository "sweetdream-order-service"
    echo ""
    
    # Login to ECR
    ecr_login
    echo ""
    
    # Build and push all services
    echo -e "${BLUE}Building and pushing Docker images...${NC}"
    build_and_push "sweetdream-backend" "./be" "$BACKEND_REPO" "$IMAGE_TAG"
    build_and_push "sweetdream-frontend" "./fe" "$FRONTEND_REPO" "$IMAGE_TAG"
    build_and_push "sweetdream-user-service" "./user-service" "$USER_SERVICE_REPO" "$IMAGE_TAG"
    build_and_push "sweetdream-order-service" "./order-service" "$ORDER_SERVICE_REPO" "$IMAGE_TAG"
    
    # Cleanup
    cleanup_images
    echo ""
    
    # Show summary
    show_summary
    
    echo -e "${GREEN}All services deployed to ECR successfully!${NC}"
}

# Show usage if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [ENVIRONMENT] [IMAGE_TAG]"
    echo ""
    echo "Arguments:"
    echo "  ENVIRONMENT  Target environment (dev|prod) [default: dev]"
    echo "  IMAGE_TAG    Docker image tag [default: latest]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy to dev with latest tag"
    echo "  $0 prod               # Deploy to prod with latest tag"
    echo "  $0 dev v1.2.3         # Deploy to dev with v1.2.3 tag"
    echo "  $0 prod release-1.0   # Deploy to prod with release-1.0 tag"
    exit 0
fi

# Run main function
main "$@"