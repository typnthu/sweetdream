# SweetDream Complete Deployment Guide

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

## Quick Start - Complete Deployment

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
- **Region:** us-east-2
- **ECR Repositories:** Same as development
- **Additional:** Blue/Green deployment enabled

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

## Next Steps After Deployment

1. **Verify ECR Images:**
   ```bash
   aws ecr list-images --repository-name sweetdream-backend --region us-east-1
   ```

2. **Deploy Infrastructure:**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform apply
   ```

3. **Test Application:**
   - Check ALB URL from Terraform outputs
   - Test frontend and API endpoints
   - Verify all services are running

4. **Monitor Deployment:**
   - AWS ECS Console
   - CloudWatch Logs
   - ALB Target Group Health

## Security Notes

- ECR repositories use AES256 encryption
- Image scanning enabled on push
- Lifecycle policies limit image retention
- Production deployments require confirmation
- AWS credentials should use least privilege access

## Cost Optimization

- Lifecycle policies automatically clean up old images
- Development environment uses rolling deployments
- Production uses blue/green (higher cost but zero downtime)
- Consider stopping development resources when not in use