# Multi-Environment Deployment Guide

## 🌍 Architecture Overview

```
AWS Account (Single Account, Multi-Region)
├── us-east-1 (Development)
│   ├── VPC: 10.1.0.0/16
│   ├── ECS Cluster: sweetdream-dev-cluster
│   ├── CodeDeploy: sweetdream-frontend-dev
│   ├── S3 State: sweetdream-terraform-state-dev
│   └── Domain: dev.sweetdream.com
└── us-west-2 (Production)
    ├── VPC: 10.0.0.0/16
    ├── ECS Cluster: sweetdream-prod-cluster
    ├── CodeDeploy: sweetdream-frontend-prod
    ├── S3 State: sweetdream-terraform-state-prod
    └── Domain: prod.sweetdream.com
```

## 🚀 Quick Start

### 1. Setup S3 Backends
```bash
chmod +x scripts/setup-s3-backends.sh
./scripts/setup-s3-backends.sh
```

### 2. Deploy Development Environment
```bash
chmod +x scripts/deploy-dev.sh
./scripts/deploy-dev.sh
```

### 3. Deploy Production Environment
```bash
chmod +x scripts/deploy-prod.sh
./scripts/deploy-prod.sh
```

## 📁 Directory Structure

```
terraform/
├── modules/                    # Reusable modules
├── environments/
│   ├── dev/                   # Development (us-west-2)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── prod/                  # Production (us-east-1)
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
└── [main module files]        # Core infrastructure
```

## 🔧 Environment Differences

| Feature | Development | Production |
|---------|-------------|------------|
| **Region** | us-east-1 | us-west-2 |
| **VPC CIDR** | 10.1.0.0/16 | 10.0.0.0/16 |
| **Log Retention** | 3 days | 30 days |
| **Bastion Host** | Enabled | Disabled |
| **SSL Certificate** | None | ACM Certificate |
| **Image Tags** | :dev | :latest |
| **Scaling** | Min: 1, Max: 3 | Min: 2, Max: 10 |

## 🛠️ Manual Operations

### Deploy to Development
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Production
```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

### CodeDeploy Blue-Green Deployment

#### Development
```bash
./scripts/codedeploy-blue-green-deploy.sh \
  "123456789012.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:dev-v1.1.0" \
  "$(cd terraform/environments/dev && terraform output -raw frontend_task_definition_arn)"
```

#### Production
```bash
./scripts/codedeploy-blue-green-deploy.sh \
  "123456789012.dkr.ecr.us-west-2.amazonaws.com/sweetdream-frontend:v1.1.0" \
  "$(cd terraform/environments/prod && terraform output -raw frontend_task_definition_arn)"
```

## 🔐 Security Considerations

### Development Environment
- ✅ Bastion host enabled for debugging
- ✅ Shorter log retention (cost optimization)
- ✅ HTTP only (no SSL certificate required)
- ✅ Relaxed security groups for development

### Production Environment
- 🔒 Bastion host disabled
- 🔒 Extended log retention (compliance)
- 🔒 HTTPS with ACM certificate
- 🔒 Strict security groups
- 🔒 Deployment confirmation prompts

## 📊 Monitoring & Alerting

### Development
- **CloudWatch Dashboard**: SweetDream-BlueGreen-Dashboard-Dev
- **Alerts**: dev-alerts@sweetdream.com
- **Log Groups**: /ecs/sweetdream-dev-*

### Production
- **CloudWatch Dashboard**: SweetDream-BlueGreen-Dashboard-Prod
- **Alerts**: prod-alerts@sweetdream.com
- **Log Groups**: /ecs/sweetdream-prod-*

## 🌐 DNS & Domain Setup

### Route 53 Configuration (Optional)
```bash
# Development subdomain
dev.sweetdream.com → dev-alb-dns-name

# Production domain
prod.sweetdream.com → prod-alb-dns-name
```

## 💰 Cost Optimization

### Development
- Smaller instance sizes
- Shorter log retention
- Spot instances (optional)
- Auto-shutdown schedules (optional)

### Production
- Right-sized instances
- Reserved instances (optional)
- Extended monitoring
- Backup strategies

## 🔄 CI/CD Integration

### GitHub Actions Workflow Example
```yaml
name: Multi-Environment Deploy

on:
  push:
    branches:
      - develop  # Deploy to dev
      - main     # Deploy to prod

jobs:
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Development
        run: ./scripts/deploy-dev.sh

  deploy-prod:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Production
        run: ./scripts/deploy-prod.sh
```

## 🆘 Troubleshooting

### Common Issues

1. **S3 Backend Access Denied**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify S3 bucket exists
   aws s3 ls s3://sweetdream-terraform-state-dev
   ```

2. **Region Mismatch**
   ```bash
   # Ensure AWS CLI region matches environment
   aws configure get region
   ```

3. **ECR Repository Not Found**
   ```bash
   # Create ECR repositories in both regions
   aws ecr create-repository --repository-name sweetdream-frontend --region us-east-1
   aws ecr create-repository --repository-name sweetdream-frontend --region us-west-2
   ```

## 📝 Best Practices

1. **Always test in development first**
2. **Use specific image tags for production**
3. **Review Terraform plans before applying**
4. **Monitor costs across both environments**
5. **Implement proper backup strategies**
6. **Use infrastructure as code for all changes**

## 🎯 Next Steps

1. Setup CI/CD pipelines
2. Configure custom domains
3. Implement monitoring dashboards
4. Setup backup strategies
5. Configure auto-scaling policies
6. Implement security scanning