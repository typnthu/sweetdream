# Quick Start - CI/CD Pipeline

Get the SweetDream CI/CD pipeline running in 15 minutes.

## ⚡ Prerequisites (5 minutes)

1. **AWS Account** - Have credentials ready
2. **GitHub Account** - Repository access
3. **Tools Installed:**
   - AWS CLI
   - Docker
   - Terraform >= 1.2
   - Git

## 🚀 Setup (10 minutes)

### Step 1: Configure AWS (2 minutes)

```bash
# Configure AWS CLI
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# Verify
aws sts get-caller-identity
```

### Step 2: Run Setup Script (3 minutes)

```bash
# Make executable
chmod +x scripts/setup-cicd.sh

# Run setup
./scripts/setup-cicd.sh
```

**This creates:**
- S3 bucket for Terraform state
- ECR repositories (backend & frontend)
- Terraform backend configuration

### Step 3: Configure GitHub (3 minutes)

**Add Secrets:** `Settings → Secrets and variables → Actions`

```
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
DB_PASSWORD=SecurePassword123!
BACKEND_API_URL=http://backend.sweetdream.local:3001
```

**Create Environments:** `Settings → Environments`
- Create `development` environment
- Create `production` environment

### Step 4: Deploy (2 minutes)

```bash
# Create dev branch
git checkout -b dev

# Push to trigger deployment
git push -u origin dev
```

**Or manually deploy infrastructure:**

Go to: `Actions → Infrastructure Deployment → Run workflow`
- Branch: `dev`
- Action: `apply`

## ✅ Verify (5 minutes)

### Check Workflows

Go to: `Actions` tab
- All workflows should be visible
- Latest runs should be successful

### Check AWS

```bash
# Check ECS cluster
aws ecs describe-clusters --clusters sweetdream-cluster-dev

# Check services
aws ecs describe-services \
  --cluster sweetdream-cluster-dev \
  --services sweetdream-service-dev-backend sweetdream-service-dev-frontend

# Get ALB URL
cd terraform
terraform output alb_url
```

### Run Validation

```bash
chmod +x scripts/validate-cicd.sh
./scripts/validate-cicd.sh
```

## 🎯 What You Get

After setup, you have:

✅ **7 Automated Workflows:**
- PR Checks
- Backend CI
- Frontend CI
- Integration Tests
- Infrastructure Deployment
- Application Deployment
- Database Migration

✅ **Automatic Deployment:**
- Push to `dev` → Auto-deploy to development
- Push to `main` → Auto-deploy to production

✅ **Complete Testing:**
- Linting and formatting
- Unit tests
- Integration tests
- Security scanning

✅ **Infrastructure as Code:**
- Terraform managed
- Environment separation
- Version controlled

## 📖 Next Steps

1. **Make a change:**
   ```bash
   git checkout -b feature/test
   echo "# Test" >> test.md
   git add test.md
   git commit -m "test: verify pipeline"
   git push origin feature/test
   ```

2. **Create Pull Request:**
   - Go to GitHub
   - Create PR to `dev`
   - Watch CI checks run

3. **Merge and Deploy:**
   - Merge PR
   - Watch automatic deployment

4. **Access Application:**
   ```bash
   cd terraform
   terraform output alb_url
   # Visit the URL in browser
   ```

## 🐛 Troubleshooting

### Issue: AWS credentials not working
```bash
aws sts get-caller-identity
# Should show your account info
```

### Issue: Terraform fails
```bash
cd terraform
terraform init
terraform validate
```

### Issue: Deployment fails
```bash
# Check ECS logs
aws logs tail /ecs/sweetdream --follow

# Check ECS service
aws ecs describe-services \
  --cluster sweetdream-cluster-dev \
  --services sweetdream-service-dev-backend
```

### Issue: Can't access application
```bash
# Get ALB URL
cd terraform
terraform output alb_url

# Check if ALB is healthy
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## 📚 Documentation

For detailed information:

- [SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md) - Complete checklist
- [DEV_SETUP.md](./DEV_SETUP.md) - Detailed setup guide
- [CICD_GUIDE.md](./CICD_GUIDE.md) - Complete CI/CD guide
- [CICD_SUMMARY.md](./CICD_SUMMARY.md) - Pipeline overview

## 💡 Tips

1. **Use dev branch for testing** - It's faster and safer
2. **Check Actions tab** - Monitor all workflow runs
3. **Review logs** - CloudWatch has all application logs
4. **Run validation** - Use `validate-cicd.sh` regularly
5. **Read documentation** - Comprehensive guides available

## 🎉 Success!

If you can:
- ✅ Push to `dev` and see deployment
- ✅ Access application via ALB URL
- ✅ See logs in CloudWatch
- ✅ Run validation script successfully

**You're ready to develop!** 🚀

---

**Time to Complete:** ~15 minutes

**Difficulty:** Easy (with prerequisites)

**Support:** Check [CICD_GUIDE.md](./CICD_GUIDE.md) for help
