# GitHub Environments Setup Guide

Hướng dẫn cấu hình GitHub Environments cho CI/CD pipeline của SweetDream.

## 📋 Tổng quan

Pipeline sử dụng 2 GitHub Environments:
- **development**: Deploy tự động khi push vào `dev` branch
- **production**: Deploy khi push vào `main` branch, yêu cầu approval

## 🔧 Cách tạo Environments

1. Vào repository trên GitHub
2. Click **Settings** → **Environments**
3. Click **New environment**

---

## 🟢 Development Environment

### Tạo Environment
- Name: `development`
- Click **Configure environment**

### Secrets (Required)

| Secret | Mô tả | Ví dụ |
|--------|-------|-------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key cho dev account | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Key cho dev account | `wJalr...` |
| `DB_PASSWORD` | Password cho RDS PostgreSQL dev | `your-dev-db-password` |

### Secrets (Optional)

| Secret | Mô tả | Default |
|--------|-------|---------|
| `DB_USERNAME` | Username cho RDS PostgreSQL | `postgres` |

### Variables (Optional)

| Variable | Mô tả | Default |
|----------|-------|---------|
| `AWS_REGION` | AWS Region | `us-east-1` |
| `ECS_CLUSTER` | ECS Cluster name | `sweetdream-dev-cluster` |

### Protection Rules
- **Không cần** cấu hình protection rules cho development
- Deploy tự động khi CI pass

---

## 🔴 Production Environment

### Tạo Environment
- Name: `production`
- Click **Configure environment**

### Secrets (Required)

| Secret | Mô tả | Ví dụ |
|--------|-------|-------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key cho prod account | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Key cho prod account | `wJalr...` |
| `DB_PASSWORD` | Password cho RDS PostgreSQL prod | `your-prod-db-password` |

### Secrets (Optional)

| Secret | Mô tả | Default |
|--------|-------|---------|
| `DB_USERNAME` | Username cho RDS PostgreSQL | `postgres` |

### Variables (Optional)

| Variable | Mô tả | Default |
|----------|-------|---------|
| `AWS_REGION` | AWS Region | `us-west-2` |
| `ECS_CLUSTER` | ECS Cluster name | `sweetdream-prod-cluster` |

### Protection Rules (QUAN TRỌNG)

1. **Required reviewers**: 
   - Check ✅ "Required reviewers"
   - Thêm ít nhất 1 reviewer (team lead hoặc senior dev)
   
2. **Deployment branches**:
   - Select "Selected branches"
   - Add rule: `main`
   - Chỉ cho phép deploy từ `main` branch

3. **Wait timer** (Optional):
   - Có thể set 5-10 phút delay trước khi deploy

---

## 🔐 Tạo AWS IAM User cho CI/CD

### Permissions cần thiết

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:DescribeTasks",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::sweetdream-terraform-state-*",
        "arn:aws:s3:::sweetdream-terraform-state-*/*"
      ]
    }
  ]
}
```

### Tạo IAM User

1. Vào AWS Console → IAM → Users
2. Click **Add users**
3. Username: `github-actions-sweetdream`
4. Select **Access key - Programmatic access**
5. Attach policy ở trên
6. Copy Access Key ID và Secret Access Key
7. Thêm vào GitHub Secrets

---

## ✅ Checklist

### Development
- [ ] Tạo environment `development`
- [ ] Thêm secret `AWS_ACCESS_KEY_ID`
- [ ] Thêm secret `AWS_SECRET_ACCESS_KEY`
- [ ] Thêm secret `DB_PASSWORD`

### Production
- [ ] Tạo environment `production`
- [ ] Thêm secret `AWS_ACCESS_KEY_ID`
- [ ] Thêm secret `AWS_SECRET_ACCESS_KEY`
- [ ] Thêm secret `DB_PASSWORD`
- [ ] Cấu hình Required reviewers
- [ ] Cấu hình Deployment branches = `main`

---

## 🧪 Test Configuration

Sau khi cấu hình xong, test bằng cách:

1. Push một thay đổi nhỏ vào `dev` branch
2. Kiểm tra GitHub Actions → CI/CD Pipeline
3. Verify:
   - CI jobs chạy thành công
   - Deploy jobs sử dụng `development` environment
   - Không yêu cầu approval

4. Tạo PR từ `dev` → `main`
5. Merge PR
6. Verify:
   - CI jobs chạy thành công
   - Deploy jobs yêu cầu approval
   - Sau khi approve, deploy vào `production`
