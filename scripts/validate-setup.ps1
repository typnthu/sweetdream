# Validation script to check if all prerequisites are met
# Run this before attempting deployment

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

Write-Host "${Blue}SweetDream Deployment Validation${Reset}"
Write-Host "${Blue}================================${Reset}"
Write-Host ""

# Check Docker
Write-Host "${Yellow}Checking Docker...${Reset}"
try {
    $dockerVersion = docker --version 2>$null
    docker info 2>$null | Out-Null
    Write-Host "${Green}[OK] Docker is installed and running${Reset}"
    Write-Host "  Version: $dockerVersion"
} catch {
    try {
        docker --version 2>$null | Out-Null
        Write-Host "${Red}[ERROR] Docker is installed but not running${Reset}"
        Write-Host "  Please start Docker Desktop"
        exit 1
    } catch {
        Write-Host "${Red}[ERROR] Docker is not installed${Reset}"
        Write-Host "  Please install Docker Desktop"
        exit 1
    }
}
Write-Host ""

# Check AWS CLI
Write-Host "${Yellow}Checking AWS CLI...${Reset}"
try {
    $awsVersion = aws --version 2>$null
    Write-Host "${Green}[OK] AWS CLI is installed${Reset}"
    Write-Host "  Version: $awsVersion"
    
    # Check AWS credentials
    try {
        aws sts get-caller-identity 2>$null | Out-Null
        Write-Host "${Green}[OK] AWS credentials are configured${Reset}"
        $awsAccount = aws sts get-caller-identity --query Account --output text 2>$null
        $awsRegion = aws configure get region 2>$null
        if (-not $awsRegion) { $awsRegion = "not set" }
        Write-Host "  Account ID: $awsAccount"
        Write-Host "  Default Region: $awsRegion"
    } catch {
        Write-Host "${Red}[ERROR] AWS credentials not configured${Reset}"
        Write-Host "  Run: aws configure"
        exit 1
    }
} catch {
    Write-Host "${Red}[ERROR] AWS CLI is not installed${Reset}"
    Write-Host "  Please install AWS CLI v2"
    exit 1
}
Write-Host ""

# Check Terraform
Write-Host "${Yellow}Checking Terraform...${Reset}"
try {
    $terraformVersion = terraform --version 2>$null | Select-Object -First 1
    Write-Host "${Green}[OK] Terraform is installed${Reset}"
    Write-Host "  Version: $terraformVersion"
} catch {
    Write-Host "${Yellow}! Terraform is not installed${Reset}"
    Write-Host "  Install Terraform if you plan to deploy infrastructure"
}
Write-Host ""

# Check Git
Write-Host "${Yellow}Checking Git...${Reset}"
try {
    $gitVersion = git --version 2>$null
    Write-Host "${Green}[OK] Git is installed${Reset}"
    Write-Host "  Version: $gitVersion"
} catch {
    Write-Host "${Yellow}! Git is not installed${Reset}"
    Write-Host "  Install Git for version control"
}
Write-Host ""

# Check PowerShell scripts
Write-Host "${Yellow}Checking PowerShell scripts...${Reset}"
$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$powershellScripts = @(
    "build-and-deploy.ps1",
    "deploy-images.ps1",
    "create-ecr-repos.ps1",
    "validate-setup.ps1"
)

foreach ($script in $powershellScripts) {
    $scriptPath = Join-Path $scriptsDir $script
    if (Test-Path $scriptPath) {
        Write-Host "${Green}[OK] $script exists${Reset}"
    } else {
        Write-Host "${Red}[ERROR] $script not found${Reset}"
    }
}
Write-Host ""

# Check project structure
Write-Host "${Yellow}Checking project structure...${Reset}"
$requiredDirs = @("be", "fe", "user-service", "order-service", "terraform")
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir -PathType Container) {
        Write-Host "${Green}[OK] $dir directory exists${Reset}"
    } else {
        Write-Host "${Red}[ERROR] $dir directory missing${Reset}"
        exit 1
    }
}
Write-Host ""

# Check Dockerfiles
Write-Host "${Yellow}Checking Dockerfiles...${Reset}"
$dockerfiles = @("be/Dockerfile", "fe/Dockerfile", "user-service/Dockerfile", "order-service/Dockerfile")
foreach ($dockerfile in $dockerfiles) {
    if (Test-Path $dockerfile) {
        Write-Host "${Green}[OK] $dockerfile exists${Reset}"
    } else {
        Write-Host "${Red}[ERROR] $dockerfile missing${Reset}"
        exit 1
    }
}
Write-Host ""

# Summary
Write-Host "${Green}================================${Reset}"
Write-Host "${Green}Validation Complete!${Reset}"
Write-Host "${Green}================================${Reset}"
Write-Host ""
Write-Host "${Green}Your system is ready for deployment.${Reset}"
Write-Host ""
Write-Host "${Blue}Next steps:${Reset}"
Write-Host "1. Run complete deployment:"
Write-Host "   ${Yellow}.\scripts\build-and-deploy.ps1 -Environment dev -ImageTag latest${Reset}"
Write-Host ""
Write-Host "2. Or see detailed guide:"
Write-Host "   ${Yellow}Get-Content scripts\DEPLOYMENT_GUIDE.md${Reset}"
Write-Host ""