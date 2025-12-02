# Manual User Action Log Export Script (PowerShell)
# Usage: 
#   .\manual-export-logs.ps1 backend  # Export today's backend logs (00:00 to now)
#   .\manual-export-logs.ps1 order    # Export today's order logs (00:00 to now)

param(
    [Parameter(Position=0)]
    [ValidateSet("backend", "order")]
    [string]$Service = "backend"
)

Write-Host "=== CloudWatch Logs to S3 Export ===" -ForegroundColor Cyan
Write-Host "Service: $Service" -ForegroundColor Yellow
Write-Host "Exporting today's logs (00:00 to now)..." -ForegroundColor Cyan
Write-Host ""

# Lambda function names from Terraform
if ($Service -eq "backend") {
    $LambdaFunctionName = "sweetdream-service-backend-export-logs"
} else {
    $LambdaFunctionName = "sweetdream-service-order-service-export-logs"
}

# Payload (empty object, Lambda will use current time)
$Payload = '{}'

Write-Host "Invoking Lambda function: $LambdaFunctionName" -ForegroundColor Yellow
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
