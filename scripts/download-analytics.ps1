# Download Analytics Data from S3
# Downloads exported user action logs from S3 buckets

param(
    [Parameter(Mandatory=$false)]
    [string]$Service = "all",  # all, backend, or order-service
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "analytics-data",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "Downloading analytics data from S3..." -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Created directory: $OutputDir" -ForegroundColor Green
}

function Download-ServiceLogs {
    param(
        [string]$ServiceName
    )
    
    $BucketName = "sweetdream-analytics-$ServiceName-production"
    $ServiceDir = Join-Path $OutputDir $ServiceName
    
    Write-Host ""
    Write-Host "Downloading logs from: $BucketName" -ForegroundColor Yellow
    
    # Check if bucket exists
    $bucketExists = aws s3api head-bucket --bucket $BucketName --region $Region 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Bucket not found or not accessible: $BucketName" -ForegroundColor Red
        return
    }
    
    # List files in bucket
    Write-Host "  Listing files..." -ForegroundColor Gray
    $files = aws s3 ls "s3://$BucketName/user-actions/" --recursive --region $Region
    
    if ([string]::IsNullOrEmpty($files)) {
        Write-Host "  No files found in bucket" -ForegroundColor Yellow
        return
    }
    
    # Create service directory
    if (-not (Test-Path $ServiceDir)) {
        New-Item -ItemType Directory -Path $ServiceDir | Out-Null
    }
    
    # Download files
    Write-Host "  Downloading files to: $ServiceDir" -ForegroundColor Gray
    aws s3 cp "s3://$BucketName/user-actions/" $ServiceDir --recursive --region $Region
    
    if ($LASTEXITCODE -eq 0) {
        $fileCount = (Get-ChildItem -Path $ServiceDir -Recurse -File).Count
        Write-Host "  Downloaded $fileCount files" -ForegroundColor Green
    } else {
        Write-Host "  Download failed" -ForegroundColor Red
    }
}

# Download based on service parameter
if ($Service -eq "all") {
    Download-ServiceLogs -ServiceName "backend"
    Download-ServiceLogs -ServiceName "order-service"
} else {
    Download-ServiceLogs -ServiceName $Service
}

Write-Host ""
Write-Host "Download complete!" -ForegroundColor Green
Write-Host "Files saved to: $OutputDir" -ForegroundColor Cyan

# Show summary
if (Test-Path $OutputDir) {
    $totalFiles = (Get-ChildItem -Path $OutputDir -Recurse -File).Count
    $totalSize = (Get-ChildItem -Path $OutputDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Total files: $totalFiles" -ForegroundColor White
    Write-Host "  Total size: $totalSizeMB MB" -ForegroundColor White
}
