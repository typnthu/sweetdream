# Design Document: CI/CD Improvements

## Overview

Thiết kế cải tiến CI/CD pipeline cho SweetDream E-commerce Platform. Mục tiêu chính:
1. Liên kết CI và Deploy workflows - CI phải thành công trước khi Deploy
2. Hỗ trợ multi-environment deployment (dev và prod)
3. Đơn giản hóa bằng cách gộp workflows

## Architecture

### Current State (Hiện tại)
```
┌─────────────┐     ┌─────────────┐
│   ci.yml    │     │  deploy.yml │
│  (độc lập)  │     │  (độc lập)  │
└─────────────┘     └─────────────┘
      │                    │
      ▼                    ▼
   Build/Test         Deploy to AWS
   (không liên kết với deploy)
```

### Target State (Mục tiêu)
```
┌─────────────────────────────────────────────────────────┐
│                    ci-cd.yml (unified)                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐                                        │
│  │   Changes   │  ← Detect changed services             │
│  └──────┬──────┘                                        │
│         │                                               │
│         ▼                                               │
│  ┌─────────────┐                                        │
│  │     CI      │  ← Build, Test, Lint                   │
│  │  (matrix)   │                                        │
│  └──────┬──────┘                                        │
│         │                                               │
│         │ needs: ci (CI phải thành công)                │
│         ▼                                               │
│  ┌─────────────────────────────────────────────┐        │
│  │              Deploy                          │        │
│  │  ┌─────────────┐    ┌─────────────┐         │        │
│  │  │     DEV     │    │    PROD     │         │        │
│  │  │ (dev branch)│    │(main branch)│         │        │
│  │  │             │    │ + approval  │         │        │
│  │  └─────────────┘    └─────────────┘         │        │
│  └─────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### Branch Strategy
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Feature   │────▶│     dev     │────▶│    main     │
│   Branch    │ PR  │   branch    │ PR  │   branch    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ Development │     │ Production  │
                    │ Environment │     │ Environment │
                    │ (us-east-1) │     │ (us-west-2) │
                    └─────────────┘     └─────────────┘
```

## Components and Interfaces

### 1. Unified Workflow File (ci-cd.yml)

**Triggers:**
```yaml
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]
```

**Jobs Structure:**
```
jobs:
  changes        → Detect changed services
  ci-backend     → Build & test backend (needs: changes)
  ci-frontend    → Build & test frontend (needs: changes)
  ci-order       → Build & test order-service (needs: changes)
  ci-user        → Build & test user-service (needs: changes)
  ci-terraform   → Validate terraform (needs: changes)
  deploy-infra   → Deploy infrastructure (needs: ci-*)
  deploy-services → Deploy services (needs: deploy-infra)
```

### 2. Environment Configuration

| Environment | Branch | Region | Cluster | Approval |
|-------------|--------|--------|---------|----------|
| development | dev | us-east-1 | sweetdream-dev-cluster | No |
| production | main | us-west-2 | sweetdream-prod-cluster | Yes |

### 3. GitHub Environments Setup

**Development Environment:**
- Secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DB_PASSWORD
- Variables: AWS_REGION=us-east-1, ECS_CLUSTER=sweetdream-dev-cluster
- Protection: None

**Production Environment:**
- Secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DB_PASSWORD
- Variables: AWS_REGION=us-west-2, ECS_CLUSTER=sweetdream-prod-cluster
- Protection: Required reviewers, Deployment branches (main only)

### 4. Terraform Integration

```
terraform/
├── environments/
│   ├── dev/           ← Used when deploying to development
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/          ← Used when deploying to production
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── modules/           ← Shared modules
```

## Data Models

### Environment Matrix
```yaml
environment_config:
  development:
    branch: dev
    aws_region: us-east-1
    ecs_cluster: sweetdream-dev-cluster
    terraform_dir: terraform/environments/dev
    image_tag: dev
    requires_approval: false
    
  production:
    branch: main
    aws_region: us-west-2
    ecs_cluster: sweetdream-prod-cluster
    terraform_dir: terraform/environments/prod
    image_tag: latest
    requires_approval: true
```

### Service Matrix
```yaml
services:
  - name: backend
    path: be
    port: 3001
  - name: frontend
    path: fe
    port: 3000
  - name: order-service
    path: order-service
    port: 3002
  - name: user-service
    path: user-service
    port: 3003
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Dựa trên phân tích prework, tất cả các acceptance criteria đều liên quan đến cấu hình workflow và GitHub settings, không phải logic code có thể test bằng property-based testing. Các yêu cầu này được verify thông qua:

1. **Configuration Validation**: Kiểm tra cấu trúc YAML workflow
2. **Integration Testing**: Test thực tế bằng cách push code và quan sát behavior
3. **Manual Verification**: Kiểm tra GitHub environment settings

Do đó, không có correctness properties cần implement cho feature này.

## Error Handling

### CI Failures
- Khi CI job fail → Deploy jobs sẽ không chạy (do `needs` dependency)
- GitHub Actions tự động hiển thị failed status
- Notification qua email (nếu configured)

### Deploy Failures
- Khi Terraform fail → Service deployment sẽ không chạy
- Khi service deployment fail → Các service khác vẫn tiếp tục (fail-fast: false)
- ECS sẽ rollback nếu health check fail

### Environment Protection
- Production deployment bị block nếu không có approval
- Timeout sau 30 ngày nếu không có action

## Testing Strategy

### Workflow Validation
1. **YAML Syntax Check**: Sử dụng `actionlint` hoặc GitHub's built-in validation
2. **Dry Run**: Test workflow với `workflow_dispatch` trigger
3. **Branch Protection**: Verify PR checks are required

### Integration Testing
1. Push to `dev` branch → Verify deploys to development only
2. Push to `main` branch → Verify requires approval, deploys to production
3. Create PR → Verify CI runs but no deployment

### Manual Checklist
- [ ] CI jobs run before deploy jobs
- [ ] Deploy jobs have `needs: [ci-*]` dependency
- [ ] Environment selection based on branch
- [ ] Production requires approval
- [ ] Correct Terraform directory used per environment
- [ ] Correct ECR/ECS resources used per environment
