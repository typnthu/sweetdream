# Clean Local Terraform State
# This removes local state files so GitHub Actions can manage everything

$ErrorActionPreference = "Stop"

Write-Host "Cleaning local Terraform state..." -ForegroundColor Cyan

$stateFiles = @(
    "terraform/.terraform",
    "terraform/.terraform.lock.hcl",
    "terraform/terraform.tfstate",
    "terraform/terraform.tfstate.backup",
    "terraform/tfplan"
)

foreach ($file in $stateFiles) {
    if (Test-Path $file) {
        Write-Host "Removing: $file" -ForegroundColor Yellow
        Remove-Item $file -Recurse -Force
        Write-Host "  Deleted" -ForegroundColor Green
    } else {
        Write-Host "Not found: $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Local state cleaned!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Remote state in S3 is NOT affected." -ForegroundColor Cyan
Write-Host "GitHub Actions will use the remote state to deploy." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Commit and push your changes" -ForegroundColor White
Write-Host "  2. GitHub Actions will deploy using remote state" -ForegroundColor White
Write-Host "  3. S3 buckets are protected and won't be deleted" -ForegroundColor White
