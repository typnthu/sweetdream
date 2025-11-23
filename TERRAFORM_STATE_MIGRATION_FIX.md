# 🔧 Terraform State Migration - Fix Guide

## Common Issues & Solutions

### Issue 1: "Backend configuration changed"

**Error:**
```
Error: Backend configuration changed
A change in the backend configuration has been detected, which may require migrating existing state.
```

**Solution:**
```powershell
cd terraform

# Option A: Reconfigure backend
terraform init -reconfigure

# Option B: Migrate state
terraform init -migrate-state
```

---

### Issue 2: "No existing state to migrate"

**Error:**
```
Terraform has detected that the configuration specified for the backend has changed.
Terraform will now check for existing state in the backends.
```

**Solution:** This means you don't have local state yet. Just run:
```powershell
terraform init
```

---

### Issue 3: "Backend initialization required"

**Error:**
```
Backend initialization required, please run "terraform init"
```

**Solution:**
```powershell
# Remove old backend config
Remove-Item -Recurse -Force .terraform

# Reinitialize
terraform init
```

---

### Issue 4: "State lock error"

**Error:**
```
Error acquiring the state lock
```

**Solution:**
```powershell
# Check if lock exists
aws dynamodb scan --table-name sweetdream-terraform-locks

# Force unlock (if you're sure no one else is running terraform)
terraform force-unlock <lock-id>
```

---

## Step-by-Step Migration (Safe Method)

### Step 1: Backup Current State

```powershell
cd terraform

# If you have local state, back it up
if (Test-Path "terraform.tfstate") {
    Copy-Item "terraform.tfstate" "terraform.tfstate.backup"
    Write-Host "✅ Backed up local state"
}
```

### Step 2: Check S3 Bucket Exists

```powershell
# Verify bucket exists
aws s3 ls s3://sweetdream-terraform-state-409964509537

# If not, create it
aws s3 mb s3://sweetdream-terraform-state-409964509537 --region us-east-1
```

### Step 3: Check DynamoDB Table Exists

```powershell
# Verify table exists
aws dynamodb describe-table --table-name sweetdream-terraform-locks

# If not, create it
aws dynamodb create-table `
  --table-name sweetdream-terraform-locks `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region us-east-1
```

### Step 4: Clean Terraform Directory

```powershell
# Remove old terraform files
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
```

### Step 5: Initialize with Backend

```powershell
# Initialize (will prompt to migrate if state exists)
terraform init

# If prompted "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### Step 6: Verify State in S3

```powershell
# Check if state was uploaded
aws s3 ls s3://sweetdream-terraform-state-409964509537/

# Download and verify
aws s3 cp s3://sweetdream-terraform-state-409964509537/terraform.tfstate terraform.tfstate.s3
```

---

## Alternative: Manual State Upload

If migration keeps failing, upload state manually:

### Step 1: Ensure Backend Config is Correct

Check `terraform/backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "sweetdream-terraform-state-409964509537"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sweetdream-terraform-locks"
  }
}
```

### Step 2: Upload State Manually

```powershell
cd terraform

# If you have local state
if (Test-Path "terraform.tfstate") {
    # Upload to S3
    aws s3 cp terraform.tfstate s3://sweetdream-terraform-state-409964509537/terraform.tfstate
    
    # Verify
    aws s3 ls s3://sweetdream-terraform-state-409964509537/
}
```

### Step 3: Reinitialize

```powershell
# Clean up
Remove-Item -Recurse -Force .terraform
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue

# Initialize with backend
terraform init
```

### Step 4: Verify

```powershell
# Check state
terraform state list

# Should show your resources
```

---

## If You Don't Have Local State Yet

If this is your first time and you haven't deployed infrastructure yet:

```powershell
cd terraform

# Just initialize
terraform init

# Deploy infrastructure
terraform apply -var="db_password=YourPassword"

# State will be automatically saved to S3
```

---

## Troubleshooting Commands

### Check Current Backend

```powershell
cd terraform
terraform init -backend=false
terraform providers
```

### View State Location

```powershell
# If using local state
Get-Content .terraform/terraform.tfstate | ConvertFrom-Json | Select-Object -ExpandProperty backend

# If using remote state
aws s3 ls s3://sweetdream-terraform-state-409964509537/
```

### Force Reconfigure

```powershell
cd terraform

# Nuclear option: start fresh
Remove-Item -Recurse -Force .terraform
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
terraform init -reconfigure
```

---

## Common Mistakes

### ❌ Wrong: Backend in terraform.tf

```hcl
# DON'T put backend in terraform.tf
terraform {
  required_providers { ... }
  backend "s3" { ... }  # ❌ Wrong location
}
```

### ✅ Correct: Backend in backend.tf

```hcl
# backend.tf (separate file)
terraform {
  backend "s3" {
    bucket = "sweetdream-terraform-state-409964509537"
    key    = "terraform.tfstate"
    region = "us-east-1"
    encrypt        = true
    dynamodb_table = "sweetdream-terraform-locks"
  }
}
```

---

## Quick Fix Script

Run this to fix most issues:

```powershell
cd terraform

Write-Host "🔧 Fixing Terraform backend..." -ForegroundColor Cyan

# 1. Backup local state if exists
if (Test-Path "terraform.tfstate") {
    Copy-Item "terraform.tfstate" "terraform.tfstate.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "✅ Backed up local state" -ForegroundColor Green
}

# 2. Clean terraform directory
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
Write-Host "✅ Cleaned .terraform directory" -ForegroundColor Green

# 3. Verify S3 bucket exists
$bucketExists = aws s3 ls s3://sweetdream-terraform-state-409964509537 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating S3 bucket..." -ForegroundColor Yellow
    aws s3 mb s3://sweetdream-terraform-state-409964509537 --region us-east-1
}
Write-Host "✅ S3 bucket ready" -ForegroundColor Green

# 4. Verify DynamoDB table exists
$tableExists = aws dynamodb describe-table --table-name sweetdream-terraform-locks 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating DynamoDB table..." -ForegroundColor Yellow
    aws dynamodb create-table `
      --table-name sweetdream-terraform-locks `
      --attribute-definitions AttributeName=LockID,AttributeType=S `
      --key-schema AttributeName=LockID,KeyType=HASH `
      --billing-mode PAY_PER_REQUEST `
      --region us-east-1
    Start-Sleep -Seconds 10
}
Write-Host "✅ DynamoDB table ready" -ForegroundColor Green

# 5. Initialize
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Terraform initialized successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: terraform plan" -ForegroundColor White
    Write-Host "2. Run: terraform apply" -ForegroundColor White
} else {
    Write-Host "❌ Initialization failed" -ForegroundColor Red
    Write-Host "Check the error message above" -ForegroundColor Yellow
}

cd ..
```

---

## What's Your Specific Error?

Copy the error message you're seeing and I'll provide the exact fix!

Common errors:
1. "Backend configuration changed"
2. "No existing state"
3. "State lock error"
4. "Bucket does not exist"
5. "Access denied"
6. "Invalid backend configuration"

---

## After Successful Migration

Verify everything works:

```powershell
cd terraform

# 1. Check state location
terraform state list

# 2. Verify state in S3
aws s3 ls s3://sweetdream-terraform-state-409964509537/

# 3. Test plan
terraform plan

# 4. Remove local state (if migration successful)
Remove-Item terraform.tfstate.backup -ErrorAction SilentlyContinue
```

---

**Need help?** Share the exact error message and I'll provide the specific fix!
