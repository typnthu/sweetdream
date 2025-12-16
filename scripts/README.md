# SweetDream Deployment Scripts & Guide

## Overview

This directory contains deployment scripts and documentation for the SweetDream e-commerce platform. **Note:** With the implementation of GitHub Actions CI/CD pipeline, most of these scripts are now legacy and primarily useful for local development and testing.

## Current Deployment Method

**Recommended:** Use GitHub Actions workflows for automated deployment:
- Push to `dev` branch → Automatic CI testing → Automatic deployment to development
- Push to `master` branch → Automatic CI testing → Automatic deployment to production
- Manual deployment via GitHub Actions interface

## Available Scripts (Legacy)

### Infrastructure Setup
- `setup-s3-backends.sh` - Create S3 backends for Terraform state
- `deploy-dev.sh` - Deploy to development environment
- `deploy-prod.sh` - Deploy to production environment

### Container Management  
- `create-ecr-repos.ps1` - Create ECR repositories
- `deploy-images.sh` - Build and push Docker images to ECR
- `deploy-images.ps1` - PowerShell version for Windows
- `build-and-deploy.sh` - Complete build and deploy script (Linux/Mac)
- `build-and-deploy.ps1` - Complete build and deploy script (Windows)

### Validation and Setup
- `validate-setup.sh` - Check prerequisites and system readiness (Linux/Mac)
- `validate-setup.ps1` - Check prerequisites and system readiness (Windows)
- `make-executable.sh` - Make shell scripts executable (Linux/Mac)

## Prerequisites

### Required Tools
- Docker Desktop (running)
- AWS CLI v2 (configured with credentials)
- Terraform (for infrastructure deployment)
- Git (for version control)

### AWS Configuration
```bash
# Configure AWS CLI with your credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

## Quick Start - GitHub Actions (Recommended)

### Automatic Deployment
```bash
# Push to development
git push origin dev
# → Triggers CI → On success, deploys to development environment

# Push to production
git push origin master
# → Triggers CI → On success, deploys to production environment
```

### Manual Deployment via GitHub Actions
1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Deploy to AWS** workflow
4. Click **Run workflow**
5. Choose environment (development/production)
6. Optionally enable **Force deploy** to deploy all services
7. Click **Run workflow**

## Legacy Manual Deployment

### Prerequisites Check (Recommended First Step)
```bash
# Linux/Mac - Check if system is ready for deployment
./scripts/validate-setup.sh

# Windows PowerShell
.\scripts\validate-setup.ps1
```

### Option 1: Complete Build and Deploy (Recommended)

**Linux/Mac:**
```bash
# Make scripts executable (first time only)
./scripts/make-executable.sh

# Deploy to development
./scripts/build-and-deploy.sh dev latest

# Deploy to production
./scripts/build-and-deploy.sh prod latest
```

**Windows PowerShell:**
```powershell
# Deploy to development
.\scripts\build-and-deploy.ps1 -Environment dev -ImageTag latest

# Deploy to production
.\scripts\build-and-deploy.ps1 -Environment prod -ImageTag latest
```

### Option 2: Step-by-Step Deployment

#### Step 1: Create ECR Repositories (First time only)
```powershell
# Windows only - creates ECR repositories
.\scripts\create-ecr-repos.ps1
```

#### Step 2: Build and Push Images
**Linux/Mac:**
```bash
./scripts/deploy-images.sh dev latest
./scripts/deploy-images.sh prod v1.0.0
```

**Windows:**
```powershell
.\scripts\deploy-images.ps1 -Environment dev -ImageTag latest
.\scripts\deploy-images.ps1 -Environment prod -ImageTag latest
```

#### Step 3: Deploy Infrastructure
```bash
# Development
./scripts/deploy-dev.sh

# Production (with confirmation prompts)
./scripts/deploy-prod.sh
```

## Script Details

### build-and-deploy.sh / build-and-deploy.ps1
**Most comprehensive script** - handles everything:
- Creates ECR repositories (if they don't exist)
- Sets up lifecycle policies (keeps 10 images)
- Builds all Docker images
- Pushes to ECR with proper tagging
- Provides deployment summary

**Usage:**
```bash
./build-and-deploy.sh [environment] [image_tag]

# Examples:
./build-and-deploy.sh                    # dev environment, latest tag
./build-and-deploy.sh prod               # prod environment, latest tag  
./build-and-deploy.sh dev v1.2.3         # dev environment, v1.2.3 tag
./build-and-deploy.sh prod release-1.0   # prod environment, release-1.0 tag
```

### deploy-images.sh / deploy-images.ps1
**Image-only deployment** - builds and pushes images:
- Assumes ECR repositories exist
- Builds all service images
- Pushes to ECR with environment-specific tags

### create-ecr-repos.ps1
**Repository setup** - creates ECR repositories:
- Creates all required ECR repositories
- Sets up lifecycle policies
- Configures image scanning
- Windows PowerShell only

### deploy-dev.sh / deploy-prod.sh
**Infrastructure deployment** - deploys Terraform:
- Initializes Terraform
- Plans and applies infrastructure
- Shows deployment outputs
- Production script includes confirmation prompts

## Environment Configuration

### Development Environment
- **Region:** us-east-1
- **ECR Repositories:** 
  - sweetdream-backend
  - sweetdream-frontend
  - sweetdream-user-service
  - sweetdream-order-service

### Production Environment
- **Region:** us-west-2
- **ECR Repositories:** Same as development
- **Additional:** Blue/Green deployment enabled

## GitHub Actions Integration

The project now uses GitHub Actions for automated CI/CD:

### Workflow Files
- `.github/workflows/ci.yml` - Continuous Integration (testing)
- `.github/workflows/deploy.yml` - Deployment to AWS
- `.github/workflows/pr-checks.yml` - Pull request validation

### Environment Variables Required
Set these in GitHub repository settings:

**Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`
- `DB_USERNAME`
- `ALERT_EMAIL`

**Variables:**
- `AWS_REGION`
- `ENVIRONMENT`
- `VPC_CIDR`
- `CLUSTER_NAME`
- `DB_NAME`
- `S3_BUCKET_NAME`
- `ENABLE_ANALYTICS`
- `LOG_RETENTION_DAYS`

## Troubleshooting

### Common Issues

**Docker not running:**
```bash
# Start Docker Desktop and wait for it to be ready
docker version
```

**AWS credentials not configured:**
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, and region
```

**ECR login failed:**
```bash
# Check AWS credentials and region
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1
```

**Build failures:**
```bash
# Check Docker daemon is running
docker info

# Check for syntax errors in Dockerfiles
docker build -t test ./be
```

### Script Permissions (Linux/Mac)
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or use the helper script
./scripts/make-executable.sh
```

### GitHub Actions Issues
```bash
# Check workflow status
gh run list --workflow=ci.yml

# View failed run details
gh run view [RUN_ID] --log-failed

# Manually trigger deployment
# Go to Actions → Deploy to AWS → Run workflow
```

## Next Steps After Deployment

1. **Verify ECR Images:**
   ```bash
   aws ecr list-images --repository-name sweetdream-backend --region us-east-1
   ```

2. **Check ECS Services:**
   ```bash
   aws ecs list-services --cluster sweetdream-cluster --region us-east-1
   ```

3. **Test Application:**
   - Check ALB URL from Terraform outputs
   - Test frontend and API endpoints
   - Verify all services are running

4. **Monitor Deployment:**
   - AWS ECS Console
   - CloudWatch Logs
   - ALB Target Group Health
   - GitHub Actions workflow results

## Security Notes

- ECR repositories use AES256 encryption
- Image scanning enabled on push
- Lifecycle policies limit image retention
- Production deployments require confirmation
- AWS credentials should use least privilege access
- GitHub secrets are encrypted and environment-scoped

## Cost Optimization

- Lifecycle policies automatically clean up old images
- Development environment uses rolling deployments
- Production uses blue/green (higher cost but zero downtime)
- Consider stopping development resources when not in use
- GitHub Actions provides free CI/CD minutes

## Migration from Scripts to GitHub Actions

If you're currently using the manual scripts and want to migrate to GitHub Actions:

1. **Set up GitHub environments** (development, production)
2. **Configure secrets and variables** in GitHub repository settings
3. **Test the workflows** with a small change
4. **Archive or remove** the manual deployment scripts
5. **Update team documentation** to use GitHub Actions workflow

## Legacy Script Cleanup

Since GitHub Actions now handles deployment, consider:

**Keep for local development:**
- `validate-setup.*` - Useful for new developers
- `setup-s3-backends.sh` - One-time setup utility

**Archive or remove:**
- `build-and-deploy.*` - Replaced by GitHub Actions
- `deploy-images.*` - Replaced by GitHub Actions
- `deploy-*.sh` - Replaced by GitHub Actions
- `create-ecr-repos.ps1` - Can be done via Terraform

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Main Project README](../README.md)