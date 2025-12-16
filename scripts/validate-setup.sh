#!/bin/bash

# Validation script to check if all prerequisites are met
# Run this before attempting deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}SweetDream Deployment Validation${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check Docker
echo -e "${YELLOW}Checking Docker...${NC}"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo -e "${GREEN}[OK] Docker is installed and running${NC}"
        DOCKER_VERSION=$(docker --version)
        echo -e "  Version: ${DOCKER_VERSION}"
    else
        echo -e "${RED}[ERROR] Docker is installed but not running${NC}"
        echo -e "  Please start Docker Desktop"
        exit 1
    fi
else
    echo -e "${RED}[ERROR] Docker is not installed${NC}"
    echo -e "  Please install Docker Desktop"
    exit 1
fi
echo ""

# Check AWS CLI
echo -e "${YELLOW}Checking AWS CLI...${NC}"
if command -v aws &> /dev/null; then
    echo -e "${GREEN}[OK] AWS CLI is installed${NC}"
    AWS_VERSION=$(aws --version)
    echo -e "  Version: ${AWS_VERSION}"
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        echo -e "${GREEN}[OK] AWS credentials are configured${NC}"
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_REGION=$(aws configure get region || echo "not set")
        echo -e "  Account ID: ${AWS_ACCOUNT}"
        echo -e "  Default Region: ${AWS_REGION}"
    else
        echo -e "${RED}[ERROR] AWS credentials not configured${NC}"
        echo -e "  Run: aws configure"
        exit 1
    fi
else
    echo -e "${RED}[ERROR] AWS CLI is not installed${NC}"
    echo -e "  Please install AWS CLI v2"
    exit 1
fi
echo ""

# Check Terraform
echo -e "${YELLOW}Checking Terraform...${NC}"
if command -v terraform &> /dev/null; then
    echo -e "${GREEN}[OK] Terraform is installed${NC}"
    TERRAFORM_VERSION=$(terraform --version | head -n1)
    echo -e "  Version: ${TERRAFORM_VERSION}"
else
    echo -e "${YELLOW}! Terraform is not installed${NC}"
    echo -e "  Install Terraform if you plan to deploy infrastructure"
fi
echo ""

# Check Git
echo -e "${YELLOW}Checking Git...${NC}"
if command -v git &> /dev/null; then
    echo -e "${GREEN}[OK] Git is installed${NC}"
    GIT_VERSION=$(git --version)
    echo -e "  Version: ${GIT_VERSION}"
else
    echo -e "${YELLOW}! Git is not installed${NC}"
    echo -e "  Install Git for version control"
fi
echo ""

# Check script permissions
echo -e "${YELLOW}Checking script permissions...${NC}"
SCRIPTS_DIR="$(dirname "$0")"
EXECUTABLE_SCRIPTS=(
    "build-and-deploy.sh"
    "deploy-images.sh"
    "deploy-dev.sh"
    "deploy-prod.sh"
    "setup-s3-backends.sh"
    "make-executable.sh"
)

ALL_EXECUTABLE=true
for script in "${EXECUTABLE_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        if [ -x "$SCRIPTS_DIR/$script" ]; then
            echo -e "${GREEN}[OK] $script is executable${NC}"
        else
            echo -e "${YELLOW}! $script is not executable${NC}"
            ALL_EXECUTABLE=false
        fi
    else
        echo -e "${RED}[ERROR] $script not found${NC}"
    fi
done

if [ "$ALL_EXECUTABLE" = false ]; then
    echo -e "${YELLOW}  Run: ./scripts/make-executable.sh${NC}"
fi
echo ""

# Check project structure
echo -e "${YELLOW}Checking project structure...${NC}"
REQUIRED_DIRS=("be" "fe" "user-service" "order-service" "terraform")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}[OK] $dir directory exists${NC}"
    else
        echo -e "${RED}[ERROR] $dir directory missing${NC}"
        exit 1
    fi
done
echo ""

# Check Dockerfiles
echo -e "${YELLOW}Checking Dockerfiles...${NC}"
DOCKERFILES=("be/Dockerfile" "fe/Dockerfile" "user-service/Dockerfile" "order-service/Dockerfile")
for dockerfile in "${DOCKERFILES[@]}"; do
    if [ -f "$dockerfile" ]; then
        echo -e "${GREEN}[OK] $dockerfile exists${NC}"
    else
        echo -e "${RED}[ERROR] $dockerfile missing${NC}"
        exit 1
    fi
done
echo ""

# Summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Validation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${GREEN}Your system is ready for deployment.${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run complete deployment:"
echo -e "   ${YELLOW}./scripts/build-and-deploy.sh dev latest${NC}"
echo -e ""
echo -e "2. Or see detailed guide:"
echo -e "   ${YELLOW}cat scripts/DEPLOYMENT_GUIDE.md${NC}"
echo ""