#!/bin/bash

# SweetDream - CI/CD Validation Script
# This script validates the CI/CD setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

ERRORS=0

# Check AWS resources
check_aws() {
    print_header "Checking AWS Resources"
    
    AWS_REGION="${AWS_REGION:-us-east-1}"
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        print_fail "AWS credentials not configured"
        ((ERRORS++))
        return
    fi
    print_success "AWS credentials configured (Account: $AWS_ACCOUNT_ID)"
    
    # Check ECR repositories
    for REPO in sweetdream-backend sweetdream-frontend; do
        if aws ecr describe-repositories --repository-names $REPO --region $AWS_REGION > /dev/null 2>&1; then
            print_success "ECR repository exists: $REPO"
        else
            print_fail "ECR repository missing: $REPO"
            ((ERRORS++))
        fi
    done
    
    # Check S3 bucket for Terraform state
    BUCKET_NAME="sweetdream-terraform-state-${AWS_ACCOUNT_ID}"
    if aws s3 ls "s3://${BUCKET_NAME}" > /dev/null 2>&1; then
        print_success "S3 bucket exists: ${BUCKET_NAME}"
    else
        print_warning "S3 bucket missing: ${BUCKET_NAME} (optional for local Terraform)"
    fi
    
    echo ""
}

# Check Terraform configuration
check_terraform() {
    print_header "Checking Terraform Configuration"
    
    if [ ! -d "terraform" ]; then
        print_fail "terraform directory not found"
        ((ERRORS++))
        return
    fi
    print_success "Terraform directory exists"
    
    if [ -f "terraform/terraform.tfvars" ]; then
        print_success "terraform.tfvars exists"
    else
        print_warning "terraform.tfvars not found (will use defaults)"
    fi
    
    cd terraform
    
    # Check Terraform format
    if terraform fmt -check -recursive > /dev/null 2>&1; then
        print_success "Terraform files are formatted correctly"
    else
        print_warning "Terraform files need formatting (run: terraform fmt -recursive)"
    fi
    
    # Check Terraform validation
    if [ -d ".terraform" ]; then
        if terraform validate > /dev/null 2>&1; then
            print_success "Terraform configuration is valid"
        else
            print_fail "Terraform validation failed"
            ((ERRORS++))
        fi
    else
        print_warning "Terraform not initialized (run: terraform init)"
    fi
    
    cd ..
    echo ""
}

# Check GitHub Actions workflows
check_workflows() {
    print_header "Checking GitHub Actions Workflows"
    
    WORKFLOWS=(
        "infrastructure.yml"
        "backend-ci.yml"
        "frontend-ci.yml"
        "deploy.yml"
        "integration-tests.yml"
        "database-migration.yml"
    )
    
    for WORKFLOW in "${WORKFLOWS[@]}"; do
        if [ -f ".github/workflows/$WORKFLOW" ]; then
            print_success "Workflow exists: $WORKFLOW"
        else
            print_fail "Workflow missing: $WORKFLOW"
            ((ERRORS++))
        fi
    done
    
    echo ""
}

# Check Docker configuration
check_docker() {
    print_header "Checking Docker Configuration"
    
    # Check backend Dockerfile
    if [ -f "be/Dockerfile" ]; then
        print_success "Backend Dockerfile exists"
        
        # Try to build (dry run)
        if docker build -t test-backend:latest be/ --dry-run > /dev/null 2>&1 || true; then
            print_success "Backend Dockerfile syntax is valid"
        fi
    else
        print_fail "Backend Dockerfile missing"
        ((ERRORS++))
    fi
    
    # Check frontend Dockerfile
    if [ -f "fe/Dockerfile" ]; then
        print_success "Frontend Dockerfile exists"
        
        # Try to build (dry run)
        if docker build -t test-frontend:latest fe/ --dry-run > /dev/null 2>&1 || true; then
            print_success "Frontend Dockerfile syntax is valid"
        fi
    else
        print_fail "Frontend Dockerfile missing"
        ((ERRORS++))
    fi
    
    echo ""
}

# Check application configuration
check_app_config() {
    print_header "Checking Application Configuration"
    
    # Check backend
    if [ -f "be/package.json" ]; then
        print_success "Backend package.json exists"
        
        # Check required scripts
        if grep -q '"build"' be/package.json; then
            print_success "Backend has build script"
        else
            print_fail "Backend missing build script"
            ((ERRORS++))
        fi
        
        if grep -q '"migrate"' be/package.json; then
            print_success "Backend has migrate script"
        else
            print_fail "Backend missing migrate script"
            ((ERRORS++))
        fi
    else
        print_fail "Backend package.json missing"
        ((ERRORS++))
    fi
    
    # Check frontend
    if [ -f "fe/package.json" ]; then
        print_success "Frontend package.json exists"
        
        # Check required scripts
        if grep -q '"build"' fe/package.json; then
            print_success "Frontend has build script"
        else
            print_fail "Frontend missing build script"
            ((ERRORS++))
        fi
    else
        print_fail "Frontend package.json missing"
        ((ERRORS++))
    fi
    
    # Check Prisma schema
    if [ -f "be/prisma/schema.prisma" ]; then
        print_success "Prisma schema exists"
    else
        print_fail "Prisma schema missing"
        ((ERRORS++))
    fi
    
    echo ""
}

# Check documentation
check_docs() {
    print_header "Checking Documentation"
    
    DOCS=(
        "README.md"
        "CICD_GUIDE.md"
        "terraform/README.md"
        "be/README.md"
    )
    
    for DOC in "${DOCS[@]}"; do
        if [ -f "$DOC" ]; then
            print_success "Documentation exists: $DOC"
        else
            print_warning "Documentation missing: $DOC"
        fi
    done
    
    echo ""
}

# Display summary
display_summary() {
    print_header "Validation Summary"
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}All checks passed! ✓${NC}"
        echo ""
        echo "Your CI/CD pipeline is ready to use."
        echo ""
        echo "Next steps:"
        echo "1. Configure GitHub Secrets"
        echo "2. Push to dev branch to trigger deployment"
        echo "3. Monitor deployment in GitHub Actions"
    else
        echo -e "${RED}Found $ERRORS error(s) ✗${NC}"
        echo ""
        echo "Please fix the errors above before deploying."
    fi
    
    echo ""
}

# Main execution
main() {
    print_header "SweetDream CI/CD Validation"
    
    check_aws
    check_terraform
    check_workflows
    check_docker
    check_app_config
    check_docs
    display_summary
    
    exit $ERRORS
}

main
