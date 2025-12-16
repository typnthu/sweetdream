# 🚀 SweetDream Deployment Guide

## Prerequisites

1. **AWS CLI configured** với credentials có quyền:
   - ECR: Push/Pull images
   - ECS: Update services, task definitions
   - CloudWatch: View logs

2. **Docker installed** và running

3. **Infrastructure deployed** (sử dụng Terraform)

## 🎯 Quick Deploy (Recommended)

### Deploy Images to ECR:
```bash
# Build and push all Docker images
./scripts/deploy-images.sh

# Windows PowerShell
.\scripts\deploy-images.ps1
```

### Deploy Infrastructure:
```bash
# Deploy development environment
./scripts/deploy-dev.sh

# Deploy production environment (with confirmation)
./scripts/deploy-prod.sh
```

## 📋 Step-by-Step Deployment

### 1. Setup S3 Backends (First Time Only)
```bash
chmod +x ./scripts/setup-s3-backends.sh
./scripts/setup-s3-backends.sh
```

### 2. Create ECR Repositories (First Time Only)
```bash
# Windows PowerShell
pwsh ./scripts/create-ecr-repos.ps1
```

### 3. Build và Push Images
```bash
# Make script executable
chmod +x ./scripts/deploy-images.sh

# Deploy all images to ECR
./scripts/deploy-images.sh
```

### 4. Deploy Infrastructure
```bash
# Development environment
./scripts/deploy-dev.sh

# Production environment (requires confirmation)
./scripts/deploy-prod.sh
```

## 🌐 Access Application

**Development Environment:**
- **Frontend:** http://dev-alb-dns-name (from terraform output)
- **Backend API:** http://dev-alb-dns-name/api

**Production Environment:**
- **Frontend:** http://prod-alb-dns-name (from terraform output)
- **Backend API:** http://prod-alb-dns-name/api

## 📊 Monitoring & Debugging

### Check Service Status
```bash
aws ecs describe-services \
  --region us-east-1 \
  --cluster sweetdream-dev-cluster \
  --services sweetdream-dev-service-frontend sweetdream-dev-service-backend
```

### View Logs
```bash
# Frontend logs
aws logs tail /ecs/sweetdream-frontend --region us-east-1 --follow

# Backend logs  
aws logs tail /ecs/sweetdream-sweetdream-dev-service-backend --region us-east-1 --follow
```

### Scale Services
```bash
aws ecs update-service \
  --region us-east-1 \
  --cluster sweetdream-dev-cluster \
  --service sweetdream-dev-service-frontend \
  --desired-count 3
```

## 🔄 Infrastructure Management

### Check Terraform State
```bash
# Development
cd terraform/environments/dev
terraform state list

# Production  
cd terraform/environments/prod
terraform state list
```

### Update Infrastructure
```bash
# Development
cd terraform/environments/dev
terraform plan
terraform apply

# Production
cd terraform/environments/prod
terraform plan
terraform apply
```

## 🐛 Troubleshooting

### Common Issues:

1. **ECR Login Failed**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 409964509537.dkr.ecr.us-east-1.amazonaws.com
   ```

2. **Service Won't Start**
   - Check task definition
   - Verify image exists in ECR
   - Check CloudWatch logs

3. **Load Balancer 503 Error**
   - Verify target group health
   - Check security group rules
   - Ensure containers are listening on correct ports

4. **CodeDeploy Failed**
   - Check deployment logs in AWS Console
   - Verify task definition is valid
   - Ensure target groups are healthy

## 📈 Multi-Environment Setup

The project supports both development and production environments:

- **Development**: us-east-1 region
- **Production**: us-west-2 region

Each environment has its own:
- Terraform state in separate S3 buckets
- ECR repositories
- VPC and networking
- ECS clusters and services

See `MULTI_ENVIRONMENT_GUIDE.md` for detailed setup instructions.

## 🔐 Security Notes

- All services run in private subnets
- Only ALB is internet-facing
- Service-to-service communication via service discovery
- Database access restricted to ECS security group
- No bastion host (disabled for cost optimization)

## 📞 Support

If you encounter issues:
1. Check CloudWatch logs
2. Verify AWS permissions
3. Ensure Docker is running
4. Check network connectivity