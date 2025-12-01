# Terraform Apply Helper
# Prompts for password securely and applies Terraform

param(
    [switch]$Plan,
    [switch]$Destroy
)

$ErrorActionPreference = "Stop"

Write-Host "🏗️ Terraform Deployment Helper" -ForegroundColor Cyan
Write-Host ""

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform/terraform.tfvars")) {
    Write-Host "⚠️ terraform.tfvars not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Creating from example..." -ForegroundColor Gray
    
    if (Test-Path "terraform/terraform.tfvars.example") {
        Copy-Item "terraform/terraform.tfvars.example" "terraform/terraform.tfvars"
        Write-Host "✓ Created terraform/terraform.tfvars" -ForegroundColor Green
        Write-Host ""
        Write-Host "Please edit terraform/terraform.tfvars and set your values:" -ForegroundColor Yellow
        Write-Host "  - db_password" -ForegroundColor White
        Write-Host "  - alert_email" -ForegroundColor White
        Write-Host ""
        Write-Host "Then run this script again." -ForegroundColor Yellow
        exit 0
    }
}

# Read current values
Write-Host "Reading terraform.tfvars..." -ForegroundColor Gray
$tfvarsContent = Get-Content "terraform/terraform.tfvars" -Raw

# Check if password needs to be set
if ($tfvarsContent -match 'CHANGE_ME' -or $tfvarsContent -match 'db_password\s*=\s*""') {
    Write-Host "⚠️ Database password not set in terraform.tfvars" -ForegroundColor Yellow
    Write-Host ""
    
    # Prompt for password securely
    $securePassword = Read-Host "Enter database password" -AsSecureString
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
    
    # Update terraform.tfvars
    $tfvarsContent = $tfvarsContent -replace 'db_password\s*=\s*"[^"]*"', "db_password = `"$password`""
    Set-Content "terraform/terraform.tfvars" $tfvarsContent
    
    Write-Host "✓ Password updated in terraform.tfvars" -ForegroundColor Green
    Write-Host ""
}

# Change to terraform directory
Set-Location terraform

# Initialize
Write-Host "Initializing Terraform..." -ForegroundColor Cyan
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init failed" -ForegroundColor Red
    exit 1
}

# Plan or Apply
if ($Plan) {
    Write-Host ""
    Write-Host "Planning deployment..." -ForegroundColor Cyan
    terraform plan
} elseif ($Destroy) {
    Write-Host ""
    Write-Host "⚠️ WARNING: This will destroy all infrastructure!" -ForegroundColor Red
    $confirm = Read-Host "Type 'yes' to confirm"
    
    if ($confirm -eq "yes") {
        terraform destroy
    } else {
        Write-Host "Cancelled" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Applying deployment..." -ForegroundColor Cyan
    terraform apply
}

Set-Location ..

Write-Host ""
Write-Host "✓ Done!" -ForegroundColor Green
