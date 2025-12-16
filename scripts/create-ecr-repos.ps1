# Create ECR Repositories for SweetDream
# Run this BEFORE deploying infrastructure if ECR repos don't exist

$ErrorActionPreference = "Stop"

Write-Host "Creating ECR repositories..." -ForegroundColor Cyan
Write-Host ""

$repositories = @(
    "sweetdream-backend",
    "sweetdream-frontend",
    "sweetdream-user-service",
    "sweetdream-order-service"
)

foreach ($repo in $repositories) {
    Write-Host "Creating repository: $repo" -ForegroundColor Yellow
    
    try {
        # Check if repository exists
        $exists = aws ecr describe-repositories --repository-names $repo 2>$null
        
        if ($exists) {
            Write-Host "  Repository already exists" -ForegroundColor Green
        }
    } catch {
        # Create repository
        aws ecr create-repository `
            --repository-name $repo `
            --image-scanning-configuration scanOnPush=true `
            --encryption-configuration encryptionType=AES256 `
            --tags Key=Project,Value=SweetDream Key=ManagedBy,Value=Script
        
        Write-Host "  Repository created" -ForegroundColor Green
        
        # Set lifecycle policy (keep last 10 images)
        $lifecyclePolicy = @{
            rules = @(
                @{
                    rulePriority = 1
                    description = "Keep last 10 images"
                    selection = @{
                        tagStatus = "any"
                        countType = "imageCountMoreThan"
                        countNumber = 10
                    }
                    action = @{
                        type = "expire"
                    }
                }
            )
        } | ConvertTo-Json -Depth 10 -Compress
        
        aws ecr put-lifecycle-policy `
            --repository-name $repo `
            --lifecycle-policy-text $lifecyclePolicy
        
        Write-Host "  Lifecycle policy set" -ForegroundColor Green
    }
    
    Write-Host ""
}

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "ECR Setup Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repository URLs:" -ForegroundColor Yellow

$accountId = aws sts get-caller-identity --query Account --output text
$region = aws configure get region

foreach ($repo in $repositories) {
    $url = "$accountId.dkr.ecr.$region.amazonaws.com/$repo"
    Write-Host "  $repo" -ForegroundColor White
    Write-Host "    $url" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: cd terraform && terraform init" -ForegroundColor White
Write-Host "2. Run: terraform apply" -ForegroundColor White
Write-Host "3. Push to GitHub to trigger deployment" -ForegroundColor White
