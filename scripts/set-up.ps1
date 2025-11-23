# Create ECR Repositories for SweetDream Microservices
# Run this ONCE before deploying

Write-Host "Creating ECR Repositories..." -ForegroundColor Cyan
Write-Host ""

$repos = @(
    "sweetdream-backend",
    "sweetdream-frontend",
    "sweetdream-user-service",
    "sweetdream-order-service"
)

foreach ($repo in $repos) {
    Write-Host "Creating repository: $repo" -ForegroundColor Yellow
    
    # Try to create the repository
    $result = aws ecr create-repository --repository-name $repo --image-scanning-configuration scanOnPush=true --encryption-configuration encryptionType=AES256 --region us-east-1 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Created: $repo" -ForegroundColor Green
    } elseif ($result -like "*RepositoryAlreadyExistsException*") {
        Write-Host "  Already exists: $repo" -ForegroundColor Blue
    } else {
        Write-Host "  Error creating $repo" -ForegroundColor Red
        Write-Host "  $result" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ECR Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repositories created:" -ForegroundColor Yellow
aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `sweetdream`)].repositoryName' --output table

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Build and push Docker images" -ForegroundColor White
Write-Host "2. Deploy infrastructure with Terraform" -ForegroundColor White
Write-Host "3. Update ECS services with new images" -ForegroundColor White
Write-Host ""
