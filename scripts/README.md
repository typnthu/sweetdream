# SweetDream Blue-Green Deployment Scripts

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform installed
- Docker images pushed to ECR

### 1. Deploy New Version
```bash
# Linux/Mac
./blue-green-deploy.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:v2.0.0

# Windows
bash blue-green-deploy.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:v2.0.0
```

### 2. Emergency Rollback
```bash
# Linux/Mac
./rollback.sh

# Windows
bash rollback.sh
```

## 📊 Deployment Process

1. **Health Check**: Verify current environment
2. **Deploy to Inactive**: Start new version in inactive environment
3. **Health Validation**: Ensure new version is healthy
4. **Traffic Shift**: Gradually shift traffic (10% → 50% → 100%)
5. **Complete**: Stop old version tasks

## 🔧 Manual Operations

### Check Current Status
```bash
cd terraform
terraform output blue_green_summary
```

### Manual Traffic Shift
```bash
# Edit terraform.tfvars
blue_green_weights = {
  frontend = {
    blue  = 20   # 20% to blue
    green = 80   # 80% to green
  }
}

# Apply changes
terraform apply
```

### Manual Task Count Adjustment
```bash
# Edit terraform.tfvars
frontend_blue_green_counts = {
  blue  = 2   # 2 blue tasks
  green = 2   # 2 green tasks
}

# Apply changes
terraform apply
```

## 📈 Monitoring

- **CloudWatch Dashboard**: Check AWS Console → CloudWatch → Dashboards → "SweetDream-BlueGreen-Dashboard"
- **Alerts**: Configured for error rates and response times
- **Logs**: Separate log groups for blue and green environments

## 🚨 Troubleshooting

### Deployment Stuck
```bash
# Check ECS service status
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-frontend-blue sweetdream-service-frontend-green

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

### Health Check Failures
```bash
# Check ALB access logs
# Check application logs in CloudWatch
# Verify security group rules
```

### Emergency Procedures
1. **Immediate Rollback**: Run `./rollback.sh`
2. **Stop All Traffic**: Set both weights to 0 (manual intervention required)
3. **Scale Down**: Set task counts to 0 for problematic environment