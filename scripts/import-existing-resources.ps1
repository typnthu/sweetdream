# Import Existing AWS Resources into Terraform State
# Run this before terraform apply to prevent resource recreation

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "Importing existing AWS resources into Terraform state..." -ForegroundColor Cyan

cd terraform

# Import S3 Analytics Buckets
Write-Host "`nImporting S3 buckets..." -ForegroundColor Yellow

try {
    terraform import 'module.backend_analytics[0].aws_s3_bucket.analytics' sweetdream-analytics-backend-production 2>$null
    Write-Host "✓ Imported backend analytics bucket" -ForegroundColor Green
} catch {
    Write-Host "  Backend analytics bucket already imported or doesn't exist" -ForegroundColor Gray
}

try {
    terraform import 'module.order_analytics[0].aws_s3_bucket.analytics' sweetdream-analytics-order-production 2>$null
    Write-Host "✓ Imported order analytics bucket" -ForegroundColor Green
} catch {
    Write-Host "  Order analytics bucket already imported or doesn't exist" -ForegroundColor Gray
}

# Import S3 Bucket Versioning
Write-Host "`nImporting S3 bucket versioning..." -ForegroundColor Yellow

try {
    terraform import 'module.backend_analytics[0].aws_s3_bucket_versioning.analytics' sweetdream-analytics-backend-production 2>$null
    Write-Host "✓ Imported backend bucket versioning" -ForegroundColor Green
} catch {
    Write-Host "  Backend bucket versioning already imported" -ForegroundColor Gray
}

try {
    terraform import 'module.order_analytics[0].aws_s3_bucket_versioning.analytics' sweetdream-analytics-order-production 2>$null
    Write-Host "✓ Imported order bucket versioning" -ForegroundColor Green
} catch {
    Write-Host "  Order bucket versioning already imported" -ForegroundColor Gray
}

Write-Host "`n✓ Import complete!" -ForegroundColor Green
Write-Host "Now you can safely run: terraform apply -var=`"db_password=`$env:DB_PASSWORD`"" -ForegroundColor Cyan

cd ..
