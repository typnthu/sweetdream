# CI/CD Setup Checklist

Complete checklist for setting up the SweetDream CI/CD pipeline on the dev branch.

## ✅ Prerequisites

- [ ] AWS Account created
- [ ] AWS CLI installed and configured
- [ ] GitHub account with repository access
- [ ] Docker installed locally
- [ ] Terraform >= 1.2 installed
- [ ] Node.js 18+ installed
- [ ] Git installed

## ✅ AWS Setup

### 1. Configure AWS CLI
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
```

- [ ] AWS CLI configured
- [ ] Credentials verified: `aws sts get-caller-identity`

### 2. Run Setup Script
```bash
chmod +x scripts/setup-cicd.sh
./scripts/setup-cicd.sh
```

- [ ] S3 bucket created for Terraform state
- [ ] ECR repositories created (backend & frontend)
- [ ] Terraform backend configured

### 3. Create IAM User for GitHub Actions
```bash
aws iam create-user --user-name github-actions-sweetdream
```

- [ ] IAM user created
- [ ] Policies attached:
  - [ ] AmazonECS_FullAccess
  - [ ] AmazonEC2ContainerRegistryFullAccess
  - [ ] AmazonRDSFullAccess
  - [ ] AmazonVPCFullAccess
  - [ ] AmazonS3FullAccess
  - [ ] CloudWatchLogsFullAccess

### 4. Generate Access Keys
```bash
aws iam create-access-key --user-name github-actions-sweetdream
```

- [ ] Access key ID saved
- [ ] Secret access key saved (securely!)

## ✅ GitHub Setup

### 1. Repository Configuration

- [ ] Repository forked/cloned
- [ ] Local repository up to date

### 2. Add Repository Secrets

Go to: `Settings → Secrets and variables → Actions → New repository secret`

- [ ] `AWS_ACCESS_KEY_ID` added
- [ ] `AWS_SECRET_ACCESS_KEY` added
- [ ] `DB_PASSWORD` added (e.g., `SecurePassword123!`)
- [ ] `BACKEND_API_URL` added (e.g., `http://backend.sweetdream.local:3001`)

### 3. Create Environments

Go to: `Settings → Environments`

**Development Environment:**
- [ ] Environment `development` created
- [ ] No protection rules (for faster deployment)
- [ ] Environment secrets added (if any)

**Production Environment:**
- [ ] Environment `production` created
- [ ] Protection rules configured:
  - [ ] Required reviewers enabled
  - [ ] Wait timer set (optional)
- [ ] Environment secrets added (if any)

### 4. Branch Protection (Optional)

Go to: `Settings → Branches → Add rule`

**For `dev` branch:**
- [ ] Require pull request reviews
- [ ] Require status checks to pass
- [ ] Require branches to be up to date

**For `main` branch:**
- [ ] Require pull request reviews (2+ reviewers)
- [ ] Require status checks to pass
- [ ] Require branches to be up to date
- [ ] Include administrators

## ✅ Terraform Configuration

### 1. Review Environment Files

- [ ] `terraform/environments/dev.tfvars` reviewed
- [ ] `terraform/environments/prod.tfvars` reviewed
- [ ] Database password strategy decided

### 2. Initialize Terraform (Optional - for local testing)

```bash
cd terraform
terraform init
terraform validate
cd ..
```

- [ ] Terraform initialized
- [ ] Terraform validated

## ✅ Git Configuration

### 1. Create Dev Branch

```bash
git checkout -b dev
git push -u origin dev
```

- [ ] `dev` branch created
- [ ] `dev` branch pushed to remote

### 2. Set Default Branch (Optional)

Go to: `Settings → Branches → Default branch`

- [ ] Default branch set to `dev` (for development focus)

## ✅ Initial Deployment

### 1. Verify Workflows

- [ ] All workflow files present in `.github/workflows/`:
  - [ ] `backend-ci.yml`
  - [ ] `frontend-ci.yml`
  - [ ] `integration-tests.yml`
  - [ ] `infrastructure.yml`
  - [ ] `deploy.yml`
  - [ ] `database-migration.yml`
  - [ ] `pr-checks.yml`

### 2. Deploy Infrastructure

**Option A: Via GitHub Actions (Recommended)**

1. Go to: `Actions → Infrastructure Deployment`
2. Click: `Run workflow`
3. Select:
   - Branch: `dev`
   - Action: `apply`
4. Click: `Run workflow`

- [ ] Infrastructure workflow started
- [ ] Infrastructure workflow completed successfully
- [ ] Resources created in AWS

**Option B: Manually**

```bash
cd terraform
terraform plan -var-file="environments/dev.tfvars" -var="db_password=YourPassword123!"
terraform apply -var-file="environments/dev.tfvars" -var="db_password=YourPassword123!"
cd ..
```

- [ ] Terraform plan reviewed
- [ ] Terraform apply completed
- [ ] Resources created in AWS

### 3. Deploy Application

**Automatic (on push to dev):**

```bash
git add .
git commit -m "feat: initial dev deployment"
git push origin dev
```

- [ ] Code pushed to `dev` branch
- [ ] CI workflows triggered
- [ ] Backend CI passed
- [ ] Frontend CI passed
- [ ] Integration tests passed
- [ ] Application deployment started
- [ ] Backend deployed to ECS
- [ ] Frontend deployed to ECS
- [ ] Database migrations completed

**Manual (via GitHub Actions):**

1. Go to: `Actions → Deploy Application`
2. Click: `Run workflow`
3. Select: Branch `dev`
4. Click: `Run workflow`

- [ ] Deployment workflow started
- [ ] Deployment workflow completed successfully

## ✅ Verification

### 1. Check GitHub Actions

- [ ] All workflows visible in Actions tab
- [ ] Latest workflow runs successful
- [ ] No failed jobs

### 2. Check AWS Resources

```bash
# Check ECS cluster
aws ecs describe-clusters --clusters sweetdream-cluster-dev

# Check ECS services
aws ecs describe-services \
  --cluster sweetdream-cluster-dev \
  --services sweetdream-service-dev-backend sweetdream-service-dev-frontend

# Check running tasks
aws ecs list-tasks --cluster sweetdream-cluster-dev

# Check RDS instance
aws rds describe-db-instances --query 'DBInstances[?DBName==`sweetdream_dev`]'
```

- [ ] ECS cluster exists and active
- [ ] Backend service running
- [ ] Frontend service running
- [ ] Tasks healthy
- [ ] RDS instance available

### 3. Check Application

```bash
# Get ALB URL
cd terraform
terraform output alb_url
cd ..

# Test frontend
curl -I <ALB_URL>

# Check logs
aws logs tail /ecs/sweetdream --follow
```

- [ ] ALB URL obtained
- [ ] Frontend accessible
- [ ] Backend responding (internal)
- [ ] Logs showing activity

### 4. Run Validation Script

```bash
chmod +x scripts/validate-cicd.sh
./scripts/validate-cicd.sh
```

- [ ] Validation script passed
- [ ] No errors reported

## ✅ Database Setup

### 1. Run Migrations

**Via GitHub Actions:**

1. Go to: `Actions → Database Migration`
2. Click: `Run workflow`
3. Select:
   - Environment: `development`
   - Migration type: `deploy`
4. Click: `Run workflow`

- [ ] Migration workflow completed
- [ ] Database schema created

### 2. Seed Database (Optional)

**Via GitHub Actions:**

1. Go to: `Actions → Database Migration`
2. Click: `Run workflow`
3. Select:
   - Environment: `development`
   - Migration type: `seed`
4. Click: `Run workflow`

- [ ] Seed workflow completed
- [ ] Test data populated

## ✅ Monitoring Setup

### 1. CloudWatch Logs

- [ ] Log groups created
- [ ] Logs streaming from ECS tasks
- [ ] No error messages in logs

### 2. CloudWatch Metrics

- [ ] Container Insights enabled
- [ ] Metrics visible in CloudWatch
- [ ] CPU/Memory metrics normal

### 3. ECS Service Health

- [ ] All tasks running
- [ ] Health checks passing
- [ ] No deployment failures

## ✅ Documentation

- [ ] README.md reviewed
- [ ] CICD_SUMMARY.md reviewed
- [ ] CICD_GUIDE.md reviewed
- [ ] DEV_SETUP.md reviewed
- [ ] Team members have access to documentation

## ✅ Team Onboarding

- [ ] Team members added to GitHub repository
- [ ] Team members have AWS console access (read-only)
- [ ] Team members trained on:
  - [ ] Git workflow (feature branches → dev → main)
  - [ ] Pull request process
  - [ ] CI/CD pipeline overview
  - [ ] How to view logs and metrics
  - [ ] How to run manual deployments
  - [ ] How to run database migrations

## ✅ Testing

### 1. Test Development Workflow

```bash
# Create feature branch
git checkout dev
git pull origin dev
git checkout -b feature/test-cicd

# Make a small change
echo "# Test" >> test.md
git add test.md
git commit -m "test: verify CI/CD pipeline"
git push origin feature/test-cicd
```

- [ ] Feature branch created
- [ ] Changes pushed
- [ ] Create pull request
- [ ] PR checks run automatically
- [ ] All checks passed

### 2. Test Merge and Deploy

- [ ] Merge PR to `dev`
- [ ] Deployment triggered automatically
- [ ] Deployment completed successfully
- [ ] Changes visible in application

### 3. Test Manual Operations

- [ ] Manual deployment works
- [ ] Manual migration works
- [ ] Manual infrastructure changes work

## ✅ Production Preparation (Optional)

### 1. Production Environment

- [ ] Production environment configured in GitHub
- [ ] Production secrets added
- [ ] Production protection rules enabled

### 2. Production Infrastructure

- [ ] `terraform/environments/prod.tfvars` configured
- [ ] Production database password set
- [ ] Production resources planned

### 3. Production Deployment Process

- [ ] Deployment process documented
- [ ] Rollback process documented
- [ ] Emergency contacts defined

## ✅ Final Checks

- [ ] All checklist items completed
- [ ] No errors in any workflow
- [ ] Application accessible and functional
- [ ] Database populated (if seeded)
- [ ] Monitoring working
- [ ] Team trained
- [ ] Documentation complete

## 🎉 Success Criteria

Your CI/CD pipeline is ready when:

1. ✅ Push to `dev` branch automatically deploys
2. ✅ All tests pass in CI
3. ✅ Application is accessible via ALB
4. ✅ Database migrations run automatically
5. ✅ Logs are visible in CloudWatch
6. ✅ Team can create PRs and merge
7. ✅ Manual operations work (migrations, deployments)

## 📞 Support

If you encounter issues:

1. Check [CICD_GUIDE.md](./CICD_GUIDE.md) troubleshooting section
2. Review CloudWatch logs
3. Check GitHub Actions logs
4. Run validation script: `./scripts/validate-cicd.sh`
5. Review AWS console for resource status

## 📚 Next Steps

After completing this checklist:

1. **Add Tests**: Write unit and integration tests
2. **Configure Monitoring**: Set up CloudWatch alarms
3. **Add Logging**: Implement structured logging
4. **Performance Testing**: Run load tests
5. **Security Hardening**: Review security groups and IAM policies
6. **Production Deployment**: Follow production checklist

---

**Estimated Time:** 30-45 minutes for complete setup

**Difficulty:** Intermediate

**Prerequisites:** AWS and GitHub knowledge

---

**Ready to start?** Begin with the Prerequisites section and work your way down! 🚀
