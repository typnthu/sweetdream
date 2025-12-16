# Complete Build and Deploy Script for SweetDream
# This script creates ECR repositories, builds Docker images, and pushes them to ECR

param(
    [string]$Environment = "dev",
    [string]$ImageTag = "latest"
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

# Configuration
$AWS_REGION = "us-east-1"

# Override region for production
if ($Environment -eq "prod") {
    $AWS_REGION = "us-west-2"
}

# Get AWS Account ID
try {
    $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text 2>$null)
    if (-not $AWS_ACCOUNT_ID) {
        throw "Unable to get AWS Account ID"
    }
} catch {
    Write-Host "${Red}ERROR: Unable to get AWS Account ID. Check AWS credentials.${Reset}"
    exit 1
}

# ECR Repository URLs
$BACKEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-backend"
$FRONTEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-frontend"
$USER_SERVICE_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-user-service"
$ORDER_SERVICE_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-order-service"

Write-Host "${Blue}SweetDream Build and Deploy Script${Reset}"
Write-Host "${Yellow}Environment: $Environment${Reset}"
Write-Host "${Yellow}Region: $AWS_REGION${Reset}"
Write-Host "${Yellow}Image Tag: $ImageTag${Reset}"
Write-Host "${Yellow}AWS Account: $AWS_ACCOUNT_ID${Reset}"
Write-Host ""

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "${Blue}Checking prerequisites...${Reset}"
    
    # Check Docker
    try {
        docker version | Out-Null
        Write-Host "${Green}Docker is available${Reset}"
    } catch {
        Write-Host "${Red}ERROR: Docker is not running. Please start Docker Desktop${Reset}"
        exit 1
    }
    
    # Check AWS CLI
    try {
        aws --version | Out-Null
        Write-Host "${Green}AWS CLI is available${Reset}"
    } catch {
        Write-Host "${Red}ERROR: AWS CLI not found. Please install AWS CLI${Reset}"
        exit 1
    }
    
    # Check AWS credentials
    try {
        aws sts get-caller-identity | Out-Null
        Write-Host "${Green}AWS credentials configured${Reset}"
    } catch {
        Write-Host "${Red}ERROR: AWS credentials not configured${Reset}"
        exit 1
    }
    
    Write-Host "${Green}All prerequisites met${Reset}"
}

# Function to create ECR repository if it doesn't exist
function New-ECRRepository {
    param([string]$RepoName)
    
    Write-Host "${Yellow}Checking ECR repository: $RepoName${Reset}"
    
    # Check if repository exists
    $repoExists = $false
    try {
        aws ecr describe-repositories --repository-names $RepoName --region $AWS_REGION 2>$null | Out-Null
        $repoExists = $true
    } catch {
        $repoExists = $false
    }
    
    if ($repoExists) {
        Write-Host "${Green}Repository $RepoName already exists${Reset}"
    } else {
        Write-Host "${Yellow}Creating ECR repository: $RepoName${Reset}"
        
        # Create repository
        aws ecr create-repository `
            --repository-name $RepoName `
            --region $AWS_REGION `
            --image-scanning-configuration scanOnPush=true `
            --encryption-configuration encryptionType=AES256 | Out-Null
        
        # Set lifecycle policy to keep only 10 images
        $lifecyclePolicy = @'
{
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
}
'@
        
        aws ecr put-lifecycle-policy `
            --repository-name $RepoName `
            --region $AWS_REGION `
            --lifecycle-policy-text $lifecyclePolicy | Out-Null
        
        Write-Host "${Green}Repository $RepoName created successfully${Reset}"
    }
}

# Function to login to ECR
function Connect-ECR {
    Write-Host "${Yellow}Logging in to ECR...${Reset}"
    try {
        $loginCommand = aws ecr get-login-password --region $AWS_REGION
        $loginCommand | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        Write-Host "${Green}ECR login successful${Reset}"
    } catch {
        Write-Host "${Red}ECR login failed. Check AWS credentials${Reset}"
        exit 1
    }
}

# Function to build and push image
function Build-And-Push {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [string]$RepoUrl,
        [string]$Tag
    )
    
    Write-Host "${Blue}Building and pushing $ServiceName...${Reset}"
    
    # Build image
    Write-Host "${Yellow}Building Docker image for $ServiceName...${Reset}"
    docker build -t "${ServiceName}:${Tag}" $ServicePath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${Red}Failed to build $ServiceName${Reset}"
        exit 1
    }
    
    # Tag for ECR
    docker tag "${ServiceName}:${Tag}" "${RepoUrl}:${Tag}"
    docker tag "${ServiceName}:${Tag}" "${RepoUrl}:latest"
    
    # Push to ECR
    Write-Host "${Yellow}Pushing $ServiceName to ECR...${Reset}"
    docker push "${RepoUrl}:${Tag}"
    docker push "${RepoUrl}:latest"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "${Green}$ServiceName deployed successfully${Reset}"
        Write-Host ""
    } else {
        Write-Host "${Red}Failed to push $ServiceName${Reset}"
        exit 1
    }
}

# Function to clean up local images
function Remove-LocalImages {
    Write-Host "${Yellow}Cleaning up local Docker images...${Reset}"
    
    # Remove local images to save space
    try {
        docker rmi "sweetdream-backend:${ImageTag}" 2>$null
        docker rmi "sweetdream-frontend:${ImageTag}" 2>$null
        docker rmi "sweetdream-user-service:${ImageTag}" 2>$null
        docker rmi "sweetdream-order-service:${ImageTag}" 2>$null
    } catch {
        # Ignore errors if images don't exist
    }
    
    # Clean up dangling images
    try {
        docker image prune -f | Out-Null
    } catch {
        # Ignore errors
    }
    
    Write-Host "${Green}Cleanup completed${Reset}"
}

# Function to display deployment summary
function Show-Summary {
    Write-Host "${Green}Deployment Summary:${Reset}"
    Write-Host "Environment: $Environment"
    Write-Host "Region: $AWS_REGION"
    Write-Host "Image Tag: $ImageTag"
    Write-Host ""
    Write-Host "${Green}ECR Repository URLs:${Reset}"
    Write-Host "Backend:      $BACKEND_REPO"
    Write-Host "Frontend:     $FRONTEND_REPO"
    Write-Host "User Service: $USER_SERVICE_REPO"
    Write-Host "Order Service: $ORDER_SERVICE_REPO"
    Write-Host ""
    Write-Host "${Green}Next Steps:${Reset}"
    Write-Host "1. Update ECS task definitions to use new images"
    Write-Host "2. Deploy infrastructure: cd terraform/environments/$Environment && terraform apply"
    Write-Host "3. Test application endpoints"
    Write-Host "4. Monitor deployment in AWS Console"
}

# Show usage if help requested
if ($Environment -eq "--help" -or $Environment -eq "-h") {
    Write-Host "Usage: .\build-and-deploy.ps1 [-Environment <env>] [-ImageTag <tag>]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Environment  Target environment (dev|prod) [default: dev]"
    Write-Host "  -ImageTag     Docker image tag [default: latest]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build-and-deploy.ps1                           # Deploy to dev with latest tag"
    Write-Host "  .\build-and-deploy.ps1 -Environment prod         # Deploy to prod with latest tag"
    Write-Host "  .\build-and-deploy.ps1 -Environment dev -ImageTag v1.2.3    # Deploy to dev with v1.2.3 tag"
    Write-Host "  .\build-and-deploy.ps1 -Environment prod -ImageTag release-1.0  # Deploy to prod with release-1.0 tag"
    exit 0
}

# Main execution
Write-Host "${Blue}Starting complete build and deployment process...${Reset}"
Write-Host ""

# Check prerequisites
Test-Prerequisites
Write-Host ""

# Create ECR repositories
Write-Host "${Blue}Setting up ECR repositories...${Reset}"
New-ECRRepository -RepoName "sweetdream-backend"
New-ECRRepository -RepoName "sweetdream-frontend"
New-ECRRepository -RepoName "sweetdream-user-service"
New-ECRRepository -RepoName "sweetdream-order-service"
Write-Host ""

# Login to ECR
Connect-ECR
Write-Host ""

# Build and push all services
Write-Host "${Blue}Building and pushing Docker images...${Reset}"
Build-And-Push -ServiceName "sweetdream-backend" -ServicePath "./be" -RepoUrl $BACKEND_REPO -Tag $ImageTag
Build-And-Push -ServiceName "sweetdream-frontend" -ServicePath "./fe" -RepoUrl $FRONTEND_REPO -Tag $ImageTag
Build-And-Push -ServiceName "sweetdream-user-service" -ServicePath "./user-service" -RepoUrl $USER_SERVICE_REPO -Tag $ImageTag
Build-And-Push -ServiceName "sweetdream-order-service" -ServicePath "./order-service" -RepoUrl $ORDER_SERVICE_REPO -Tag $ImageTag

# Cleanup
Remove-LocalImages
Write-Host ""

# Show summary
Show-Summary

Write-Host "${Green}All services deployed to ECR successfully!${Reset}"