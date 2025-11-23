# Check if all services are running
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Microservices Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allRunning = $true

# Check User Service
Write-Host "User Service (3001)..." -ForegroundColor Yellow -NoNewline
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 2
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "  Service: $($response.service)" -ForegroundColor Gray
} catch {
    Write-Host " [NOT RUNNING]" -ForegroundColor Red
    $allRunning = $false
}

Write-Host ""

# Check Order Service
Write-Host "Order Service (3002)..." -ForegroundColor Yellow -NoNewline
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3002/health" -TimeoutSec 2
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "  Service: $($response.service)" -ForegroundColor Gray
} catch {
    Write-Host " [NOT RUNNING]" -ForegroundColor Red
    $allRunning = $false
}

Write-Host ""

# Check Backend Service
Write-Host "Backend Service (3003)..." -ForegroundColor Yellow -NoNewline
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3003/health" -TimeoutSec 2
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "  Status: $($response.status)" -ForegroundColor Gray
} catch {
    Write-Host " [NOT RUNNING]" -ForegroundColor Red
    $allRunning = $false
}

Write-Host ""

# Check Frontend
Write-Host "Frontend (3000)..." -ForegroundColor Yellow -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 2 -ErrorAction Stop
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    Write-Host " [NOT RUNNING]" -ForegroundColor Red
    $allRunning = $false
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($allRunning) {
    Write-Host "ALL SERVICES RUNNING!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Visit: http://localhost:3000" -ForegroundColor Cyan
} else {
    Write-Host "SOME SERVICES NOT RUNNING!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start missing services:" -ForegroundColor Yellow
    Write-Host "  See: FIX_FRONTEND.md" -ForegroundColor White
    Write-Host "  Or: FULL_STACK_MICROSERVICES.md" -ForegroundColor White
}

Write-Host ""
