# SweetDream Deployment Scripts

## � Aviailable Scripts

### 🏗️ Infrastructure Setup
- `setup-s3-backends.sh` - Create S3 backends for Terraform state
- `deploy-dev.sh` - Deploy to development environment
- `deploy-prod.sh` - Deploy to production environment

### 🐳 Container Management  
- `create-ecr-repos.ps1` - Create ECR repositories
- `deploy-images.sh` - Build and push Docker images to ECR
- `deploy-images.ps1` - PowerShell version for Windows

## 🚀 Usage

### Initial Setup
```bash
# Create S3 backends for state management
./setup-s3-backends.sh

# Create ECR repositories
pwsh create-ecr-repos.ps1
```

### Deploy Images
```bash
# Build and push all Docker images
./deploy-images.sh

# Windows PowerShell
.\deploy-images.ps1
```

### Deploy Infrastructure
```bash
# Deploy to development
./deploy-dev.sh

# Deploy to production (with confirmation prompts)
./deploy-prod.sh
```

## ⚠️ Note

Most deployment scripts have been removed as the ECS infrastructure has been destroyed to save costs. Only essential scripts for ECR management and basic deployment remain.