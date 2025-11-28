# Manually Export CloudWatch Logs to S3
# This triggers the Lambda function that exports user action logs
# .\scripts\export-logs-to-s3.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$Service = "backend",  # backend or order-service
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "Exporting CloudWatch logs to S3..." -ForegroundColor Cyan
Write-Host "Service: $Service" -ForegroundColor Yellow

# Determine Lambda function name based on service
$LambdaName = "sweetdream-service-$Service-export-logs"

Write-Host ""
Write-Host "Finding Lambda function: $LambdaName" -ForegroundColor Yellow

# Check if Lambda exists
$lambdaExists = aws lambda get-function --function-name $LambdaName --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lambda function not found: $LambdaName" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available options:" -ForegroundColor Yellow
    Write-Host "  - backend" -ForegroundColor White
    Write-Host "  - order-service" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage: .\scripts\export-logs-to-s3.ps1 -Service backend" -ForegroundColor Cyan
    exit 1
}

Write-Host "Found Lambda function" -ForegroundColor Green
Write-Host ""
Write-Host "Invoking Lambda to export logs..." -ForegroundColor Yellow

# Invoke Lambda function
$result = aws lambda invoke `
    --function-name $LambdaName `
    --region $Region `
    --invocation-type RequestResponse `
    --log-type Tail `
    response.json

if ($LASTEXITCODE -eq 0) {
    Write-Host "Lambda invoked successfully" -ForegroundColor Green
    Write-Host ""
    
    # Read and display response
    if (Test-Path "response.json") {
        $response = Get-Content "response.json" -Raw | ConvertFrom-Json
        Write-Host "Response:" -ForegroundColor Cyan
        Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
        
        # Clean up
        Remove-Item "response.json" -Force
    }
    
    Write-Host ""
    Write-Host "Logs exported to S3 bucket: sweetdream-analytics-$Service-production" -ForegroundColor Green
    Write-Host "Prefix: user-actions/" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "To download the exported logs:" -ForegroundColor Cyan
    Write-Host "  aws s3 ls s3://sweetdream-analytics-$Service-production/user-actions/" -ForegroundColor White
    Write-Host "  aws s3 cp s3://sweetdream-analytics-$Service-production/user-actions/ . --recursive" -ForegroundColor White
} else {
    Write-Host "Failed to invoke Lambda function" -ForegroundColor Red
    exit 1
}
