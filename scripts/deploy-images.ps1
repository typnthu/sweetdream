# Deploy Images to ECR - Development Environment
param(
    [string]$ImageTag = "dev"
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

# Configuration
$AWS_REGION = "us-east-1"
$AWS_ACCOUNT_ID = "409964509537"
$ENVIRONMENT = "dev"

# ECR Repository URLs
$BACKEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-backend"
$FRONTEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-frontend"
$USER_SERVICE_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-user-service"
$ORDER_SERVICE_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-order-service"

Write-Host "${Green}🚀 Starting deployment to ECR repositories...${Reset}"

# Check if Docker is running
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

# Login to ECR
Write-Host "${Yellow}📝 Logging in to ECR...${Reset}"
try {
    $loginCommand = aws ecr get-login-password --region $AWS_REGION
    $loginCommand | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    Write-Host "${Green}✅ ECR login successful${Reset}"
} catch {
    Write-Host "${Red}❌ ECR login failed. Check AWS credentials${Reset}"
    exit 1
}

# Function to build and push image
function Build-And-Push {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [string]$RepoUrl,
        [string]$Tag = $ImageTag
    )
    
    Write-Host "${Yellow}🔨 Building ${ServiceName}...${Reset}"
    
    # Build image
    docker build -t "${ServiceName}:${Tag}" $ServicePath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${Red}❌ Failed to build ${ServiceName}${Reset}"
        exit 1
    }
    
    # Tag for ECR
    docker tag "${ServiceName}:${Tag}" "${RepoUrl}:${Tag}"
    docker tag "${ServiceName}:${Tag}" "${RepoUrl}:latest"
    
    # Push to ECR
    Write-Host "${Yellow}📤 Pushing ${ServiceName} to ECR...${Reset}"
    docker push "${RepoUrl}:${Tag}"
    docker push "${RepoUrl}:latest"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "${Green}✅ ${ServiceName} deployed successfully${Reset}"
    } else {
        Write-Host "${Red}❌ Failed to push ${ServiceName}${Reset}"
        exit 1
    }
}

# Deploy each service
Write-Host "${Yellow}🏗️  Building and pushing services...${Reset}"

# Backend Service
Build-And-Push -ServiceName "sweetdream-backend" -ServicePath "./be" -RepoUrl $BACKEND_REPO

# Frontend Service  
Build-And-Push -ServiceName "sweetdream-frontend" -ServicePath "./fe" -RepoUrl $FRONTEND_REPO

# User Service
Build-And-Push -ServiceName "sweetdream-user-service" -ServicePath "./user-service" -RepoUrl $USER_SERVICE_REPO

# Order Service
Build-And-Push -ServiceName "sweetdream-order-service" -ServicePath "./order-service" -RepoUrl $ORDER_SERVICE_REPO

Write-Host "${Green}🎉 All services deployed to ECR successfully!${Reset}"
Write-Host "${Green}📋 Next steps:${Reset}"
Write-Host "   1. Update ECS services to use new images"
Write-Host "   2. Test application at: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com"
Write-Host "   3. Monitor deployment in AWS Console"