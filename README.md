# 🛍️ SweetDream E-Commerce Platform

A production-ready, cloud-native e-commerce platform built with microservices architecture on AWS. Features automated deployments, real-time analytics, and comprehensive customer behavior tracking.

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [API Documentation](#-api-documentation)
- [Analytics System](#-analytics-system)
- [Deployment](#-deployment)
- [Development](#-development)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Architecture

### Microservices

| Service | Technology | Port | Purpose |
|---------|-----------|------|---------|
| **Frontend** | Next.js 14 | 3000 | Customer-facing web application |
| **Backend** | Express.js + Prisma | 3001 | Product catalog & cart management |
| **User Service** | Express.js + Prisma | 3003 | Authentication & user management |
| **Order Service** | Express.js + Prisma | 3002 | Order processing & fulfillment |

### AWS Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Load Balancer               │
│                    (Public-facing endpoint)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│  Public Subnet │       │  Public Subnet │
│   (us-east-1a) │       │   (us-east-1b) │
└───────┬────────┘       └───────┬────────┘
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│ Private Subnet │       │ Private Subnet │
│   ECS Fargate  │       │   ECS Fargate  │
│  ┌──────────┐  │       │  ┌──────────┐  │
│  │ Frontend │  │       │  │ Frontend │  │
│  │ Backend  │  │       │  │ Backend  │  │
│  │ User Svc │  │       │  │ User Svc │  │
│  │ Order Svc│  │       │  │ Order Svc│  │
│  └──────────┘  │       │  └──────────┘  │
└───────┬────────┘       └───────┬────────┘
        │                         │
        └────────────┬────────────┘
                     │
            ┌────────▼────────┐
            │  RDS PostgreSQL │
            │  (Multi-AZ)     │
            └─────────────────┘
```

**Key Components:**
- **ECS Fargate**: Serverless container orchestration
- **RDS PostgreSQL**: Managed relational database
- **Application Load Balancer**: Traffic distribution
- **CloudWatch**: Logging, monitoring, and analytics
- **S3**: Analytics data storage
- **ECR**: Container image registry
- **AWS Cloud Map**: Service discovery
- **Secrets Manager**: Credential management
- **EventBridge**: Scheduled Lambda triggers

## ✨ Features

### 🛒 Customer Features
- ✅ Product catalog with search and filtering
- ✅ Shopping cart management
- ✅ User registration and authentication
- ✅ Order placement and tracking
- ✅ Order history and status updates
- ✅ Responsive design (mobile-friendly)

### 👨‍💼 Admin Features
- ✅ Order management dashboard
- ✅ Order status updates
- ✅ Customer analytics and insights
- ✅ User role management
- ✅ Real-time monitoring

### 🔧 Technical Features
- ✅ **Microservices architecture** with service discovery
- ✅ **Auto-scaling** based on CPU/memory usage
- ✅ **Blue-green deployments** with zero downtime
- ✅ **Automated CI/CD** with GitHub Actions
- ✅ **Smart change detection** (only rebuild changed services)
- ✅ **CloudWatch Insights** for log analysis
- ✅ **Daily analytics export** to S3 with duplicate prevention
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Container-based** deployment
- ✅ **Health checks** and automatic recovery
- ✅ **Secrets management** with AWS Secrets Manager

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+
- AWS CLI (for cloud deployment)
- Terraform 1.5+ (for infrastructure)

### Local Development

```bash
# 1. Clone repository
git clone <repository-url>
cd sweetdream

# 2. Setup environment files
cp be/.env.example be/.env
cp fe/.env.example fe/.env
cp order-service/.env.example order-service/.env
cp user-service/.env.example user-service/.env

# 3. Start all services
docker-compose up -d

# 4. Wait for services to be ready (~30 seconds)
docker-compose logs -f

# 5. Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
# User Service: http://localhost:3003
# Order Service: http://localhost:3002
```

**Default Admin Account:**
- Email: `admin@sweetdream.com`
- Password: `admin123`

### AWS Deployment

```bash
# 1. Configure AWS credentials
aws configure

# 2. Setup Terraform
cd terraform
terraform init

# 3. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values:
# - db_password
# - alert_email
# - analytics_bucket_prefix (must be globally unique)

# 4. Deploy infrastructure
terraform plan
terraform apply

# 5. Push code to trigger CI/CD
git push origin main
```

GitHub Actions will automatically:
- Build Docker images
- Push to ECR
- Deploy to ECS
- Run health checks

## 📁 Project Structure

```
sweetdream/
├── be/                              # Backend Service
│   ├── src/
│   │   ├── routes/                  # API routes
│   │   ├── utils/                   # Utilities & loggers
│   │   └── server.ts                # Express server
│   ├── prisma/
│   │   ├── schema.prisma            # Database schema
│   │   └── seed.ts                  # Sample data
│   ├── Dockerfile
│   └── package.json
│
├── fe/                              # Frontend (Next.js)
│   ├── src/
│   │   ├── app/                     # App router pages
│   │   ├── components/              # React components
│   │   └── lib/                     # Utilities
│   ├── public/                      # Static assets
│   ├── Dockerfile
│   └── package.json
│
├── order-service/                   # Order Service
│   ├── src/
│   │   ├── routes/                  # Order API routes
│   │   └── server.ts
│   ├── prisma/
│   │   └── schema.prisma
│   ├── Dockerfile
│   └── package.json
│
├── user-service/                    # User Service
│   ├── src/
│   │   ├── routes/                  # Auth & user routes
│   │   └── server.ts
│   ├── prisma/
│   │   └── schema.prisma
│   ├── Dockerfile
│   └── package.json
│
├── terraform/                       # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                     # Network configuration
│   │   ├── ecs/                     # Container orchestration
│   │   ├── rds/                     # Database
│   │   ├── alb/                     # Load balancer
│   │   ├── ecr/                     # Container registry
│   │   ├── s3/                      # Object storage
│   │   ├── iam/                     # Permissions
│   │   ├── cloudwatch-logs/         # Logging
│   │   ├── cloudwatch-analytics/    # Analytics export
│   │   ├── service-discovery/       # AWS Cloud Map
│   │   ├── secrets-manager/         # Secrets
│   │   └── bastion/                 # Database access
│   ├── main.tf                      # Main configuration
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   └── terraform.tfvars             # Your values (gitignored)
│
├── .github/workflows/               # CI/CD Pipelines
│   ├── ci-cd.yml                    # Unified CI/CD Pipeline
│   └── README.md                    # Workflow documentation
├── .github/ENVIRONMENTS_SETUP.md    # GitHub Environments setup guide
│
├── scripts/                         # Utility Scripts
│   ├── set-user-role.ps1           # Change user roles
│   └── setup-admin.ps1             # Create admin user
│
├── docker-compose.yml               # Local development
├── ANALYTICS_DEPLOYMENT_GUIDE.md    # Analytics setup
└── README.md                        # This file
```

## 📡 API Documentation

### Backend Service (Port 3001)

#### Products
```http
GET    /api/products              # List all products
GET    /api/products/:id          # Get product details
GET    /api/products/search?q=    # Search products
```

#### Cart
```http
POST   /api/cart                  # Add item to cart
GET    /api/cart/:userId          # Get user's cart
DELETE /api/cart/:id              # Remove cart item
PATCH  /api/cart/:id              # Update cart item quantity
```

#### Categories
```http
GET    /api/categories            # List categories
```

### User Service (Port 3003)

#### Authentication
```http
POST   /api/auth/register         # Register new user
POST   /api/auth/login            # Login
POST   /api/auth/verify           # Verify JWT token
```

#### Customer Management
```http
GET    /api/customers             # List all customers (admin)
GET    /api/customers/:id         # Get customer details
PATCH  /api/customers/:id/role    # Update user role (admin)
PATCH  /api/customers/email/:email/role  # Update role by email (admin)
```

### Order Service (Port 3002)

#### Orders
```http
POST   /api/orders                # Create new order
GET    /api/orders/user/:userId   # Get user's orders
GET    /api/orders/:id            # Get order details
PATCH  /api/orders/:id/status     # Update order status (admin)
```

**Order Status Flow:**
`PENDING` → `PROCESSING` → `SHIPPED` → `DELIVERED`

### Example Requests

#### Register User
```bash
curl -X POST http://localhost:3003/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "phone": "0123456789",
    "address": "123 Main St"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3003/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

#### Create Order
```bash
curl -X POST http://localhost:3002/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "userId": 1,
    "items": [
      {
        "productId": 1,
        "quantity": 2,
        "size": "M",
        "price": 299000
      }
    ],
    "totalAmount": 598000,
    "shippingAddress": "123 Main St"
  }'
```

## 📊 Analytics System

### Overview

The platform includes a comprehensive analytics system that tracks customer behavior and exports data to S3 for analysis.

### Tracked Events

| Event | Service | Data Captured |
|-------|---------|---------------|
| **Product Viewed** | Backend | productId, productName, price, category |
| **Product Search** | Backend | searchQuery, resultsCount |
| **Add to Cart** | Backend | productId, quantity, size, price |
| **Checkout Started** | Frontend | cartTotal, itemCount |
| **Order Completed** | Order Service | orderId, products, totalAmount, userId |

### Data Export

**Automated Daily Export:**
- Runs at **midnight Vietnam time** (17:00 UTC)
- Exports to S3 in JSON format
- Organized by date: `s3://bucket/user-actions/year=2024/month=12/day=02/`
- **Automatic duplicate prevention** when run multiple times

**Manual Export:**
```bash
# Test export (exports today's logs)
aws lambda invoke \
  --function-name sweetdream-service-backend-export-logs \
  --payload '{"test_mode": true}' \
  response.json

# Check result
cat response.json | jq .
```

### CloudWatch Insights Queries

Pre-configured queries available in AWS Console:

1. **Product Views by User** - Most viewed products
2. **Cart Additions** - Products added to cart
3. **Purchases** - Completed orders with revenue
4. **Customer Frequency** - Repeat customer analysis
5. **Best Sellers** - Top-selling products
6. **Category Performance** - Sales by category
7. **Conversion Funnel** - View → Cart → Checkout → Order

### Duplicate Prevention

The Lambda function automatically prevents duplicates:
- Each log gets a unique ID based on content
- Merges with existing S3 data before writing
- Tracks export history in metadata files
- **Safe to run multiple times per day**

See `ANALYTICS_DEPLOYMENT_GUIDE.md` and `terraform/modules/cloudwatch-analytics/DUPLICATE_PREVENTION.md` for details.

## 🚢 Deployment

### Environments

| Environment | Branch | Region | Approval |
|-------------|--------|--------|----------|
| Development | `dev` | us-east-1 | No |
| Production | `main` | us-west-2 | Yes |

### Automated CI/CD (GitHub Actions)

**Unified Pipeline (`ci-cd.yml`):**
- CI và Deploy được gộp trong 1 workflow
- CI phải pass trước khi Deploy chạy
- Smart change detection - chỉ build/deploy services thay đổi

**Triggers:**
- Push to `main` → CI → Deploy to Production (cần approval)
- Push to `dev` → CI → Deploy to Development (tự động)
- Pull requests → Chỉ chạy CI, không deploy

**Pipeline Flow:**
```
Push → Change Detection → CI Jobs → Deploy Infrastructure → Deploy Services
                              ↓
                    (CI fail = Deploy không chạy)
```

**Deployment Time:**
- Single service: ~5-8 minutes
- All services: ~10-15 minutes

### GitHub Environments Setup

Xem hướng dẫn chi tiết: [.github/ENVIRONMENTS_SETUP.md](.github/ENVIRONMENTS_SETUP.md)

**Required Secrets (per environment):**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`

### Manual Deployment

```bash
# Deploy to Development
git checkout dev
git push origin dev

# Deploy to Production
git checkout main
git merge dev
git push origin main
# → Approve trong GitHub Actions
```

### Manual Trigger

1. Vào **Actions** → **CI/CD Pipeline**
2. Click **Run workflow**
3. Chọn environment và force deploy option

### Blue-Green Deployment

The ALB uses weighted target groups for gradual rollouts.
Configure in `terraform/modules/alb/main.tf`.

## 🛠️ Development

### Database Migrations

```bash
# Backend service
cd be
npx prisma migrate dev --name migration_name
npx prisma generate
npm run seed

# User service
cd user-service
npx prisma migrate dev --name migration_name
npx prisma generate

# Order service
cd order-service
npx prisma migrate dev --name migration_name
npx prisma generate
```

### Admin User Setup

**Automatic (Recommended):**
Admin user is created automatically on container startup.

**Manual (if needed):**
```powershell
.\scripts\setup-admin.ps1
```

### User Role Management

```powershell
# Promote user to admin
.\scripts\set-user-role.ps1 -Email "user@example.com" -Role "ADMIN"

# Demote admin to customer
.\scripts\set-user-role.ps1 -Email "admin@example.com" -Role "CUSTOMER"
```

**Note:** Users must log in again after role changes.

### Running Tests

```bash
# Backend
cd be && npm test

# Frontend
cd fe && npm test

# All services
docker-compose run backend npm test
docker-compose run frontend npm test
```

### Code Quality

```bash
# Lint
npm run lint

# Format
npm run format

# Type check
npm run type-check
```

## 🔐 Security

### Network Security
- ✅ VPC with public/private subnets
- ✅ Security groups with least privilege
- ✅ Private subnets for ECS and RDS
- ✅ NAT Gateway for outbound traffic
- ✅ HTTPS/TLS via ALB

### Application Security
- ✅ JWT-based authentication
- ✅ Password hashing with bcrypt
- ✅ Role-based access control (RBAC)
- ✅ Input validation and sanitization
- ✅ SQL injection prevention (Prisma ORM)

### AWS Security
- ✅ IAM roles with least privilege
- ✅ Secrets Manager for credentials
- ✅ Encrypted S3 buckets (AES-256)
- ✅ Encrypted RDS storage
- ✅ CloudWatch audit logs

### Best Practices
- ✅ No hardcoded credentials
- ✅ Environment-based configuration
- ✅ Regular security updates
- ✅ Automated vulnerability scanning

## 🔍 Troubleshooting

### View Logs

```bash
# Backend service
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow

# Frontend service
aws logs tail /ecs/sweetdream-sweetdream-service-frontend --follow

# Order service
aws logs tail /ecs/sweetdream-sweetdream-service-order-service --follow

# User service
aws logs tail /ecs/sweetdream-sweetdream-service-user-service --follow

# Lambda export function
aws logs tail /aws/lambda/sweetdream-service-backend-export-logs --follow
```

### Check Service Health

```bash
# List all services
aws ecs list-services --cluster sweetdream-cluster

# Describe specific service
aws ecs describe-services \
  --cluster sweetdream-cluster \
  --services sweetdream-service-backend

# Check task status
aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-service-backend
```

### Database Access

```bash
# Enable bastion host (optional, disabled by default)
# Edit terraform/terraform.tfvars:
enable_bastion = false

# Apply changes
cd terraform && terraform apply

# Connect via SSM
aws ssm start-session --target <bastion-instance-id>

# Inside bastion, connect to RDS
psql -h <rds-endpoint> -U dbadmin -d sweetdream
```

### Common Issues

**Issue: Service won't start**
```bash
# Check task logs
aws ecs describe-tasks --cluster sweetdream-cluster --tasks <task-id>

# Check CloudWatch logs for errors
aws logs tail /ecs/sweetdream-sweetdream-service-backend --since 10m
```

**Issue: Database connection failed**
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Test connectivity from ECS task
aws ecs execute-command \
  --cluster sweetdream-cluster \
  --task <task-id> \
  --container sweetdream-backend \
  --interactive \
  --command "/bin/sh"
```

**Issue: Analytics not exporting**
```bash
# Check Lambda logs
aws logs tail /aws/lambda/sweetdream-service-backend-export-logs --follow

# Verify EventBridge rule
aws events list-rules --name-prefix sweetdream

# Test Lambda manually
aws lambda invoke \
  --function-name sweetdream-service-backend-export-logs \
  --payload '{"test_mode": true}' \
  response.json
```

## 📈 Monitoring

### CloudWatch Dashboards

Access via AWS Console → CloudWatch → Dashboards

**Metrics to Monitor:**
- ECS CPU/Memory utilization
- ALB request count and latency
- RDS connections and queries
- Lambda invocations and errors
- S3 storage usage

### Alarms

Configured alarms (sent to `alert_email`):
- High CPU usage (>80%)
- High memory usage (>80%)
- Service unhealthy targets
- RDS storage low
- Lambda errors

### Cost Monitoring

**Estimated Monthly Costs:**
- ECS Fargate: $50-100 (4 services, 2 tasks each)
- RDS PostgreSQL: $30-50 (db.t3.micro)
- ALB: $20-30
- S3: $1-5
- CloudWatch: $5-10
- Data Transfer: $10-20
- **Total: ~$120-220/month**

Use AWS Cost Explorer to track actual costs.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Coding Standards
- Use TypeScript for type safety
- Follow ESLint configuration
- Write meaningful commit messages
- Add tests for new features
- Update documentation

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Next.js team for the amazing framework
- AWS for cloud infrastructure
- Prisma for the excellent ORM
- All open-source contributors

---

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review CloudWatch logs

**Note:** This is a demo project. For production use, ensure proper:
- Security hardening
- Backup strategies
- Disaster recovery plans
- Performance optimization
- Cost optimization
- Compliance requirements

---

**Built with ❤️ for learning cloud-native architecture**
