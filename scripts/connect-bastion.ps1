# Connect to Bastion via AWS Systems Manager Session Manager
# No SSH keys or public IPs needed!

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Finding bastion instance..." -ForegroundColor Cyan

# Get bastion instance ID
$InstanceId = aws ec2 describe-instances `
    --region $Region `
    --filters "Name=tag:Name,Values=sweetdream-bastion" "Name=instance-state-name,Values=running" `
    --query "Reservations[0].Instances[0].InstanceId" `
    --output text

if ($InstanceId -eq "None" -or [string]::IsNullOrEmpty($InstanceId)) {
    Write-Host "❌ Bastion instance not found or not running" -ForegroundColor Red
    Write-Host "Make sure enable_bastion = true in terraform.tfvars and run terraform apply" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found bastion: $InstanceId" -ForegroundColor Green
Write-Host ""
Write-Host "📡 Connecting via AWS Systems Manager Session Manager..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Once connected, you can:" -ForegroundColor Yellow
Write-Host "  1. Run: ./connect-db.sh     - Connect to PostgreSQL database" -ForegroundColor White
Write-Host "  2. Run: ./check-admin.sh    - Check admin accounts" -ForegroundColor White
Write-Host "  3. Type 'exit' to disconnect" -ForegroundColor White
Write-Host ""

# Start SSM session
aws ssm start-session --target $InstanceId --region $Region
