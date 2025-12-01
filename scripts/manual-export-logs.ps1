# Manual User Action Log Export Script (PowerShell)
# Usage: 
#   .\manual-export-logs.ps1 backend test       # Export today's backend logs
#   .\manual-export-logs.ps1 backend production # Export yesterday's backend logs
#   .\manual-export-logs.ps1 order test         # Export today's order logs
#   .\manual-export-logs.ps1 order production   # Export yesterday's order logs

param(
    [Parameter(Position=0)]
    [ValidateSet("backend", "order")]
    [string]$Service = "backend",
    
    [Parameter(Position=1)]
    [ValidateSet("test", "production")]
    [string]$Mode = "test"
)

Write-Host "=== CloudWatch Logs to S3 Export ===" -ForegroundColor Cyan
Write-Host "Service: $Service" -ForegroundColor Yellow
Write-Host ""

# Lambda function names from Terraform
if ($Service -eq "backend") {
    $LambdaFunctionName = "sweetdream-service-backend-export-logs"
} else {
    $LambdaFunctionName = "sweetdream-service-order-service-export-logs"
}

if ($Mode -eq "test") {
    $Payload = '{"test_mode": true}'
    Write-Host "Exporting TODAY's logs (test mode)..." -ForegroundColor Cyan
} else {
    $Payload = '{"test_mode": false}'
    Write-Host "Exporting YESTERDAY's logs (production mode)..." -ForegroundColor Cyan
}

Write-Host "Invoking Lambda function: $LambdaFunctionName" -ForegroundColor Yellow
Write-Host "Payload: $Payload" -ForegroundColor Yellow
Write-Host ""

# Invoke Lambda
# Convert payload to base64 (AWS CLI requirement)
$PayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($Payload)
$PayloadBase64 = [System.Convert]::ToBase64String($PayloadBytes)

aws lambda invoke --function-name $LambdaFunctionName --payload $PayloadBase64 response.json

Write-Host ""
Write-Host "Response:" -ForegroundColor Green
Get-Content response.json | Write-Host
Write-Host ""

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Export completed successfully" -ForegroundColor Green
} else {
    Write-Host "[FAILED] Export failed" -ForegroundColor Red
    exit 1
}
