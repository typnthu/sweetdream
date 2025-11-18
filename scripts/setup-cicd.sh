#!/bin/bash

# SweetDream - CI/CD Setup Script
# This script helps set up the CI/CD pipeline prerequisites

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

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        echo "Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    print_info "AWS CLI: ✓"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        echo "Install from: https://www.terraform.io/downloads"
        exit 1
    fi
    print_info "Terraform: ✓"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Install from: https://www.docker.com/get-started"
        exit 1
    fi
    print_info "Docker: ✓"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        exit 1
    fi
    print_info "Git: ✓"
    
    echo ""
}

# Setup AWS resources
setup_aws() {
    print_header "Setting Up AWS Resources"
    
    AWS_REGION="${AWS_REGION:-us-east-1}"
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    print_info "AWS Account ID: $AWS_ACCOUNT_ID"
    print_info "AWS Region: $AWS_REGION"
    echo ""
    
    # Create S3 bucket for Terraform state
    print_info "Creating S3 bucket for Terraform state..."
    BUCKET_NAME="sweetdream-terraform-state-${AWS_ACCOUNT_ID}"
    
    if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
        aws s3 mb "s3://${BUCKET_NAME}" --region $AWS_REGION
        aws s3api put-bucket-versioning \
            --bucket "${BUCKET_NAME}" \
            --versioning-configuration Status=Enabled
        print_info "Created S3 bucket: ${BUCKET_NAME}"
    else
        print_info "S3 bucket already exists: ${BUCKET_NAME}"
    fi
    
    # Create ECR repositories
    print_info "Creating ECR repositories..."
    
    for REPO in sweetdream-backend sweetdream-frontend; do
        if ! aws ecr describe-repositories --repository-names $REPO --region $AWS_REGION > /dev/null 2>&1; then
            aws ecr create-repository \
                --repository-name $REPO \
                --region $AWS_REGION \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256
            print_info "Created ECR repository: $REPO"
        else
            print_info "ECR repository already exists: $REPO"
        fi
    done
    
    echo ""
}

# Setup Terraform backend
setup_terraform() {
    print_header "Configuring Terraform Backend"
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    BUCKET_NAME="sweetdream-terraform-state-${AWS_ACCOUNT_ID}"
    
    # Update terraform.tf with backend configuration
    print_info "Creating terraform/backend.tf..."
    
    # Create the backend.tf file
    cat > terraform/backend.tf <<'BACKEND_EOF'
terraform {
  backend "s3" {
    bucket = "BUCKET_NAME_PLACEHOLDER"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
BACKEND_EOF
    
    # Replace the placeholder with actual bucket name
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/BUCKET_NAME_PLACEHOLDER/${BUCKET_NAME}/g" terraform/backend.tf
    else
        # Linux
        sed -i "s/BUCKET_NAME_PLACEHOLDER/${BUCKET_NAME}/g" terraform/backend.tf
    fi
    
    print_info "Created terraform/backend.tf"
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform/terraform.tfvars ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f terraform/terraform.tfvars.example ]; then
            cp terraform/terraform.tfvars.example terraform/terraform.tfvars
            print_info "Created terraform/terraform.tfvars"
            print_warning "Please edit terraform/terraform.tfvars with your values!"
        else
            print_warning "terraform.tfvars.example not found. Skipping..."
        fi
    fi
    
    echo ""
}

# Display GitHub secrets needed
display_github_secrets() {
    print_header "GitHub Secrets Configuration"
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    echo "Add these secrets to your GitHub repository:"
    echo "(Settings → Secrets and variables → Actions → New repository secret)"
    echo ""
    echo "1. AWS_ACCESS_KEY_ID"
    echo "   Value: <your-aws-access-key-id>"
    echo ""
    echo "2. AWS_SECRET_ACCESS_KEY"
    echo "   Value: <your-aws-secret-access-key>"
    echo ""
    echo "3. BACKEND_API_URL"
    echo "   Value: http://backend.sweetdream.local:3001"
    echo ""
    
    print_warning "Create a dedicated IAM user for GitHub Actions with these permissions:"
    echo "  - AmazonECS_FullAccess"
    echo "  - AmazonEC2ContainerRegistryFullAccess"
    echo "  - AmazonRDSFullAccess"
    echo "  - AmazonVPCFullAccess"
    echo "  - AmazonS3FullAccess"
    echo "  - CloudWatchLogsFullAccess"
    echo ""
}

# Display next steps
display_next_steps() {
    print_header "Next Steps"
    
    echo "1. Configure GitHub Secrets (see above)"
    echo ""
    echo "2. Create GitHub Environments:"
    echo "   - Go to Settings → Environments"
    echo "   - Create 'development' environment"
    echo "   - Create 'production' environment"
    echo ""
    echo "3. Edit terraform/terraform.tfvars:"
    echo "   - Set db_password"
    echo "   - Review other variables"
    echo ""
    echo "4. Initialize Terraform:"
    echo "   cd terraform"
    echo "   terraform init"
    echo "   terraform plan"
    echo ""
    echo "5. Deploy infrastructure (choose one):"
    echo "   a) Manually:"
    echo "      terraform apply"
    echo ""
    echo "   b) Via GitHub Actions:"
    echo "      - Go to Actions → Infrastructure Deployment"
    echo "      - Run workflow with action: apply"
    echo ""
    echo "6. Push code to dev branch:"
    echo "   git checkout -b dev"
    echo "   git push origin dev"
    echo ""
    echo "7. Monitor deployment:"
    echo "   - Go to Actions tab in GitHub"
    echo "   - Watch the deployment progress"
    echo ""
    
    print_info "Setup complete! Follow the steps above to deploy."
}

# Main execution
main() {
    print_header "SweetDream CI/CD Setup"
    
    check_prerequisites
    setup_aws
    setup_terraform
    display_github_secrets
    display_next_steps
}

main
