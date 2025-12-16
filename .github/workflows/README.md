# GitHub Actions Workflows

Complete, production-ready CI/CD pipeline for the SweetDream e-commerce platform.

## Workflows

### 1. CI (`ci.yml`)
**Triggers**: Push/PR to master/dev branches  
**Purpose**: Continuous Integration - builds, tests, and validates code

**Features**:
- Smart change detection - only runs jobs for changed components
- Parallel execution for faster builds
- npm dependency caching
- PostgreSQL test database for backend tests
- TypeScript type checking
- Linting and code quality checks
- Security audits (npm audit)
- Terraform validation

**Components Tested**:
- Backend (with PostgreSQL integration tests)
- Frontend (build + lint + type check)
- Order Service (build + Prisma generation)
- User Service (build + Prisma generation)
- Terraform (format + validate)

**CI Summary**: Automatic summary table showing which components changed and their test results

---

### 2. Deploy to AWS (`deploy.yml`)
**Triggers**: 
- CI workflow completion (automatic, only on success)
- Manual dispatch with options

**Purpose**: Automated deployment to AWS ECS with zero-downtime

**Dependencies**: Only runs after CI workflow completes successfully

**Branch Strategy**:
- `main` branch → Production environment (us-west-2)
- `dev` branch → Development environment (us-east-1)

**Features**:
- Smart change detection - only deploys modified services
- Matrix strategy for parallel service deployment
- Infrastructure-first deployment (Terraform)
- Docker image tagging with commit SHA + latest
- ECS service health checks and wait for stability
- Environment-specific deployments (production/development)
- Force deploy option (manual trigger)
- Comprehensive deployment summary with service statuses

**Deployment Flow**:
1. **Detect Changes** - Identify modified services
2. **Deploy Infrastructure** - Apply Terraform changes (if needed)
3. **Build & Push Images** - Build Docker images in parallel, push to ECR
4. **Deploy to ECS** - Update ECS services with new images
5. **Wait for Stability** - Ensure services are healthy
6. **Summary** - Show deployment status and application URL

**Manual Deployment Options**:
- `environment`: Choose production or development
- `force_deploy`: Deploy all services regardless of changes

---

### 3. PR Checks (`pr-checks.yml`)
**Triggers**: Pull requests to master/dev  
**Purpose**: Fast validation before merge

**Features**:
- Terraform format validation
- Secret detection (prevents credential leaks)
- Security scanning with Trivy
- SARIF upload to GitHub Security tab
- Fast execution (< 2 minutes)

**Checks**:
- Terraform formatting
- No hardcoded AWS credentials
- Vulnerability scanning

---

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Code Push/PR                            │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌──────────────┐
│   PR Checks   │         │      CI      │
│  (< 2 min)    │         │  (3-8 min)   │
└───────────────┘         └──────┬───────┘
                                 │
                    ┌────────────┴────────────┐
                    │   CI Success Required     │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │   Deploy to AWS         │
                    │   1. Infrastructure     │
                    │   2. Services (Matrix)  │
                    │   3. Health Checks      │
                    └─────────────────────────┘
```

---

## Usage Examples

### Automatic Deployment
```bash
# Push to master branch
git push origin main

# Pipeline automatically:
# 1. Runs CI tests and validation
# 2. On CI success, triggers deployment
# 3. Detects changes
# 4. Deploys infrastructure (if Terraform changed)
# 5. Builds & deploys only changed services
# 6. Waits for services to stabilize
# 7. Shows deployment summary
```

### Manual Deployment
```bash
# Go to: Actions → Deploy to AWS → Run workflow

# Options:
# - Environment: production or development
# - Force Deploy: true (deploys all services)
```

### Database Migration
```bash
# Go to: Actions → Database Migration → Run workflow

# Options:
# - Environment: production or development
# - Action: deploy, seed, or reset
# - Service: backend, user-service, order-service, or all
```

### Create Pull Request
```bash
# Create PR to master/dev
# PR Checks automatically run:
# - Terraform format validation
# - Secret detection
# - Security scanning
```

---

## Configuration

### Required GitHub Secrets

Navigate to: **Settings → Secrets and variables → Actions → Secrets tab**

| Secret | Description | Required | Default if not set |
|--------|-------------|----------|-------------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | Yes | - |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | Yes | - |
| `DB_PASSWORD` | RDS PostgreSQL password | Yes | - |
| `DB_USERNAME` | RDS PostgreSQL username | Optional | `postgres` |
| `ALERT_EMAIL` | CloudWatch alerts email | Optional | `admin@example.com` |

### Optional GitHub Variables (Non-Sensitive Config)

Navigate to: **Settings → Secrets and variables → Actions → Variables tab**

| Variable | Description | Default if not set |
|----------|-------------|-------------------|
| `ENABLE_ANALYTICS` | Enable customer analytics | `false` |
| `LOG_RETENTION_DAYS` | CloudWatch log retention | `7` |
| `ANALYTICS_BUCKET_PREFIX` | S3 bucket prefix for analytics | `sweetdream-analytics` |

**Note:** Use **Variables** for non-sensitive config, **Secrets** for passwords/keys

### Required GitHub Environments

Create environments: **Settings → Environments**

1. **production**
   - Protection rules: Require approval (recommended)
   - Deployment branches: main only
   - AWS Region: us-west-2

2. **development**
   - Protection rules: None
   - Deployment branches: main, dev
   - AWS Region: us-east-1

---

## Performance Metrics

| Workflow | Duration | Optimization |
|----------|----------|--------------|
| PR Checks | ~2 min | Fast feedback loop |
| CI (no changes) | ~1 min | Smart change detection |
| CI (all changed) | ~5 min | Parallel execution |
| Deploy (1 service) | ~4 min | Matrix strategy |
| Deploy (all services) | ~8 min | Parallel builds + deploys |
| Database Migration | ~1 min | Direct ECS exec |

---

## Best Practices

### 1. **Branch Strategy**
- `main` → Production deployments (us-west-2)
- `dev` → Development deployments (us-east-1)
- Feature branches → PR checks only (no deployment)

### 2. **Commit Messages**
Use conventional commits for clarity:
```bash
feat(backend): add product search API
fix(frontend): resolve cart calculation bug
chore(terraform): update RDS instance type
```

### 3. **Change Detection**
Pipeline automatically detects changes in:
- `be/**` → Backend service
- `fe/**` → Frontend service
- `order-service/**` → Order service
- `user-service/**` → User service
- `terraform/**` → Infrastructure

### 4. **Deployment Safety**
- PR checks prevent broken code from merging
- CI validates all changes before deployment
- ECS health checks ensure zero-downtime
- Matrix strategy isolates service failures

### 5. **Monitoring**
- Check GitHub Actions summary for deployment status
- View ECS service health in AWS Console
- Monitor CloudWatch logs for errors

---

## Troubleshooting

### Deployment Fails
```bash
# Check ECS service events
aws ecs describe-services \
  --cluster sweetdream-cluster \
  --services sweetdream-service-backend

# View container logs
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow
```

### Terraform State Issues
```bash
# View current state
cd terraform
terraform state list

# Refresh state
terraform refresh -var="db_password=$DB_PASSWORD"
```

### Service Won't Stabilize
```bash
# Check task health
aws ecs describe-tasks \
  --cluster sweetdream-cluster \
  --tasks $(aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-service-backend --query 'taskArns[0]' --output text)
```

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

