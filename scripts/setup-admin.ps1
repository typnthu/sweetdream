# Setup Admin User
# Creates admin@sweetdream.com with password admin123 and ADMIN role

$ErrorActionPreference = "Stop"

Write-Host "🔧 Setting up admin user..." -ForegroundColor Cyan
Write-Host ""

# Check if running locally or on AWS
$albUrl = aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `sweetdream`)].DNSName' --output text 2>$null

if ([string]::IsNullOrEmpty($albUrl)) {
    Write-Host "Running locally..." -ForegroundColor Yellow
    $isLocal = $true
    $userServiceUrl = "http://localhost:3003"
} else {
    Write-Host "Running on AWS..." -ForegroundColor Yellow
    $isLocal = $false
    $userServiceUrl = "http://$albUrl"
}

Write-Host "User Service URL: $userServiceUrl" -ForegroundColor Gray
Write-Host ""

# Admin credentials
$adminEmail = "admin@sweetdream.com"
$adminPassword = "admin123"
$adminName = "Admin"

# Try to register admin user
Write-Host "Attempting to create admin user..." -ForegroundColor Cyan

$registerBody = @{
    name = $adminName
    email = $adminEmail
    password = $adminPassword
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$userServiceUrl/api/auth/register" `
        -Method POST `
        -Body $registerBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "✓ Admin user created successfully!" -ForegroundColor Green
    $userId = $response.user.id
    
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "Admin user already exists, fetching details..." -ForegroundColor Yellow
        
        # Get existing user
        try {
            $existingUser = Invoke-RestMethod -Uri "$userServiceUrl/api/customers/email/$adminEmail" `
                -Method GET `
                -ErrorAction Stop
            
            $userId = $existingUser.id
            Write-Host "✓ Found existing admin user (ID: $userId)" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to fetch existing user" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✗ Failed to create admin user" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Update role to ADMIN
Write-Host ""
Write-Host "Setting role to ADMIN..." -ForegroundColor Cyan

$roleBody = @{
    role = "ADMIN"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$userServiceUrl/api/customers/$userId/role" `
        -Method PATCH `
        -Body $roleBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "✓ Role updated to ADMIN" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Failed to update role" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✓ Admin Setup Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Email:    admin@sweetdream.com" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host "  Role:     ADMIN" -ForegroundColor White
Write-Host ""

if ($isLocal) {
    Write-Host "Login at: http://localhost:3000" -ForegroundColor Cyan
} else {
    Write-Host "Login at: http://$albUrl" -ForegroundColor Cyan
}

Write-Host ""
