# Start All Services for Microservices Demo
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting SweetDream Microservices" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if database is running
Write-Host "Checking database..." -ForegroundColor Yellow
$dbRunning = docker ps --filter "name=sweetdream-db" --format "{{.Names}}"
if (-not $dbRunning) {
    Write-Host "[INFO] Starting database..." -ForegroundColor Yellow
    docker-compose -f docker-compose.dev.yml up -d
    Write-Host "[INFO] Waiting for database (10 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}
Write-Host "[OK] Database is running" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Please open 4 separate terminals and run:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Terminal 1 - User Service (Port 3001):" -ForegroundColor Yellow
Write-Host "  cd user-service" -ForegroundColor White
Write-Host "  `$env:DATABASE_URL='postgresql://dev:dev123@localhost:5432/sweetdream'" -ForegroundColor White
Write-Host "  `$env:PORT='3001'" -ForegroundColor White
Write-Host "  npm install" -ForegroundColor White
Write-Host "  npx prisma generate" -ForegroundColor White
Write-Host "  npx prisma db push --accept-data-loss" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

Write-Host "Terminal 2 - Order Service (Port 3002):" -ForegroundColor Yellow
Write-Host "  cd order-service" -ForegroundColor White
Write-Host "  `$env:DATABASE_URL='postgresql://dev:dev123@localhost:5432/sweetdream'" -ForegroundColor White
Write-Host "  `$env:PORT='3002'" -ForegroundColor White
Write-Host "  `$env:USER_SERVICE_URL='http://localhost:3001'" -ForegroundColor White
Write-Host "  npm install" -ForegroundColor White
Write-Host "  npx prisma generate" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

Write-Host "Terminal 3 - Backend Service (Port 3003):" -ForegroundColor Yellow
Write-Host "  cd be" -ForegroundColor White
Write-Host "  `$env:DATABASE_URL='postgresql://dev:dev123@localhost:5432/sweetdream'" -ForegroundColor White
Write-Host "  `$env:PORT='3003'" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

Write-Host "Terminal 4 - Frontend (Port 3000):" -ForegroundColor Yellow
Write-Host "  cd fe" -ForegroundColor White
Write-Host "  Copy-Item .env.microservices .env.local" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "After all services are running:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Visit: http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  User Service:    http://localhost:3001/health" -ForegroundColor White
Write-Host "  Order Service:   http://localhost:3002/health" -ForegroundColor White
Write-Host "  Backend Service: http://localhost:3003/health" -ForegroundColor White
Write-Host "  Frontend:        http://localhost:3000" -ForegroundColor White
Write-Host ""
