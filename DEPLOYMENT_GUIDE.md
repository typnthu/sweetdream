# 🚀 SweetDream Deployment Guide

## Prerequisites

1. **AWS CLI configured** với credentials có quyền:
   - ECR: Push/Pull images
   - ECS: Update services, task definitions
   - CodeDeploy: Create deployments
   - CloudWatch: View logs

2. **Docker installed** và running

3. **Infrastructure deployed** (đã hoàn thành với Terraform)

## 🎯 Quick Deploy (Recommended)

### Deploy tất cả services:
```bash
# Deploy với manual update (nhanh)
./scripts/deploy-all.sh dev manual

# Deploy với CodeDeploy Blue-Green (production-ready)
./scripts/deploy-all.sh dev codedeploy
```

## 📋 Step-by-Step Deployment

### 1. Build và Push Images
```bash
# Make script executable
chmod +x ./scripts/deploy-images.sh

# Deploy all images to ECR
./scripts/deploy-images.sh
```

### 2. Update ECS Services

**Option A: Manual Update (Fast)**
```bash
chmod +x ./scripts/update-ecs-services.sh
./scripts/update-ecs-services.sh
```

**Option B: CodeDeploy Blue-Green (Frontend only)**
```bash
chmod +x ./scripts/codedeploy-frontend.sh
./scripts/codedeploy-frontend.sh dev
```

## 🌐 Access Application

- **Frontend:** http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com
- **Backend API:** http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com/api
- **Health Check:** http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com/api/health

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

## 🔄 CodeDeploy Blue-Green Deployment

### Monitor Deployment
```bash
# List deployments
aws deploy list-deployments \
  --application-name sweetdream-dev-service-frontend-codedeploy \
  --region us-east-1

# Get deployment status
aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --region us-east-1
```

### Rollback if needed
```bash
aws deploy stop-deployment \
  --deployment-id <deployment-id> \
  --auto-rollback-enabled \
  --region us-east-1
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

## 📈 Production Deployment

For production environment:
```bash
# Deploy to production (us-west-2)
cd terraform/environments/prod
terraform apply

# Update scripts for production
# Change AWS_REGION="us-west-2" in deploy scripts
# Change CLUSTER_NAME="sweetdream-prod-cluster"
```

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