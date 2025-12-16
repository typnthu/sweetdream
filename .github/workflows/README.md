# GitHub Actions Workflows

CI/CD pipeline cho SweetDream E-commerce Platform.

## 🔄 Workflows

### CI/CD Pipeline (`ci-cd.yml`)

**Unified workflow** kết hợp CI và CD trong một file duy nhất.

**Triggers:**
- Push to `main` → Deploy to Production (cần approval)
- Push to `dev` → Deploy to Development (tự động)
- Pull Request → Chỉ chạy CI, không deploy
- Manual dispatch → Chọn environment và force deploy

## 📊 Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Code Push/PR                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Change Detection                          │
│  Detect: backend, frontend, order-service, user-service,    │
│          terraform                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│   CI Jobs     │         │   CI Jobs     │
│  (parallel)   │         │  (parallel)   │
│ ┌───────────┐ │         │ ┌───────────┐ │
│ │ Backend   │ │         │ │ Terraform │ │
│ │ Frontend  │ │         │ └───────────┘ │
│ │ Order Svc │ │         └───────────────┘
│ │ User Svc  │ │
│ └───────────┘ │
└───────┬───────┘
        │
        │ needs: [ci-*] (CI phải pass)
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│                    Deploy Jobs                             │
│  (Chỉ chạy khi push, không chạy cho PR)                   │
│                                                            │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │  Development    │    │   Production    │               │
│  │  (dev branch)   │    │  (main branch)  │               │
│  │  Auto deploy    │    │  Need approval  │               │
│  │  us-east-1      │    │  us-west-2      │               │
│  └─────────────────┘    └─────────────────┘               │
└───────────────────────────────────────────────────────────┘
```

## 🌍 Environments

| Environment | Branch | Region | Approval | Terraform Dir |
|-------------|--------|--------|----------|---------------|
| development | dev | us-east-1 | No | terraform/environments/dev |
| production | main | us-west-2 | Yes | terraform/environments/prod |

## 🔐 Required Secrets

Cấu hình trong **Settings → Environments**:

### Development Environment
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Key |
| `DB_PASSWORD` | RDS PostgreSQL password |

### Production Environment
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Key |
| `DB_PASSWORD` | RDS PostgreSQL password |

**Xem chi tiết:** [ENVIRONMENTS_SETUP.md](../ENVIRONMENTS_SETUP.md)

## 🚀 Usage

### Automatic Deployment

```bash
# Deploy to Development
git checkout dev
git push origin dev

# Deploy to Production
git checkout main
git merge dev
git push origin main
# → Chờ approval trong GitHub Actions
```

### Manual Deployment

1. Vào **Actions** → **CI/CD Pipeline**
2. Click **Run workflow**
3. Chọn:
   - Environment: `development` hoặc `production`
   - Force deploy: `true` để deploy tất cả services

### Pull Request

```bash
# Tạo PR
git checkout -b feature/my-feature
git push origin feature/my-feature
# → Tạo PR trên GitHub
# → CI chạy tự động, không deploy
```

## 📈 Job Dependencies

```
changes
    │
    ├── ci-backend ────────┐
    ├── ci-frontend ───────┤
    ├── ci-order-service ──┼──► deploy-infrastructure ──► deploy-services
    ├── ci-user-service ───┤
    └── ci-terraform ──────┘
```

**Quan trọng:** Deploy jobs chỉ chạy khi TẤT CẢ CI jobs thành công (hoặc skipped).

## 🔧 Troubleshooting

### CI Failed
- Check logs của job failed
- Fix code và push lại
- Deploy sẽ không chạy cho đến khi CI pass

### Deploy Failed
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster sweetdream-dev-cluster \
  --services sweetdream-dev-service-backend

# View logs
aws logs tail /ecs/sweetdream-sweetdream-dev-service-backend --follow
```

### Production Approval Pending
1. Vào GitHub Actions
2. Click vào workflow run
3. Click **Review deployments**
4. Approve hoặc Reject

## 📊 Performance

| Stage | Duration |
|-------|----------|
| Change Detection | ~30s |
| CI (per service) | 2-4 min |
| Deploy Infrastructure | 3-5 min |
| Deploy Services | 4-8 min |
| **Total (all changed)** | **10-15 min** |

## 🗂️ Files

```
.github/
├── workflows/
│   ├── ci-cd.yml          # Main CI/CD pipeline
│   ├── pr-checks.yml      # PR validation (optional)
│   └── README.md          # This file
└── ENVIRONMENTS_SETUP.md  # Environment setup guide
```
