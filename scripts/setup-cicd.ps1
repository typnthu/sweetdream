# SweetDream - CI/CD Setup Script (PowerShell)
# This script helps set up the CI/CD pipeline prerequisites

# Colors
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check AWS CLI
    if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI is not installed"
        Write-Host "Install from: https://aws.amazon.com/cli/"
        exit 1
    }
    Write-Info "AWS CLI: ✓"
    
    # Check Terraform
    if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "Terraform is not installed"
        Write-Host "Install from: https://www.terraform.io/downloads"
        exit 1
    }
    Write-Info "Terraform: ✓"
    
    # Check Docker
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed"
        Write-Host "Install from: https://www.docker.com/get-started"
        exit 1
    }
    Write-Info "Docker: ✓"
    
    # Check Git
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed"
        exit 1
    }
    Write-Info "Git: ✓"
}

# Setup AWS resources
function Setup-AWS {
    Write-Header "Setting Up AWS Resources"
    
    $AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
    $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
    
    if (!$AWS_ACCOUNT_ID) {
        Write-Error "Failed to get AWS Account ID. Please configure AWS CLI."
        exit 1
    }
    
    Write-Info "AWS Account ID: $AWS_ACCOUNT_ID"
    Write-Info "AWS Region: $AWS_REGION"
    Write-Host ""
    
    # Create S3 bucket for Terraform state
    Write-Info "Creating S3 bucket for Terraform state..."
    $BUCKET_NAME = "sweetdream-terraform-state-$AWS_ACCOUNT_ID"
    
    $bucketExists = aws s3 ls "s3://$BUCKET_NAME" 2>&1
    if ($LASTEXITCODE -ne 0) {
        aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION
        aws s3api put-bucket-versioning `
            --bucket "$BUCKET_NAME" `
            --versioning-configuration Status=Enabled
        Write-Info "Created S3 bucket: $BUCKET_NAME"
    } else {
        Write-Info "S3 bucket already exists: $BUCKET_NAME"
    }
    
    # Create ECR repositories
    Write-Info "Creating ECR repositories..."
    
    $repos = @("sweetdream-backend", "sweetdream-frontend")
    foreach ($REPO in $repos) {
        $repoExists = aws ecr describe-repositories --repository-names $REPO --region $AWS_REGION 2>&1
        if ($LASTEXITCODE -ne 0) {
            aws ecr create-repository `
                --repository-name $REPO `
                --region $AWS_REGION `
                --image-scanning-configuration scanOnPush=true `
                --encryption-configuration encryptionType=AES256
            Write-Info "Created ECR repository: $REPO"
        } else {
            Write-Info "ECR repository already exists: $REPO"
        }
    }
    
    Write-Host ""
    return @{
        AccountId = $AWS_ACCOUNT_ID
        BucketName = $BUCKET_NAME
        Region = $AWS_REGION
    }
}

# Setup Terraform backend
function Setup-Terraform {
    param($AwsInfo)
    
    Write-Header "Configuring Terraform Backend"
    
    $BUCKET_NAME = $AwsInfo.BucketName
    
    # Create backend.tf
    $backendContent = @"
terraform {
  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
"@
    
    $backendContent | Out-File -FilePath "terraform/backend.tf" -Encoding UTF8
    Write-Info "Created terraform/backend.tf"
    
    # Create terraform.tfvars if it doesn't exist
    if (!(Test-Path "terraform/terraform.tfvars")) {
        Write-Warning "terraform.tfvars not found. Creating from example..."
        Copy-Item "terraform/terraform.tfvars.example" "terraform/terraform.tfvars"
        Write-Info "Created terraform/terraform.tfvars"
        Write-Warning "Please edit terraform/terraform.tfvars with your values!"
    }
    
    Write-Host ""
}

# Display GitHub secrets needed
function Display-GitHubSecrets {
    param($AwsInfo)
    
    Write-Header "GitHub Secrets Configuration"
    
    Write-Host "Add these secrets to your GitHub repository:"
    Write-Host "(Settings → Secrets and variables → Actions → New repository secret)"
    Write-Host ""
    Write-Host "1. AWS_ACCESS_KEY_ID"
    Write-Host "   Value: <your-aws-access-key-id>"
    Write-Host ""
    Write-Host "2. AWS_SECRET_ACCESS_KEY"
    Write-Host "   Value: <your-aws-secret-access-key>"
    Write-Host ""
    Write-Host "3. DB_PASSWORD"
    Write-Host "   Value: SecurePassword123! (or your chosen password)"
    Write-Host ""
    Write-Host "4. BACKEND_API_URL"
    Write-Host "   Value: http://backend.sweetdream.local:3001"
    Write-Host ""
    
    Write-Warning "Create a dedicated IAM user for GitHub Actions with these permissions:"
    Write-Host "  - AmazonECS_FullAccess"
    Write-Host "  - AmazonEC2ContainerRegistryFullAccess"
    Write-Host "  - AmazonRDSFullAccess"
    Write-Host "  - AmazonVPCFullAccess"
    Write-Host "  - AmazonS3FullAccess"
    Write-Host "  - CloudWatchLogsFullAccess"
    Write-Host ""
}

# Display next steps
function Display-NextSteps {
    Write-Header "Next Steps"
    
    Write-Host "1. Configure GitHub Secrets (see above)"
    Write-Host ""
    Write-Host "2. Create GitHub Environments:"
    Write-Host "   - Go to Settings → Environments"
    Write-Host "   - Create 'development' environment"
    Write-Host "   - Create 'production' environment"
    Write-Host ""
    Write-Host "3. Edit terraform/terraform.tfvars:"
    Write-Host "   - Set db_password"
    Write-Host "   - Review other variables"
    Write-Host ""
    Write-Host "4. Initialize Terraform:"
    Write-Host "   cd terraform"
    Write-Host "   terraform init"
    Write-Host "   terraform plan"
    Write-Host ""
    Write-Host "5. Deploy infrastructure (choose one):"
    Write-Host "   a) Manually:"
    Write-Host "      terraform apply"
    Write-Host ""
    Write-Host "   b) Via GitHub Actions:"
    Write-Host "      - Go to Actions → Infrastructure Deployment"
    Write-Host "      - Run workflow with action: apply"
    Write-Host ""
    Write-Host "6. Push code to dev branch:"
    Write-Host "   git checkout -b dev"
    Write-Host "   git push origin dev"
    Write-Host ""
    Write-Host "7. Monitor deployment:"
    Write-Host "   - Go to Actions tab in GitHub"
    Write-Host "   - Watch the deployment progress"
    Write-Host ""
    
    Write-Info "Setup complete! Follow the steps above to deploy."
}

# Main execution
function Main {
    Write-Header "SweetDream CI/CD Setup"
    
    try {
        Check-Prerequisites
        $awsInfo = Setup-AWS
        Setup-Terraform -AwsInfo $awsInfo
        Display-GitHubSecrets -AwsInfo $awsInfo
        Display-NextSteps
    }
    catch {
        Write-Error "An error occurred: $_"
        exit 1
    }
}

# Run main
Main
