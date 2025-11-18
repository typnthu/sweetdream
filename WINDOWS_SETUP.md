# Windows Setup Guide

Quick guide for setting up the CI/CD pipeline on Windows.

## 🪟 Windows-Specific Instructions

### Option 1: Use PowerShell Script (Recommended for Windows)

```powershell
# Run the PowerShell setup script
.\scripts\setup-cicd.ps1
```

This script is native to Windows and will work without any additional tools.

---

### Option 2: Use Git Bash

If you prefer the bash script:

1. **Install Git for Windows** (includes Git Bash)
   - Download from: https://git-scm.com/download/win

2. **Open Git Bash** (not PowerShell or CMD)

3. **Run the bash script:**
   ```bash
   chmod +x scripts/setup-cicd.sh
   ./scripts/setup-cicd.sh
   ```

---

### Option 3: Use WSL (Windows Subsystem for Linux)

1. **Install WSL:**
   ```powershell
   wsl --install
   ```

2. **Open WSL terminal**

3. **Run the bash script:**
   ```bash
   chmod +x scripts/setup-cicd.sh
   ./scripts/setup-cicd.sh
   ```

---

## 🔧 Prerequisites for Windows

### Required Tools

1. **AWS CLI**
   ```powershell
   # Install via MSI installer
   # Download from: https://aws.amazon.com/cli/
   
   # Or via Chocolatey
   choco install awscli
   
   # Verify
   aws --version
   ```

2. **Terraform**
   ```powershell
   # Install via Chocolatey
   choco install terraform
   
   # Or download from: https://www.terraform.io/downloads
   
   # Verify
   terraform --version
   ```

3. **Docker Desktop**
   ```powershell
   # Download from: https://www.docker.com/products/docker-desktop
   
   # Verify
   docker --version
   ```

4. **Git**
   ```powershell
   # Install via installer
   # Download from: https://git-scm.com/download/win
   
   # Or via Chocolatey
   choco install git
   
   # Verify
   git --version
   ```

---

## 🚀 Quick Setup (PowerShell)

### Step 1: Configure AWS

```powershell
# Configure AWS CLI
aws configure

# Enter your credentials:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json

# Verify
aws sts get-caller-identity
```

### Step 2: Run Setup Script

```powershell
# Navigate to project root
cd path\to\Project_IS402

# Run PowerShell setup script
.\scripts\setup-cicd.ps1
```

The script will:
- ✅ Check prerequisites
- ✅ Create S3 bucket for Terraform state
- ✅ Create ECR repositories
- ✅ Configure Terraform backend
- ✅ Display GitHub secrets needed

### Step 3: Configure GitHub

1. **Go to GitHub repository**
   - Settings → Secrets and variables → Actions

2. **Add secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DB_PASSWORD`
   - `BACKEND_API_URL`

3. **Create environments:**
   - Settings → Environments
   - Create `development`
   - Create `production`

### Step 4: Deploy

```powershell
# Create dev branch
git checkout -b dev

# Push to trigger deployment
git push -u origin dev
```

---

## 🐛 Common Windows Issues

### Issue: "execution of scripts is disabled"

**Solution:**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the script again
.\scripts\setup-cicd.ps1
```

### Issue: "aws: command not found"

**Solution:**
```powershell
# Restart PowerShell after installing AWS CLI
# Or add to PATH manually:
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

# Verify
aws --version
```

### Issue: Line ending problems with bash scripts

**Solution:**
```powershell
# Convert line endings using Git
git config --global core.autocrlf true

# Or use dos2unix (if available)
dos2unix scripts/setup-cicd.sh
```

### Issue: Docker not running

**Solution:**
```powershell
# Start Docker Desktop
# Wait for it to fully start
# Check status
docker ps
```

### Issue: Terraform not found

**Solution:**
```powershell
# Add Terraform to PATH
$env:Path += ";C:\terraform"

# Or install via Chocolatey
choco install terraform

# Verify
terraform --version
```

---

## 📝 Manual Setup (If Scripts Fail)

If the automated scripts don't work, you can set up manually:

### 1. Create S3 Bucket

```powershell
# Get AWS Account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Create bucket
$BUCKET_NAME = "sweetdream-terraform-state-$AWS_ACCOUNT_ID"
aws s3 mb "s3://$BUCKET_NAME" --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning `
    --bucket "$BUCKET_NAME" `
    --versioning-configuration Status=Enabled
```

### 2. Create ECR Repositories

```powershell
# Backend repository
aws ecr create-repository `
    --repository-name sweetdream-backend `
    --region us-east-1 `
    --image-scanning-configuration scanOnPush=true `
    --encryption-configuration encryptionType=AES256

# Frontend repository
aws ecr create-repository `
    --repository-name sweetdream-frontend `
    --region us-east-1 `
    --image-scanning-configuration scanOnPush=true `
    --encryption-configuration encryptionType=AES256
```

### 3. Create Terraform Backend Config

```powershell
# Create backend.tf
$backendContent = @"
terraform {
  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
"@

$backendContent | Out-File -FilePath "terraform\backend.tf" -Encoding UTF8
```

### 4. Create terraform.tfvars

```powershell
# Copy example
Copy-Item "terraform\terraform.tfvars.example" "terraform\terraform.tfvars"

# Edit with your values
notepad terraform\terraform.tfvars
```

---

## ✅ Verification

After setup, verify everything:

```powershell
# Check AWS resources
aws s3 ls | Select-String "sweetdream-terraform-state"
aws ecr describe-repositories --query 'repositories[*].repositoryName'

# Check Terraform
cd terraform
terraform init
terraform validate
cd ..

# Check files
Test-Path terraform\backend.tf
Test-Path terraform\terraform.tfvars
```

---

## 🎯 Next Steps

After successful setup:

1. **Configure GitHub Secrets**
   - See [QUICK_START_CICD.md](./QUICK_START_CICD.md)

2. **Deploy Infrastructure**
   - Via GitHub Actions (recommended)
   - Or manually with Terraform

3. **Deploy Application**
   - Push to `dev` branch
   - Watch GitHub Actions

---

## 📚 Additional Resources

- [QUICK_START_CICD.md](./QUICK_START_CICD.md) - Quick start guide
- [SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md) - Complete checklist
- [CICD_GUIDE.md](./CICD_GUIDE.md) - Complete reference

---

## 💡 Tips for Windows Users

1. **Use PowerShell** - Native to Windows, no additional tools needed
2. **Run as Administrator** - Some operations may require elevated privileges
3. **Check PATH** - Ensure all tools are in your PATH
4. **Use Docker Desktop** - Easier than Docker Toolbox
5. **Git Bash alternative** - If you prefer bash scripts

---

**Need help?** Check the troubleshooting section above or refer to [CICD_GUIDE.md](./CICD_GUIDE.md)
