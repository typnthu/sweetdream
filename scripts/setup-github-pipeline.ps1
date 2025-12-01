# Setup GitHub Actions Pipeline
# This script helps you configure AWS and GitHub for CI/CD

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub Actions Pipeline Setup for SweetDream         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "✓ AWS CLI installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI not found!" -ForegroundColor Red
    Write-Host "  Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 1: AWS Resources Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
$accountId = aws sts get-caller-identity --query Account --output text
$region = aws configure get region

if ([string]::IsNullOrEmpty($region)) {
    $region = "us-east-1"
}

Write-Host "AWS Account ID: $accountId" -ForegroundColor White
Write-Host "AWS Region: $region" -ForegroundColor White
Write-Host ""

# Create S3 bucket for Terraform state
$stateBucket = "sweetdream-terraform-state-$accountId"
Write-Host "Creating S3 bucket for Terraform state..." -ForegroundColor Yellow
Write-Host "  Bucket: $stateBucket" -ForegroundColor Gray

try {
    aws s3 mb "s3://$stateBucket" --region $region 2>$null
    Write-Host "✓ S3 bucket created" -ForegroundColor Green
} catch {
    Write-Host "✓ S3 bucket already exists" -ForegroundColor Green
}

# Enable versioning
Write-Host "  Enabling versioning..." -ForegroundColor Gray
aws s3api put-bucket-versioning `
    --bucket $stateBucket `
    --versioning-configuration Status=Enabled `
    --region $region
Write-Host "✓ Versioning enabled" -ForegroundColor Green

# Enable encryption
Write-Host "  Enabling encryption..." -ForegroundColor Gray
aws s3api put-bucket-encryption `
    --bucket $stateBucket `
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' `
    --region $region
Write-Host "✓ Encryption enabled" -ForegroundColor Green

Write-Host ""

# Create DynamoDB table for locks
Write-Host "Creating DynamoDB table for Terraform locks..." -ForegroundColor Yellow
Write-Host "  Table: sweetdream-terraform-locks" -ForegroundColor Gray

try {
    aws dynamodb create-table `
        --table-name sweetdream-terraform-locks `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $region 2>$null | Out-Null
    Write-Host "✓ DynamoDB table created" -ForegroundColor Green
} catch {
    Write-Host "✓ DynamoDB table already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 2: IAM User for GitHub Actions" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$iamUser = "github-actions-sweetdream"

Write-Host "Creating IAM user..." -ForegroundColor Yellow
Write-Host "  Username: $iamUser" -ForegroundColor Gray

try {
    aws iam create-user --user-name $iamUser 2>$null | Out-Null
    Write-Host "✓ IAM user created" -ForegroundColor Green
} catch {
    Write-Host "✓ IAM user already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Creating access key..." -ForegroundColor Yellow

try {
    $accessKey = aws iam create-access-key --user-name $iamUser --output json | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ⚠️  SAVE THESE CREDENTIALS NOW!                       ║" -ForegroundColor Green
    Write-Host "║  They will not be shown again!                        ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "AWS_ACCESS_KEY_ID:" -ForegroundColor Yellow
    Write-Host $accessKey.AccessKey.AccessKeyId -ForegroundColor White
    Write-Host ""
    Write-Host "AWS_SECRET_ACCESS_KEY:" -ForegroundColor Yellow
    Write-Host $accessKey.AccessKey.SecretAccessKey -ForegroundColor White
    Write-Host ""
    
    # Save to file
    $credsFile = "github-secrets.txt"
    @"
GitHub Secrets for SweetDream Pipeline
Generated: $(Get-Date)

Add these to GitHub: Settings → Secrets and variables → Actions

AWS_ACCESS_KEY_ID
$($accessKey.AccessKey.AccessKeyId)

AWS_SECRET_ACCESS_KEY
$($accessKey.AccessKey.SecretAccessKey)

DB_PASSWORD
$(openssl rand -base64 32 2>$null)

"@ | Out-File $credsFile -Encoding UTF8
    
    Write-Host "✓ Credentials saved to: $credsFile" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "⚠️  Access key already exists for this user" -ForegroundColor Yellow
    Write-Host "   To create new key, delete old one first:" -ForegroundColor Gray
    Write-Host "   aws iam list-access-keys --user-name $iamUser" -ForegroundColor Gray
    Write-Host "   aws iam delete-access-key --user-name $iamUser --access-key-id <KEY_ID>" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Attaching IAM policies..." -ForegroundColor Yellow

$policies = @(
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
)

foreach ($policy in $policies) {
    $policyName = $policy.Split("/")[-1]
    try {
        aws iam attach-user-policy --user-name $iamUser --policy-arn $policy 2>$null
        Write-Host "  ✓ $policyName" -ForegroundColor Green
    } catch {
        Write-Host "  ✓ $policyName (already attached)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 3: Generate Database Password" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$dbPassword = openssl rand -base64 32 2>$null
if ([string]::IsNullOrEmpty($dbPassword)) {
    $dbPassword = "GENERATE_SECURE_PASSWORD_HERE"
}

Write-Host "DB_PASSWORD:" -ForegroundColor Yellow
Write-Host $dbPassword -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ AWS Setup Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Add secrets to GitHub:" -ForegroundColor White
Write-Host "   Go to: https://github.com/YOUR_ORG/sweetdream/settings/secrets/actions" -ForegroundColor Gray
Write-Host "   Add these three secrets:" -ForegroundColor Gray
Write-Host "   • AWS_ACCESS_KEY_ID" -ForegroundColor Cyan
Write-Host "   • AWS_SECRET_ACCESS_KEY" -ForegroundColor Cyan
Write-Host "   • DB_PASSWORD" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Create GitHub Environments:" -ForegroundColor White
Write-Host "   Go to: https://github.com/YOUR_ORG/sweetdream/settings/environments" -ForegroundColor Gray
Write-Host "   Create:" -ForegroundColor Gray
Write-Host "   • production (with approval required)" -ForegroundColor Cyan
Write-Host "   • development (no approval)" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Update terraform/backend.tf:" -ForegroundColor White
Write-Host "   Change bucket name to: $stateBucket" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Test the pipeline:" -ForegroundColor White
Write-Host "   git checkout -b test-pipeline" -ForegroundColor Gray
Write-Host "   git commit --allow-empty -m 'test: trigger pipeline'" -ForegroundColor Gray
Write-Host "   git push origin test-pipeline" -ForegroundColor Gray
Write-Host ""
Write-Host "📄 Credentials saved to: $credsFile" -ForegroundColor Yellow
Write-Host "📚 Full guide: .github/SETUP_GUIDE.md" -ForegroundColor Yellow
Write-Host ""
