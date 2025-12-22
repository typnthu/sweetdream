# Script de tao load test cho Auto Scaling
# Chay nhieu requests dong thoi de trigger auto scaling

param(
    [int]$NumberOfRequests = 50,
    [int]$ConcurrentJobs = 10,
    [string]$BaseUrl = "http://sweetdream-alb-1623237604.us-east-1.elb.amazonaws.com"
)

$USER_EMAIL = "admin@sweetdream.com"
$PASSWORD = "admin123"

# API paths - Next.js proxies to backend services
$API_AUTH = "/api/proxy/auth"
$API_PRODUCTS = "/api/proxy/products"
$API_CART = "/api/proxy/cart"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SWEETDREAM AUTO SCALING LOAD TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "So luong requests: $NumberOfRequests" -ForegroundColor Yellow
Write-Host "Concurrent jobs: $ConcurrentJobs" -ForegroundColor Yellow
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host ""

# Script block de chay trong moi job
$scriptBlock = {
    param($BaseUrl, $Email, $Password, $JobId)
    
    $results = @{
        JobId = $JobId
        Success = $false
        Steps = @()
        TotalTime = 0
        Error = $null
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # 1. Login
        $loginBody = @{
            email = $Email
            password = $Password
        } | ConvertTo-Json
        
        $loginStart = Get-Date
        $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/proxy/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $loginBody `
            -TimeoutSec 30
        $loginTime = ((Get-Date) - $loginStart).TotalMilliseconds
        
        $token = $loginResponse.token
        $results.Steps += @{
            Step = "Login"
            Time = $loginTime
            Success = $true
        }
        
        # 2. Get Products
        $productsStart = Get-Date
        $products = Invoke-RestMethod -Uri "$BaseUrl/api/proxy/products" `
            -Method GET `
            -ContentType "application/json" `
            -TimeoutSec 30
        $productsTime = ((Get-Date) - $productsStart).TotalMilliseconds
        
        $results.Steps += @{
            Step = "GetProducts"
            Time = $productsTime
            Success = $true
            Count = $products.Count
        }
        
        # 3. Get Product Detail
        if ($products.Count -gt 0) {
            $productId = $products[0].id
            $headers = @{
                "Authorization" = "Bearer $token"
                "x-session-id" = [guid]::NewGuid().ToString()
            }
            
            $detailStart = Get-Date
            $productDetail = Invoke-RestMethod -Uri "$BaseUrl/api/proxy/products/$productId" `
                -Method GET `
                -Headers $headers `
                -ContentType "application/json" `
                -TimeoutSec 30
            $detailTime = ((Get-Date) - $detailStart).TotalMilliseconds
            
            $results.Steps += @{
                Step = "GetProductDetail"
                Time = $detailTime
                Success = $true
                ProductId = $productId
            }
            
            # 4. Add to Cart
            $cartBody = @{
                productId = $productId
                size = $products[0].sizes[0].size
                quantity = 1
                price = $products[0].sizes[0].price
            } | ConvertTo-Json
            
            $cartStart = Get-Date
            $cartResponse = Invoke-RestMethod -Uri "$BaseUrl/api/proxy/cart/items" `
                -Method POST `
                -Headers $headers `
                -ContentType "application/json" `
                -Body $cartBody `
                -TimeoutSec 30
            $cartTime = ((Get-Date) - $cartStart).TotalMilliseconds
            
            $results.Steps += @{
                Step = "AddToCart"
                Time = $cartTime
                Success = $true
            }
            
            # 5. Get Cart
            $getCartStart = Get-Date
            $cart = Invoke-RestMethod -Uri "$BaseUrl/api/proxy/cart" `
                -Method GET `
                -Headers $headers `
                -ContentType "application/json" `
                -TimeoutSec 30
            $getCartTime = ((Get-Date) - $getCartStart).TotalMilliseconds
            
            $results.Steps += @{
                Step = "GetCart"
                Time = $getCartTime
                Success = $true
                ItemCount = $cart.items.Count
            }
        }
        
        $results.Success = $true
        
    } catch {
        $results.Error = $_.Exception.Message
    }
    
    $stopwatch.Stop()
    $results.TotalTime = $stopwatch.ElapsedMilliseconds
    
    return $results
}

# Chay load test
Write-Host "Bat dau load test..." -ForegroundColor Yellow
Write-Host ""

$jobs = @()
$startTime = Get-Date

# Tao va chay cac jobs
for ($i = 1; $i -le $NumberOfRequests; $i++) {
    # Cho neu da dat so luong concurrent jobs
    while ((Get-Job -State Running).Count -ge $ConcurrentJobs) {
        Start-Sleep -Milliseconds 100
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $BaseUrl, $USER_EMAIL, $PASSWORD, $i
    $jobs += $job
    
    Write-Host "." -NoNewline -ForegroundColor Green
    
    if ($i % 50 -eq 0) {
        Write-Host " [$i/$NumberOfRequests]" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host ""
Write-Host "Dang cho tat ca requests hoan thanh..." -ForegroundColor Yellow

# Cho tat ca jobs hoan thanh
$jobs | Wait-Job | Out-Null

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

# Thu thap ket qua
Write-Host "Dang thu thap ket qua..." -ForegroundColor Yellow
$allResults = $jobs | Receive-Job
$jobs | Remove-Job

# Phan tich ket qua
$successCount = ($allResults | Where-Object { $_.Success -eq $true }).Count
$failCount = $NumberOfRequests - $successCount

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "KET QUA LOAD TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Tong quan:" -ForegroundColor Yellow
Write-Host "  Tong so requests: $NumberOfRequests" -ForegroundColor Gray
Write-Host "  Thanh cong: $successCount" -ForegroundColor Green
Write-Host "  That bai: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "  Ty le thanh cong: $([math]::Round($successCount / $NumberOfRequests * 100, 2))%" -ForegroundColor Cyan
Write-Host "  Thoi gian tong: $([math]::Round($totalDuration, 2)) giay" -ForegroundColor Gray
Write-Host "  Requests/giay: $([math]::Round($NumberOfRequests / $totalDuration, 2))" -ForegroundColor Gray
Write-Host ""

# Thong ke thoi gian response
$successResults = @($allResults | Where-Object { $_.Success -eq $true })

if ($successResults.Count -gt 0) {
    Write-Host "Thoi gian response (ms):" -ForegroundColor Yellow
    
    $totalTimes = $successResults | ForEach-Object { $_.TotalTime }
    $avgTime = ($totalTimes | Measure-Object -Average).Average
    $minTime = ($totalTimes | Measure-Object -Minimum).Minimum
    $maxTime = ($totalTimes | Measure-Object -Maximum).Maximum
    
    Write-Host "  Trung binh: $([math]::Round($avgTime, 2)) ms" -ForegroundColor Gray
    Write-Host "  Nhanh nhat: $([math]::Round($minTime, 2)) ms" -ForegroundColor Green
    Write-Host "  Cham nhat: $([math]::Round($maxTime, 2)) ms" -ForegroundColor $(if ($maxTime -gt 5000) { "Red" } else { "Gray" })
    Write-Host ""
    
    # Thong ke tung buoc
    Write-Host "Thoi gian trung binh tung buoc:" -ForegroundColor Yellow
    
    $allSteps = $successResults | ForEach-Object { $_.Steps } | Group-Object -Property Step
    
    foreach ($stepGroup in $allSteps) {
        $stepName = $stepGroup.Name
        $stepTimes = $stepGroup.Group | ForEach-Object { $_.Time }
        $avgStepTime = ($stepTimes | Measure-Object -Average).Average
        
        Write-Host "  $stepName : $([math]::Round($avgStepTime, 2)) ms" -ForegroundColor Gray
    }
    Write-Host ""
}

# Hien thi loi neu co
if ($failCount -gt 0) {
    Write-Host "Loi gap phai:" -ForegroundColor Red
    $failResults = $allResults | Where-Object { $_.Success -eq $false }
    $errorGroups = $failResults | Group-Object -Property Error
    
    foreach ($errorGroup in $errorGroups) {
        Write-Host "  [$($errorGroup.Count)x] $($errorGroup.Name)" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LOAD TEST HOAN THANH!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "De xem auto scaling hoat dong:" -ForegroundColor Yellow
Write-Host "  1. Kiem tra CloudWatch Metrics cho CPU/Memory" -ForegroundColor Gray
Write-Host "  2. Xem ECS Service Events de thay scaling activities" -ForegroundColor Gray
Write-Host "  3. Kiem tra so luong tasks dang chay trong ECS Service" -ForegroundColor Gray
Write-Host ""
Write-Host "Chay lai voi nhieu requests hon:" -ForegroundColor Yellow
Write-Host '  .\scripts\load-test-autoscaling.ps1 -NumberOfRequests 100 -ConcurrentJobs 20' -ForegroundColor Gray
Write-Host ""
