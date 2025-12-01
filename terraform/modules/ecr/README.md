# ECR Module

Creates and manages Amazon Elastic Container Registry (ECR) repositories for Docker images.

## Features

- ✅ Creates 4 ECR repositories (backend, frontend, user-service, order-service)
- ✅ Image scanning on push (security)
- ✅ AES256 encryption at rest
- ✅ Lifecycle policies (keeps last 10 images)
- ✅ Proper tagging for organization

## Repositories Created

1. **sweetdream-backend** - Backend service images
2. **sweetdream-frontend** - Frontend Next.js images
3. **sweetdream-user-service** - User authentication service images
4. **sweetdream-order-service** - Order processing service images

## Usage

```hcl
module "ecr" {
  source      = "./modules/ecr"
  environment = "production"
}
```

## Lifecycle Policy

Automatically deletes old images to save storage costs:
- Keeps the 10 most recent images
- Applies to all tags (including untagged)
- Runs daily

## Security

- **Image Scanning**: Enabled on push (detects vulnerabilities)
- **Encryption**: AES256 encryption at rest
- **IAM**: Requires proper AWS credentials to push/pull

## Outputs

- `backend_repository_url` - Backend ECR URL
- `frontend_repository_url` - Frontend ECR URL
- `user_service_repository_url` - User service ECR URL
- `order_service_repository_url` - Order service ECR URL
- `all_repository_urls` - Map of all URLs

## Cost Optimization

- Lifecycle policy prevents unlimited image accumulation
- Only 10 images per repository = ~$0.10/month per repo
- Total ECR cost: ~$0.40/month (4 repos × $0.10)

## Manual Creation Alternative

If you prefer to create ECR repos manually:

```powershell
.\scripts\create-ecr-repos.ps1
```

Then update `terraform/locals.tf` to use data sources instead of module.
