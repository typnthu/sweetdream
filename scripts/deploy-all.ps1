# Complete deployment script for SweetDream application
param(
    [string]$ImageTag = "dev",
    [string]$DeployMethod = "manual"  # manual or codedeploy
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

Write-Host "${Blue}🍰 SweetDream Application Deployment${Reset}"
Write-Host "${Blue}====================================${Reset}"

Write-Host "${Green}📋 Deployment Configuration:${Reset}"
Write-Host "   Image Tag: $ImageTag"
Write-Host "   Deploy Method: $DeployMethod"
Write-Host "   Environment: Development (us-east-1)"
Write-Host ""

# Check prerequisites
Write-Host "${Yellow}🔍 Checking prerequisites...${Reset}"

# Check Docker
try {
    docker version | Out-Null
    Write-Host "${Green}✅ Docker is running${Reset}"
} catch {
    Write-Host "${Red}❌ Docker is not running. Please start Docker Desktop${Reset}"
    exit 1
}

# Check AWS CLI
try {
    aws --version | Out-Null
    Write-Host "${Green}✅ AWS CLI is available${Reset}"
} catch {
    Write-Host "${Red}❌ AWS CLI not found. Please install AWS CLI${Reset}"
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity --query 'Account' --output text
    Write-Host "${Green}✅ AWS credentials configured (Account: $identity)${Reset}"
} catch {
    Write-Host "${Red}❌ AWS credentials not configured. Run 'aws configure'${Reset}"
    exit 1
}

Write-Host ""

# Step 1: Build and push images
Write-Host "${Yellow}Step 1: Building and pushing Docker images...${Reset}"
try {
    & ".\scripts\deploy-images.ps1" -ImageTag $ImageTag
    if ($LASTEXITCODE -ne 0) {
        throw "Image deployment failed"
    }
} catch {
    Write-Host "${Red}❌ Failed to build and push images${Reset}"
    exit 1
}

Write-Host ""

# Step 2: Update ECS services
Write-Host "${Yellow}Step 2: Updating ECS services...${Reset}"
try {
    & ".\scripts\update-ecs-services.ps1"
    if ($LASTEXITCODE -ne 0) {
        throw "ECS service update failed"
    }
} catch {
    Write-Host "${Red}❌ Failed to update ECS services${Reset}"
    exit 1
}

Write-Host ""
Write-Host "${Green}🎉 Deployment completed successfully!${Reset}"
Write-Host "${Green}📋 Application Details:${Reset}"
Write-Host "   🌐 URL: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com"
Write-Host "   🔍 Backend API: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com/api"
Write-Host "   📊 AWS Console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/sweetdream-dev-cluster"
Write-Host ""
Write-Host "${Yellow}🔧 Useful commands:${Reset}"
Write-Host "   Check service status: aws ecs describe-services --region us-east-1 --cluster sweetdream-dev-cluster --services sweetdream-dev-service-frontend"
Write-Host "   View logs: aws logs tail /ecs/sweetdream-frontend --region us-east-1 --follow"
Write-Host "   Scale service: aws ecs update-service --region us-east-1 --cluster sweetdream-dev-cluster --service sweetdream-dev-service-frontend --desired-count 3"