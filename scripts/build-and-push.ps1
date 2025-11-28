# Build and Push Docker Images to ECR
# Usage: .\scripts\build-and-push.ps1 [-Service <service-name>] [-Region <aws-region>]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "backend", "frontend", "order-service", "user-service")]
    [string]$Service = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

# Get AWS account ID
Write-Host "Getting AWS account ID..." -ForegroundColor Cyan
$AccountId = aws sts get-caller-identity --query Account --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get AWS account ID. Make sure AWS CLI is configured." -ForegroundColor Red
    exit 1
}

$EcrRegistry = "$AccountId.dkr.ecr.$Region.amazonaws.com"

Write-Host "AWS Account: $AccountId" -ForegroundColor Green
Write-Host "ECR Registry: $EcrRegistry" -ForegroundColor Green
Write-Host "Tag: $Tag" -ForegroundColor Green

# Login to ECR
Write-Host "`nLogging in to ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $EcrRegistry

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to login to ECR" -ForegroundColor Red
    exit 1
}

Write-Host "Logged in to ECR" -ForegroundColor Green

# Function to build and push image
function Build-And-Push {
    param(
        [string]$ServiceName,
        [string]$Path,
        [string]$ImageName
    )
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Building $ServiceName..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $FullImageName = "$EcrRegistry/$ImageName"
    
    # Ensure repository exists
    Write-Host "Ensuring ECR repository exists..." -ForegroundColor Gray
    aws ecr describe-repositories --repository-names $ImageName --region $Region 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating ECR repository: $ImageName" -ForegroundColor Yellow
        aws ecr create-repository `
            --repository-name $ImageName `
            --image-scanning-configuration scanOnPush=true `
            --encryption-configuration encryptionType=AES256 `
            --region $Region
    }
    
    # Build image
    Write-Host "Building Docker image..." -ForegroundColor Gray
    docker build -t ${FullImageName}:$Tag $Path
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build $ServiceName" -ForegroundColor Red
        return $false
    }
    
    # Tag as latest if needed
    if ($Tag -ne "latest") {
        docker tag ${FullImageName}:$Tag ${FullImageName}:latest
    }
    
    # Push image
    Write-Host "Pushing to ECR..." -ForegroundColor Gray
    docker push ${FullImageName}:$Tag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to push $ServiceName" -ForegroundColor Red
        return $false
    }
    
    if ($Tag -ne "latest") {
        docker push ${FullImageName}:latest
    }
    
    Write-Host "Successfully built and pushed $ServiceName" -ForegroundColor Green
    return $true
}

# Build and push services
$Success = $true

if ($Service -eq "all" -or $Service -eq "backend") {
    if (-not (Build-And-Push -ServiceName "Backend" -Path "./be" -ImageName "sweetdream-backend")) {
        $Success = $false
    }
}

if ($Service -eq "all" -or $Service -eq "frontend") {
    if (-not (Build-And-Push -ServiceName "Frontend" -Path "./fe" -ImageName "sweetdream-frontend")) {
        $Success = $false
    }
}

if ($Service -eq "all" -or $Service -eq "order-service") {
    if (-not (Build-And-Push -ServiceName "Order Service" -Path "./order-service" -ImageName "sweetdream-order-service")) {
        $Success = $false
    }
}

if ($Service -eq "all" -or $Service -eq "user-service") {
    if (-not (Build-And-Push -ServiceName "User Service" -Path "./user-service" -ImageName "sweetdream-user-service")) {
        $Success = $false
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($Success) {
    Write-Host "All images built and pushed successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Deploy to ECS: .\scripts\force-deploy.ps1" -ForegroundColor Gray
    Write-Host "  2. Or let GitHub Actions handle deployment" -ForegroundColor Gray
} else {
    Write-Host "Some images failed to build or push" -ForegroundColor Red
    exit 1
}
