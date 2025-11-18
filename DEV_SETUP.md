# Development Environment Setup

Quick guide to set up and deploy to the development environment on the `dev` branch.

## Prerequisites

- AWS Account with CLI configured
- GitHub account with repository access
- Docker installed locally
- Terraform >= 1.2 installed

## Step 1: Configure AWS

```bash
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

## Step 2: Run Setup Script

```bash
# Make script executable
chmod +x scripts/setup-cicd.sh

# Run setup
./scripts/setup-cicd.sh
```

This script will:
- Create S3 bucket for Terraform state
- Create ECR repositories
- Configure Terraform backend
- Display GitHub secrets needed

## Step 3: Configure GitHub

### Add Repository Secrets

Go to: `Settings → Secrets and variables → Actions → New repository secret`

Add these secrets:

1. **AWS_ACCESS_KEY_ID**
   - Your AWS access key ID

2. **AWS_SECRET_ACCESS_KEY**
   - Your AWS secret access key

3. **DB_PASSWORD**
   - Database password (e.g., `SecurePassword123!`)

4. **BACKEND_API_URL**
   - For dev: `http://backend.sweetdream.local:3001`

### Create Environments

Go to: `Settings → Environments`

1. **Create `development` environment**
   - No protection rules needed
   - Add environment-specific secrets if needed

2. **Create `production` environment**
   - Enable "Required reviewers"
   - Add production-specific secrets

## Step 4: Create Dev Branch

```bash
# Create and checkout dev branch
git checkout -b dev

# Push to remote
git push -u origin dev
```

## Step 5: Deploy Infrastructure

### Option A: Via GitHub Actions (Recommended)

1. Go to **Actions** tab
2. Select **Infrastructure Deployment** workflow
3. Click **Run workflow**
4. Select:
   - Branch: `dev`
   - Action: `apply`
5. Click **Run workflow**

### Option B: Manually

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev.tfvars" -var="db_password=YourPassword123!"

# Apply infrastructure
terraform apply -var-file="environments/dev.tfvars" -var="db_password=YourPassword123!"

# Save outputs
terraform output > ../terraform-outputs.txt
```

## Step 6: Deploy Application

Once infrastructure is ready:

```bash
# Make a change to trigger deployment
git add .
git commit -m "feat: initial dev deployment"
git push origin dev
```

This will automatically:
1. Run CI tests
2. Build Docker images
3. Push to ECR
4. Deploy to ECS
5. Run database migrations

## Step 7: Verify Deployment

### Check GitHub Actions

1. Go to **Actions** tab
2. Watch the **Deploy Application** workflow
3. Wait for all jobs to complete

### Check AWS Resources

```bash
# Get ALB URL
cd terraform
terraform output alb_url

# Check ECS services
aws ecs describe-services \
  --cluster sweetdream-cluster-dev \
  --services sweetdream-service-dev-backend sweetdream-service-dev-frontend

# Check running tasks
aws ecs list-tasks --cluster sweetdream-cluster-dev

# View logs
aws logs tail /ecs/sweetdream --follow
```

### Access Application

```bash
# Get the ALB URL
ALB_URL=$(cd terraform && terraform output -raw alb_url)

# Test backend (internal)
curl http://backend.sweetdream.local:3001/health

# Test frontend
curl $ALB_URL
```

## Step 8: Run Database Migrations

If migrations didn't run automatically:

1. Go to **Actions** → **Database Migration**
2. Click **Run workflow**
3. Select:
   - Environment: `development`
   - Migration type: `deploy`
4. Click **Run workflow**

## Step 9: Seed Database (Optional)

To populate with test data:

1. Go to **Actions** → **Database Migration**
2. Click **Run workflow**
3. Select:
   - Environment: `development`
   - Migration type: `seed`
4. Click **Run workflow**

## Validation

Run the validation script to check everything:

```bash
chmod +x scripts/validate-cicd.sh
./scripts/validate-cicd.sh
```

## Common Issues

### Issue: Terraform state lock

**Solution:**
```bash
cd terraform
terraform force-unlock <lock-id>
```

### Issue: ECR authentication failed

**Solution:**
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### Issue: ECS tasks not starting

**Solution:**
1. Check ECS console for error messages
2. Verify security groups allow traffic
3. Check CloudWatch logs:
   ```bash
   aws logs tail /ecs/sweetdream --follow
   ```

### Issue: Database connection failed

**Solution:**
1. Verify RDS is running
2. Check security group rules
3. Verify DATABASE_URL in ECS task definition

## Development Workflow

### Making Changes

```bash
# Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/my-feature

# Make changes
# ... edit files ...

# Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

### Create Pull Request

1. Go to GitHub repository
2. Click **Pull requests** → **New pull request**
3. Base: `dev`, Compare: `feature/my-feature`
4. Create pull request
5. Wait for CI checks to pass
6. Merge when ready

### Automatic Deployment

When you merge to `dev`:
- CI tests run automatically
- If tests pass, deployment starts
- Application updates automatically

## Monitoring

### View Logs

```bash
# Backend logs
aws logs tail /ecs/sweetdream --follow --filter-pattern "backend"

# Frontend logs
aws logs tail /ecs/sweetdream --follow --filter-pattern "frontend"

# All logs
aws logs tail /ecs/sweetdream --follow
```

### Check Service Health

```bash
# ECS service status
aws ecs describe-services \
  --cluster sweetdream-cluster-dev \
  --services sweetdream-service-dev-backend sweetdream-service-dev-frontend \
  --query 'services[*].[serviceName,status,runningCount,desiredCount]' \
  --output table

# Task health
aws ecs describe-tasks \
  --cluster sweetdream-cluster-dev \
  --tasks $(aws ecs list-tasks --cluster sweetdream-cluster-dev --query 'taskArns[0]' --output text) \
  --query 'tasks[*].[taskArn,lastStatus,healthStatus]' \
  --output table
```

### CloudWatch Metrics

Go to AWS Console → CloudWatch → Container Insights:
- CPU utilization
- Memory utilization
- Network traffic
- Task count

## Cleanup

To destroy the development environment:

### Via GitHub Actions

1. Go to **Actions** → **Infrastructure Deployment**
2. Click **Run workflow**
3. Select:
   - Branch: `dev`
   - Action: `destroy`
4. Click **Run workflow**

### Manually

```bash
cd terraform
terraform destroy -var-file="environments/dev.tfvars" -var="db_password=YourPassword123!"
```

**Warning:** This will delete all resources including the database!

## Next Steps

1. **Add Tests**: Write unit and integration tests
2. **Configure Monitoring**: Set up CloudWatch alarms
3. **Add Logging**: Implement structured logging
4. **Performance Testing**: Run load tests
5. **Security Hardening**: Review security groups and IAM policies

## Resources

- [CI/CD Guide](./CICD_GUIDE.md) - Complete CI/CD documentation
- [Terraform README](./terraform/README.md) - Infrastructure details
- [Backend README](./be/README.md) - API documentation
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS ECS Docs](https://docs.aws.amazon.com/ecs/)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Check GitHub Actions logs
4. Review [CICD_GUIDE.md](./CICD_GUIDE.md)

---

**Ready to deploy?** Follow the steps above and your dev environment will be live in ~15 minutes! 🚀
