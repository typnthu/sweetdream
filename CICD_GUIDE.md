# CI/CD Pipeline Guide

Complete guide for the SweetDream CI/CD pipeline using GitHub Actions and AWS.

## 📋 Table of Contents

- [Overview](#overview)
- [Pipeline Architecture](#pipeline-architecture)
- [Workflows](#workflows)
- [Setup Instructions](#setup-instructions)
- [Environment Configuration](#environment-configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The CI/CD pipeline automates:
- Infrastructure provisioning (Terraform)
- Application building and testing
- Container image creation and pushing to ECR
- Deployment to AWS ECS
- Database migrations
- Integration testing

## 🏗️ Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼────┐  ┌───▼────┐  ┌───▼────┐
   │   CI    │  │ Build  │  │ Deploy │
   │  Tests  │  │ Images │  │  ECS   │
   └─────────┘  └────┬───┘  └───┬────┘
                     │          │
              ┌──────▼──────────▼──────┐
              │     AWS ECR/ECS         │
              └─────────────────────────┘
```

## 🔄 Workflows

### 1. Infrastructure Deployment (`infrastructure.yml`)

**Triggers:**
- Push to `dev` or `main` branches (terraform changes)
- Pull requests (terraform changes)
- Manual dispatch

**Jobs:**
- Terraform format check
- Terraform validate
- Terraform plan (on PR)
- Terraform apply (on push to dev/main)
- Terraform destroy (manual only)

**Secrets Required:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 2. Backend CI (`backend-ci.yml`)

**Triggers:**
- Push to `dev` or `main` branches (backend changes)
- Pull requests (backend changes)

**Jobs:**
- Install dependencies
- Generate Prisma client
- Run linter
- Build TypeScript
- Run database migrations (test DB)
- Run tests
- Security audit

### 3. Frontend CI (`frontend-ci.yml`)

**Triggers:**
- Push to `dev` or `main` branches (frontend changes)
- Pull requests (frontend changes)

**Jobs:**
- Install dependencies
- Run linter
- Build Next.js application
- Run tests
- Security audit

### 4. Application Deployment (`deploy.yml`)

**Triggers:**
- Push to `dev` or `main` branches
- Manual dispatch

**Jobs:**
1. **Build & Push Backend**
   - Build Docker image
   - Push to ECR
   
2. **Build & Push Frontend**
   - Build Docker image with API URL
   - Push to ECR

3. **Deploy Backend**
   - Update ECS task definition
   - Deploy to ECS
   - Wait for stability

4. **Deploy Frontend**
   - Update ECS task definition
   - Deploy to ECS
   - Wait for stability

5. **Run Migrations**
   - Execute migrations on running ECS task

6. **Deployment Summary**
   - Generate deployment report

**Secrets Required:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `BACKEND_API_URL`

### 5. Integration Tests (`integration-tests.yml`)

**Triggers:**
- Push to `dev` or `main` branches
- Pull requests
- Manual dispatch

**Jobs:**
- Start PostgreSQL service
- Run backend migrations
- Seed test database
- Start backend server
- Test API endpoints
- Build and start frontend
- Test frontend health
- Run end-to-end tests

### 6. Database Migration (`database-migration.yml`)

**Triggers:**
- Manual dispatch only

**Inputs:**
- `environment`: development or production
- `migration_type`: deploy, seed, or reset

**Jobs:**
- Connect to ECS task
- Run specified migration command
- Generate migration report

## 🚀 Setup Instructions

### 1. AWS Prerequisites

1. **Create AWS Account** and configure IAM user with permissions:
   - ECS Full Access
   - ECR Full Access
   - RDS Full Access
   - VPC Full Access
   - S3 Full Access
   - CloudWatch Logs Full Access

2. **Generate AWS Access Keys**:
   ```bash
   aws iam create-access-key --user-name github-actions
   ```

### 2. GitHub Repository Setup

1. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):

   ```
   AWS_ACCESS_KEY_ID=<your-access-key-id>
   AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
   BACKEND_API_URL=http://backend.sweetdream.local:3001
   ```

2. **Configure Environments** (Settings → Environments):
   - Create `development` environment
   - Create `production` environment
   - Add protection rules for production

### 3. Terraform Backend Setup

1. **Create S3 bucket for Terraform state**:
   ```bash
   aws s3 mb s3://sweetdream-terraform-state --region us-east-1
   ```

2. **Enable versioning**:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket sweetdream-terraform-state \
     --versioning-configuration Status=Enabled
   ```

3. **Update `terraform/terraform.tf`**:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "sweetdream-terraform-state"
       key    = "terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

### 4. Initial Infrastructure Deployment

1. **Create `terraform/terraform.tfvars`**:
   ```hcl
   db_username = "admin"
   db_password = "YourSecurePassword123!"
   backend_image = "nginx:latest"  # Will be replaced by CI/CD
   frontend_image = "nginx:latest" # Will be replaced by CI/CD
   ```

2. **Manually deploy infrastructure first time**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Or use GitHub Actions**:
   - Go to Actions → Infrastructure Deployment
   - Click "Run workflow"
   - Select branch: `dev`
   - Action: `apply`

## 🔧 Environment Configuration

### Development Environment

**Branch:** `dev`

**Configuration:**
- Auto-deploy on push
- Runs all tests
- Uses development AWS resources
- Separate ECS cluster/services

### Production Environment

**Branch:** `main`

**Configuration:**
- Auto-deploy on push (with approval)
- Requires all tests to pass
- Uses production AWS resources
- Separate ECS cluster/services
- Manual approval required

## 📖 Usage

### Deploy to Development

```bash
# Make changes to code
git checkout dev
git add .
git commit -m "feat: add new feature"
git push origin dev
```

The pipeline will automatically:
1. Run tests
2. Build images
3. Deploy to development environment

### Deploy to Production

```bash
# Merge dev to main
git checkout main
git merge dev
git push origin main
```

The pipeline will automatically:
1. Run all tests
2. Build production images
3. Deploy to production (with approval)

### Run Database Migrations

1. Go to **Actions** → **Database Migration**
2. Click **Run workflow**
3. Select:
   - Environment: `development` or `production`
   - Migration type: `deploy`, `seed`, or `reset`
4. Click **Run workflow**

### Manual Deployment

1. Go to **Actions** → **Deploy Application**
2. Click **Run workflow**
3. Select branch: `dev` or `main`
4. Click **Run workflow**

### Infrastructure Changes

1. Make changes to Terraform files
2. Commit and push:
   ```bash
   git add terraform/
   git commit -m "infra: update ECS task size"
   git push origin dev
   ```

3. The pipeline will:
   - Run `terraform plan` on PR
   - Run `terraform apply` on merge to dev/main

## 🔍 Monitoring

### View Workflow Runs

1. Go to **Actions** tab in GitHub
2. Select workflow
3. View logs and status

### Check Deployment Status

```bash
# Check ECS services
aws ecs describe-services \
  --cluster sweetdream-cluster \
  --services sweetdream-service-backend sweetdream-service-frontend

# Check task status
aws ecs list-tasks --cluster sweetdream-cluster

# View logs
aws logs tail /ecs/sweetdream --follow
```

### Access Application

```bash
# Get ALB URL
cd terraform
terraform output alb_url

# Or from AWS Console
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `sweetdream`)].DNSName' \
  --output text
```

## 🐛 Troubleshooting

### Pipeline Fails at Build Stage

**Issue:** Docker build fails

**Solution:**
1. Check Dockerfile syntax
2. Verify dependencies in package.json
3. Check build logs in Actions

### Pipeline Fails at Deploy Stage

**Issue:** ECS deployment fails

**Solution:**
1. Check ECS service exists:
   ```bash
   aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend
   ```

2. Check task definition:
   ```bash
   aws ecs describe-task-definition --task-definition sweetdream-task-backend
   ```

3. View ECS events:
   ```bash
   aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend \
     --query 'services[0].events[0:5]'
   ```

### Migration Fails

**Issue:** Database migration fails

**Solution:**
1. Check database connectivity
2. Verify DATABASE_URL in ECS task
3. Check migration files in `be/prisma/migrations/`
4. Run migration manually:
   ```bash
   aws ecs execute-command \
     --cluster sweetdream-cluster \
     --task <task-arn> \
     --container sweetdream-backend \
     --interactive \
     --command "/bin/sh"
   ```

### Terraform State Lock

**Issue:** Terraform state is locked

**Solution:**
```bash
# Force unlock (use with caution)
cd terraform
terraform force-unlock <lock-id>
```

### ECR Authentication Fails

**Issue:** Cannot push to ECR

**Solution:**
1. Verify AWS credentials
2. Check ECR repository exists
3. Re-authenticate:
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   ```

## 🔒 Security Best Practices

1. **Secrets Management**
   - Never commit secrets to repository
   - Use GitHub Secrets for sensitive data
   - Rotate AWS access keys regularly

2. **IAM Permissions**
   - Use least privilege principle
   - Create separate IAM users for CI/CD
   - Enable MFA for production access

3. **Container Security**
   - Enable ECR image scanning
   - Use specific image tags (not `latest`)
   - Regularly update base images

4. **Network Security**
   - Use private subnets for ECS tasks
   - Configure security groups properly
   - Enable VPC Flow Logs

## 📊 Pipeline Metrics

Monitor these metrics:
- Build time
- Test coverage
- Deployment frequency
- Mean time to recovery (MTTR)
- Change failure rate

## 🎯 Next Steps

1. **Add E2E Tests**: Implement Playwright or Cypress tests
2. **Add Performance Tests**: Load testing with k6 or Artillery
3. **Add Monitoring**: Set up CloudWatch dashboards
4. **Add Alerts**: Configure SNS notifications
5. **Add Rollback**: Implement automatic rollback on failure

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Prisma Migrations](https://www.prisma.io/docs/concepts/components/prisma-migrate)

---

**Need Help?** Check the troubleshooting section or open an issue on GitHub.
