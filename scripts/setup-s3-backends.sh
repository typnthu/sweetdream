#!/bin/bash
# Setup S3 backends for multi-environment deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_s3_bucket() {
    local bucket_name=$1
    local region=$2
    
    log_info "Creating S3 bucket: $bucket_name in $region"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$bucket_name" --region "$region" 2>/dev/null; then
        log_warn "Bucket $bucket_name already exists"
        return 0
    fi
    
    # Create bucket
    if [ "$region" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$bucket_name" --region "$region"
    else
        aws s3api create-bucket --bucket "$bucket_name" --region "$region" \
            --create-bucket-configuration LocationConstraint="$region"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
    aws s3api put-bucket-encryption --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Block public access
    aws s3api put-public-access-block --bucket "$bucket_name" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    log_info "S3 bucket $bucket_name created successfully"
}

main() {
    log_info "Setting up S3 backends for multi-environment deployment"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    # Create S3 buckets for Terraform state
    create_s3_bucket "sweetdream-terraform-state-dev" "us-east-1"
    create_s3_bucket "sweetdream-terraform-state-prod" "us-west-2"
    
    log_info "All S3 backends created successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Deploy development: ./scripts/deploy-dev.sh"
    log_info "2. Deploy production: ./scripts/deploy-prod.sh"
}

main "$@"