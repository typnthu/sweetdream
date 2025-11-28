# Deploy Bastion Host Only
# This script applies only the bastion module to avoid re-deploying everything

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying Bastion Host..." -ForegroundColor Cyan

cd terraform

# Check if DB_PASSWORD is set, if not try to load from terraform.tfvars
if ([string]::IsNullOrEmpty($env:DB_PASSWORD)) {
    Write-Host "DB_PASSWORD not in environment, checking terraform.tfvars..." -ForegroundColor Yellow
    
    if (Test-Path "terraform.tfvars") {
        $tfvarsContent = Get-Content "terraform.tfvars" -Raw
        $pattern = 'db_password\s*=\s*"([^"]+)"'
        if ($tfvarsContent -match $pattern) {
            $env:DB_PASSWORD = $matches[1]
            Write-Host "Loaded DB_PASSWORD from terraform.tfvars" -ForegroundColor Green
        } else {
            Write-Host "DB_PASSWORD not found in terraform.tfvars" -ForegroundColor Red
            Write-Host 'Set it with: $env:DB_PASSWORD = "your-password"' -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "terraform.tfvars not found" -ForegroundColor Red
        Write-Host 'Set it with: $env:DB_PASSWORD = "your-password"' -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

Write-Host ""
Write-Host "Planning bastion deployment..." -ForegroundColor Yellow
terraform plan -target="module.bastion" -var="db_password=$env:DB_PASSWORD" -out=tfplan

Write-Host ""
Write-Host "Applying bastion deployment..." -ForegroundColor Yellow
terraform apply tfplan

Write-Host ""
Write-Host "Bastion deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To connect to bastion, run:" -ForegroundColor Cyan
Write-Host "  .\scripts\connect-bastion.ps1" -ForegroundColor White

cd ..
