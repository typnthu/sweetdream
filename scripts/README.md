# SweetDream Deployment Scripts

## Overview

This directory contains deployment and utility scripts for the SweetDream e-commerce platform. The project uses **GitHub Actions** for automated CI/CD, but these scripts are useful for local development, testing, and manual deployments.

## Deployment Strategy

**Primary Method:** GitHub Actions CI/CD Pipeline
- Push to `dev` branch → Auto-deploy to Development (us-east-1)
- Push to `master` branch → Auto-deploy to Production (us-west-2)
- Manual workflow dispatch available in GitHub Actions UI

**Secondary Method:** Local scripts for development and troubleshooting

## Available Scripts

### 🚀 Deployment Scripts

#### `setup-s3-backends.sh`
**One-time setup** - Creates S3 buckets for Terraform state storage

**Features:**
- Creates separate buckets for dev and prod environments
- Enables versioning for state file history
- Configures server-side encryption (AES256)
- Blocks public access for security
- Idempotent (safe to run multiple times)

**Usage:**
```bash
./scripts/setup-s3-backends.sh
```

**Creates:**
- `sweetdream-terraform-state-dev` (us-east-1)
- `sweetdream-terraform-state-prod` (us-west-2)

---

#### `build-and-deploy.sh` / `build-and-deploy.ps1`
**Complete deployment** - Builds Docker images and pushes to ECR

**Features:**
- Validates AWS credentials and Docker
- Logs into ECR automatically
- Builds all 4 services (backend, frontend, user-service, order-service)
- Tags images with environment and version
- Pushes to appropriate ECR repositories
- Cross-platform (Bash for Linux/Mac, PowerShell for Windows)

**Usage:**
```bash
# Linux/Mac
./scripts/build-and-deploy.sh [environment] [image_tag]

# Examples:
./scripts/build-and-deploy.sh dev latest
./scripts/build-and-deploy.sh prod v1.2.0

# Windows PowerShell
.\scripts\build-and-deploy.ps1 -Environment dev -ImageTag latest
.\scripts\build-and-deploy.ps1 -Environment prod -ImageTag v1.2.0
```

**Parameters:**
- `environment`: `dev` (default) or `prod`
- `image_tag`: Docker image tag (default: `latest`)

---

### 🔍 Validation Scripts

#### `validate-setup.sh` / `validate-setup.ps1`
**Prerequisites checker** - Validates your local environment

**Checks:**
- Docker installation and daemon status
- AWS CLI installation and version
- AWS credentials configuration
- Terraform installation
- Git installation
- Required permissions

**Usage:**
```bash
# Linux/Mac
./scripts/validate-setup.sh

# Windows PowerShell
.\scripts\validate-setup.ps1
```

**Output:**
- ✅ Green checkmarks for passed checks
- ❌ Red X for failed checks
- Suggestions for fixing issues

---

### 📊 Testing Scripts

#### `load-test-autoscaling.ps1`
**Load testing** - Tests ECS auto-scaling behavior

**Features:**
- Sends concurrent requests to test endpoints
- Monitors ECS service scaling
- Tracks response times and success rates
- Validates auto-scaling policies

**Usage:**
```powershell
# Windows PowerShell only
.\scripts\load-test-autoscaling.ps1 -AlbUrl "http://your-alb-url.amazonaws.com" -Duration 300
```

**Parameters:**
- `AlbUrl`: Your Application Load Balancer URL
- `Duration`: Test duration in seconds (default: 300)

---

## Quick Start Guide

### First-Time Setup

1. **Validate your environment:**
   ```bash
   ./scripts/validate-setup.sh
   ```

2. **Configure AWS credentials:**
   ```bash
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (us-east-1 for dev)
   ```

3. **Create S3 backends for Terraform:**
   ```bash
   ./scripts/setup-s3-backends.sh
   ```

4. **Deploy infrastructure via Terraform:**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform apply
   ```

### Regular Development Workflow

**Option 1: GitHub Actions (Recommended)**
```bash
# Make changes to code
git add .
git commit -m "Your changes"
git push origin dev  # Auto-deploys to development
```

**Option 2: Manual Local Deployment**
```bash
# Build and push images
./scripts/build-and-deploy.sh dev latest

# Update ECS services (Terraform will detect new images)
cd terraform/environments/dev
terraform apply -auto-approve
```

## Environment Configuration

### Development Environment
- **Region:** us-east-1
- **Cluster:** sweetdream-cluster
- **Services:** 
  - `sweetdream-dev-service-backend`
  - `sweetdream-dev-service-frontend`
  - `sweetdream-dev-service-user-service`
  - `sweetdream-dev-service-order-service`
- **Deployment:** Rolling updates
- **Resources:** Lower capacity (cost-optimized)

### Production Environment
- **Region:** us-west-2
- **Cluster:** sweetdream-cluster
- **Services:**
  - `sweetdream-prod-service-backend`
  - `sweetdream-prod-service-frontend`
  - `sweetdream-prod-service-user-service`
  - `sweetdream-prod-service-order-service`
- **Deployment:** Rolling updates (Blue/Green removed)
- **Resources:** Higher capacity, auto-scaling enabled

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Application Load Balancer            │
│                  (Public-facing, HTTPS)                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ├─────► Frontend (Port 3000)
                     │       └─► Calls backend services via proxy
                     │
┌────────────────────┴────────────────────────────────────┐
│              Service Discovery (sweetdream.local)        │
│                    (Internal DNS)                        │
└─────┬──────────────┬──────────────┬─────────────────────┘
      │              │              │
      ▼              ▼              ▼
  Backend      User Service   Order Service
 (Port 3001)   (Port 3003)    (Port 3002)
      │              │              │
      └──────────────┴──────────────┘
                     │
                     ▼
              RDS PostgreSQL
           (Private subnet)
```

**Key Points:**
- Only **Frontend** is exposed via ALB
- **Backend, User-Service, Order-Service** use Service Discovery (internal)
- Frontend proxies API requests to backend services
- All services connect to shared RDS database

## GitHub Actions Workflows

### `.github/workflows/deploy.yml`
**Main deployment pipeline:**

1. **Detect Changes** - Identifies which services changed
2. **Deploy Infrastructure** - Runs Terraform if infrastructure changed
3. **Check Initial Deployment** - Determines if services exist
4. **Deploy Services** - Builds and pushes Docker images for changed services
5. **Update Task Definitions** - Updates ECS task definitions via Terraform
6. **Redeploy Services** - Forces ECS to use new task definitions
7. **Summary** - Provides deployment status and URLs

**Triggers:**
- Push to `main`, `master`, or `dev` branches
- Manual workflow dispatch

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`
- `DB_USERNAME`
- `ALERT_EMAIL`

**Required Variables:**
- `AWS_REGION`
- `ENVIRONMENT`
- `CLUSTER_NAME`
- `S3_BUCKET_NAME`
- `LOG_RETENTION_DAYS`

### `.github/workflows/pr-checks.yml`
**Pull request validation:**
- Terraform validation
- Security scanning with Trivy
- Runs on all PRs

## Troubleshooting

### Common Issues

#### Docker not running
```bash
# Check Docker status
docker version

# Start Docker Desktop (GUI) or daemon
# Linux: sudo systemctl start docker
# Mac/Windows: Start Docker Desktop application
```

#### AWS credentials not configured
```bash
# Configure credentials
aws configure

# Verify
aws sts get-caller-identity
```

#### ECR login failed
```bash
# Get ECR login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Check region matches your environment
# Dev: us-east-1
# Prod: us-west-2
```

#### Service deployment stuck
```bash
# Check ECS service status
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-dev-service-backend --region us-east-1

# Check task logs
aws logs tail /ecs/sweetdream-backend --follow --region us-east-1

# Force new deployment
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-dev-service-backend --force-new-deployment --region us-east-1
```

#### Terraform state locked
```bash
# List DynamoDB lock table (if using)
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Script Permissions (Linux/Mac)

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or individually
chmod +x scripts/build-and-deploy.sh
chmod +x scripts/setup-s3-backends.sh
chmod +x scripts/validate-setup.sh
```

## Best Practices

### Development
- Always run `validate-setup` before first deployment
- Use `dev` environment for testing
- Tag images with meaningful versions (not just `latest`)
- Test locally with Docker Compose before deploying

### Production
- Never deploy directly to prod without testing in dev
- Use semantic versioning for image tags (v1.2.3)
- Review Terraform plan before applying
- Monitor CloudWatch logs after deployment
- Keep Terraform state in S3 (never local)

### Security
- Never commit AWS credentials to Git
- Use IAM roles with least privilege
- Enable MFA for AWS console access
- Rotate credentials regularly
- Use GitHub secrets for CI/CD credentials

### Cost Optimization
- Stop dev environment when not in use
- Use FARGATE_SPOT for non-critical workloads
- Set appropriate auto-scaling limits
- Clean up old ECR images (lifecycle policies)
- Monitor AWS Cost Explorer regularly

## Monitoring and Debugging

### Check Service Health
```bash
# List all services
aws ecs list-services --cluster sweetdream-cluster --region us-east-1

# Describe specific service
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-dev-service-backend --region us-east-1

# List running tasks
aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-dev-service-backend --region us-east-1
```

### View Logs
```bash
# Tail logs in real-time
aws logs tail /ecs/sweetdream-backend --follow --region us-east-1

# Get recent logs
aws logs tail /ecs/sweetdream-backend --since 1h --region us-east-1

# Filter logs
aws logs tail /ecs/sweetdream-backend --filter-pattern "ERROR" --region us-east-1
```

### Check ALB Health
```bash
# Get ALB URL
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `sweetdream`)].DNSName' --output text --region us-east-1

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-east-1
```

## Additional Resources

- [Main Project README](../README.md)
- [Terraform Documentation](../terraform/README.md)
- [GitHub Actions Workflows](../.github/workflows/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

## Support

For issues or questions:
1. Check this README and troubleshooting section
2. Review GitHub Actions workflow logs
3. Check AWS CloudWatch logs
4. Review Terraform plan output
5. Contact the DevOps team

---

**Last Updated:** December 2025  
**Maintained by:** SweetDream DevOps Team
