# Set User Role via User Service
# Usage: .\set-user-role.ps1 -Email "user@example.com" -Role "ADMIN"

param(
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("ADMIN", "CUSTOMER")]
    [string]$Role
)

$ErrorActionPreference = "Stop"

Write-Host "Setting role for $Email to $Role..." -ForegroundColor Cyan

# Get ALB URL
$albUrl = aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `sweetdream`)].DNSName' --output text

if ([string]::IsNullOrEmpty($albUrl)) {
    Write-Host "ALB not found. Trying localhost..." -ForegroundColor Yellow
    $userServiceUrl = "http://localhost:3003"
} else {
    $userServiceUrl = "http://$albUrl"
}

Write-Host "User Service URL: $userServiceUrl" -ForegroundColor Gray

# Update role via user-service API
$body = @{
    role = $Role
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$userServiceUrl/api/customers/email/$Email/role" `
        -Method PATCH `
        -Body $body `
        -ContentType "application/json"
    
    Write-Host ""
    Write-Host "✓ Role updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Customer Details:" -ForegroundColor Cyan
    Write-Host "  ID: $($response.customer.id)" -ForegroundColor White
    Write-Host "  Email: $($response.customer.email)" -ForegroundColor White
    Write-Host "  Name: $($response.customer.name)" -ForegroundColor White
    Write-Host "  Role: $($response.customer.role)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: User must log in again to get a new token with updated role." -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "✗ Failed to update role" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
    
    exit 1
}
