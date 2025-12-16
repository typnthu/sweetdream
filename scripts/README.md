# SweetDream Deployment Scripts

## Available Scripts

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

## Usage

### Prerequisites Check (Recommended First Step)
```bash
# Linux/Mac - Check if system is ready for deployment
./scripts/validate-setup.sh

# Windows PowerShell
.\scripts\validate-setup.ps1
```

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

### Complete Build and Deploy (Recommended)
```bash
# Complete build and deploy (creates ECR repos, builds images, pushes to ECR)
./build-and-deploy.sh [environment] [image_tag]

# Examples:
./build-and-deploy.sh dev latest
./build-and-deploy.sh prod v1.0.0

# Windows PowerShell
.\build-and-deploy.ps1 -Environment dev -ImageTag latest
.\build-and-deploy.ps1 -Environment prod -ImageTag v1.0.0
```

## Complete Documentation

For detailed deployment instructions, troubleshooting, and best practices, see:
**[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)**

## Note

The build-and-deploy scripts provide the most comprehensive functionality, including ECR repository creation, image building, and deployment. Use these for complete deployments.