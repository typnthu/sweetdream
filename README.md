# 🍰 SweetDream E-commerce Platform

A production-ready full-stack e-commerce platform with microservices architecture, built with Next.js, Express, and PostgreSQL, deployable to AWS ECS.

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![AWS](https://img.shields.io/badge/AWS-ECS%20%7C%20RDS%20%7C%20ALB-orange)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Local Development](#-local-development)
- [AWS Deployment](#-aws-deployment)
- [Project Structure](#-project-structure)
- [API Documentation](#-api-documentation)
- [Admin Panel](#-admin-panel)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Features

### Customer Features
- 🛍️ Browse products by category (Mousse, Tiramisu, Kem, Bread)
- 🛒 Shopping cart with size selection
- 📦 Order placement with customer information
- ✅ Order confirmation and tracking
- 📱 Responsive design for mobile and desktop

### Admin Features
- 📊 Product management (CRUD operations)
- 📦 Order management with status updates
- 👥 Customer management
- 🏷️ Category management
- 🗄️ Database migration and seeding tools

### Technical Features
- 🔄 Microservices architecture (4 independent services)
- 🔐 Service-to-service communication (Order → User Service)
- ☁️ AWS deployment with ECS Fargate
- 🚀 CI/CD with GitHub Actions
- 📊 CloudWatch monitoring and logging
- 🔒 Secure architecture (private subnets, security groups)
- 📈 Auto-scaling enabled
- 🐳 Fully containerized with Docker

---

## 🏗️ Architecture

### Microservices Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Application Load    │
              │     Balancer (ALB)   │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│   Frontend      │            │   Backend       │
│   (Next.js)     │──────────▶│   (Express)     │
│   Port: 3000    │            │   Port: 3001    │
└─────────────────┘            └────────┬────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
           ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
           │  User Service   │ │  Order Service  │ │   PostgreSQL    │
           │  (Express)      │ │  (Express)      │ │   RDS Database  │
           │  Port: 3001     │◀┤  Port: 3002     │ │  (Private)      │
           └─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Service Responsibilities

| Service | Port | Responsibility | Database Access |
|---------|------|----------------|-----------------|
| **Frontend** | 3000 | UI, API Gateway | ❌ No |
| **Backend** | 3001 | Products, Categories | ✅ Yes |
| **User Service** | 3001 | Authentication, Customers | ✅ Yes |
| **Order Service** | 3002 | Order Processing | ✅ Yes |

### Service Communication

- **Frontend → Backend**: Product catalog, categories
- **Frontend → User Service**: Authentication, customer management
- **Frontend → Order Service**: Order placement
- **Order Service → User Service**: Customer verification (HTTP REST API)

---

## 💻 Tech Stack

### Frontend
- **Framework**: Next.js 15 (App Router)
- **UI Library**: React 19
- **Styling**: TailwindCSS 4
- **Language**: TypeScript 5
- **State Management**: React Context API

### Backend Services
- **Runtime**: Node.js 20
- **Framework**: Express.js 4
- **ORM**: Prisma 5
- **Database**: PostgreSQL 15
- **Validation**: Joi
- **Security**: Helmet, CORS
- **Language**: TypeScript 5

### Infrastructure
- **Cloud**: AWS (ECS Fargate, RDS, ALB, S3)
- **IaC**: Terraform 1.6+
- **CI/CD**: GitHub Actions
- **Container Registry**: Amazon ECR
- **Monitoring**: CloudWatch
- **Service Discovery**: AWS Cloud Map

---

## 🚀 Quick Start

### Prerequisites

- Node.js 20+
- Docker Desktop
- Git
- (For AWS) AWS CLI, Terraform

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd sweetdream
```

### 2. Start Database

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 3. Start All Services

Open 4 separate terminals:

**Terminal 1 - Backend Service:**
```bash
cd be
npm install
cp .env.example .env
npx prisma generate
npx prisma migrate dev
npm run seed
npm run dev
```

**Terminal 2 - User Service:**
```bash
cd user-service
npm install
cp .env.example .env
npx prisma generate
npm run dev
```

**Terminal 3 - Order Service:**
```bash
cd order-service
npm install
cp .env.example .env
npx prisma generate
npm run dev
```

**Terminal 4 - Frontend:**
```bash
cd fe
npm install
cp .env.example .env.local
npm run dev
```

### 4. Access Application

- **Frontend**: http://localhost:3000
- **Admin Panel**: http://localhost:3000/admin
- **Backend API**: http://localhost:3001/health
- **User Service**: http://localhost:3001/health
- **Order Service**: http://localhost:3002/health

---

## 🔧 Local Development

### Environment Variables

**Backend (.env):**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
DB_HOST=localhost
DB_NAME=sweetdream
DB_USER=postgres
DB_PASSWORD=postgres
PORT=3001
S3_BUCKET=sweetdream-products
```

**User Service (.env):**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
PORT=3001
JWT_SECRET=your-secret-key
```

**Order Service (.env):**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
PORT=3002
USER_SERVICE_URL=http://localhost:3001
```

**Frontend (.env.local):**
```env
NEXT_PUBLIC_API_URL=/api/proxy
BACKEND_API_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3001
ORDER_SERVICE_URL=http://localhost:3002
```

### Database Management

```bash
# Run migrations
cd be
npx prisma migrate dev

# Seed database
npm run seed

# Reset database
npx prisma migrate reset

# View database
npx prisma studio
```

### Health Checks

```bash
# Check all services
.\check-services.ps1

# Or manually
curl http://localhost:3001/health  # Backend
curl http://localhost:3001/health  # User Service
curl http://localhost:3002/health  # Order Service
curl http://localhost:3000         # Frontend
```

---

## ☁️ AWS Deployment

### Prerequisites

1. AWS Account
2. AWS CLI configured
3. Terraform installed
4. GitHub repository

### Step 1: Configure AWS

```bash
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1)
```

### Step 2: Create ECR Repositories

```bash
# Run the setup script
.\scripts\create-ecr-repos.ps1

# Or manually
aws ecr create-repository --repository-name sweetdream-backend --region us-east-1
aws ecr create-repository --repository-name sweetdream-frontend --region us-east-1
aws ecr create-repository --repository-name sweetdream-user-service --region us-east-1
aws ecr create-repository --repository-name sweetdream-order-service --region us-east-1
```

### Step 3: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review changes
terraform plan -var="db_password=YourSecurePassword123!"

# Deploy (takes 10-15 minutes)
terraform apply -var="db_password=YourSecurePassword123!"

# Save outputs
terraform output
```

**What gets created:**
- VPC with public/private subnets
- RDS PostgreSQL database
- ECS Cluster with 4 services
- Application Load Balancer
- S3 buckets for images
- CloudWatch log groups
- IAM roles and security groups
- Service Discovery (AWS Cloud Map)

### Step 4: Build and Push Images

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push all services
cd be
docker build -t $ECR_REGISTRY/sweetdream-backend:latest .
docker push $ECR_REGISTRY/sweetdream-backend:latest

cd ../fe
docker build -t $ECR_REGISTRY/sweetdream-frontend:latest .
docker push $ECR_REGISTRY/sweetdream-frontend:latest

cd ../user-service
docker build -t $ECR_REGISTRY/sweetdream-user-service:latest .
docker push $ECR_REGISTRY/sweetdream-user-service:latest

cd ../order-service
docker build -t $ECR_REGISTRY/sweetdream-order-service:latest .
docker push $ECR_REGISTRY/sweetdream-order-service:latest
```

### Step 5: Initialize Database

Get your ALB URL from Terraform output, then:

```bash
# Run migrations
curl -X POST http://<alb-url>/api/proxy/admin/migrate

# Seed database
curl -X POST http://<alb-url>/api/proxy/admin/seed
```

Or visit in browser:
- `http://<alb-url>/admin/migrate`

### Step 6: Setup GitHub Actions

Add these secrets to your GitHub repository:

**Settings → Secrets and variables → Actions**

| Secret Name | Value |
|------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

### Step 7: Enable Auto-Deployment

```bash
# Push to dev branch to trigger deployment
git checkout -b dev
git push -u origin dev
```

GitHub Actions will automatically:
- ✅ Create ECR repositories if needed
- ✅ Build Docker images
- ✅ Push to ECR
- ✅ Deploy to ECS
- ✅ Wait for services to stabilize

### Verify Deployment

```bash
# Check ECS services
aws ecs describe-services \
  --cluster sweetdream-cluster \
  --services sweetdream-service-backend sweetdream-service-frontend \
  --query 'services[*].[serviceName,status,runningCount]' \
  --output table

# View logs
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow

# Test application
curl http://<alb-url>/api/proxy/health
```

### Cost Estimate

**Monthly costs (us-east-1):**
- ECS Fargate (4 services × 2 tasks): ~$120
- RDS db.t4g.micro: ~$15
- Application Load Balancer: ~$20
- NAT Gateway: ~$35
- S3, CloudWatch, Data Transfer: ~$10

**Total: ~$200/month**

**Cost optimization:**
- Scale down to 1 task per service: ~$60/month
- Use smaller RDS instance
- Stop services when not in use
- Use Spot instances for dev

---

## 📁 Project Structure

```
sweetdream/
├── fe/                          # Frontend (Next.js)
│   ├── src/
│   │   ├── app/                 # Pages (App Router)
│   │   │   ├── admin/           # Admin panel
│   │   │   ├── api/proxy/       # API proxy to backend
│   │   │   ├── cart/            # Shopping cart
│   │   │   ├── menu/            # Product catalog
│   │   │   └── product/         # Product details
│   │   ├── components/          # React components
│   │   └── context/             # State management
│   ├── public/                  # Static assets
│   ├── Dockerfile
│   └── package.json
│
├── be/                          # Backend Service
│   ├── src/
│   │   ├── routes/              # API routes
│   │   │   ├── products.ts
│   │   │   ├── categories.ts
│   │   │   ├── orders.ts
│   │   │   └── customers.ts
│   │   ├── validators/          # Input validation
│   │   └── server.ts
│   ├── prisma/
│   │   ├── schema.prisma        # Database schema
│   │   ├── seed.ts              # Seed data
│   │   └── products/            # Product images
│   ├── Dockerfile
│   └── package.json
│
├── user-service/                # User Service
│   ├── src/
│   │   └── server.ts            # Auth & customer management
│   ├── prisma/
│   │   └── schema.prisma
│   ├── Dockerfile
│   └── package.json
│
├── order-service/               # Order Service
│   ├── src/
│   │   └── server.ts            # Order processing
│   ├── prisma/
│   │   └── schema.prisma
│   ├── Dockerfile
│   └── package.json
│
├── terraform/                   # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                 # VPC, subnets, security groups
│   │   ├── ecs/                 # ECS cluster & services
│   │   ├── rds/                 # PostgreSQL database
│   │   ├── alb/                 # Load balancer
│   │   ├── s3/                  # S3 buckets
│   │   ├── iam/                 # IAM roles
│   │   └── service-discovery/   # AWS Cloud Map
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .github/
│   └── workflows/               # CI/CD pipelines
│       ├── deploy.yml           # Main deployment
│       ├── backend-ci.yml       # Backend tests
│       ├── frontend-ci.yml      # Frontend tests
│       └── pr-checks.yml        # PR validation
│
├── scripts/
│   └── create-ecr-repos.ps1     # ECR setup script
│
├── docker-compose.dev.yml       # Local database
├── check-services.ps1           # Health check script
└── README.md                    # This file
```

---

## 📡 API Documentation

### Products API

```bash
# Get all products
GET /api/products

# Get product by ID
GET /api/products/:id

# Get products by category
GET /api/products/category/:categoryId

# Create product (Admin)
POST /api/products
Body: {
  "name": "Bánh Mousse Xoài",
  "description": "Delicious mango mousse cake",
  "img": "https://...",
  "categoryId": 1,
  "sizes": [
    { "size": "12cm", "price": 90000 },
    { "size": "16cm", "price": 120000 }
  ]
}

# Update product (Admin)
PUT /api/products/:id

# Delete product (Admin)
DELETE /api/products/:id
```

### Categories API

```bash
# Get all categories
GET /api/categories

# Create category (Admin)
POST /api/categories
Body: {
  "name": "Mousse",
  "description": "Mousse cakes"
}
```

### Orders API

```bash
# Get all orders
GET /api/orders?page=1&limit=10

# Get order by ID
GET /api/orders/:id

# Create order
POST /api/orders
Body: {
  "customer": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "0123456789",
    "address": "123 Street"
  },
  "items": [
    {
      "productId": 1,
      "size": "12cm",
      "price": 90000,
      "quantity": 2
    }
  ],
  "notes": "Delivery notes"
}

# Update order status (Admin)
PATCH /api/orders/:id/status
Body: {
  "status": "CONFIRMED",
  "isAdmin": true
}

# Cancel order
POST /api/orders/:id/cancel
```

### Customers API

```bash
# Get all customers (Admin)
GET /api/customers?page=1&limit=10

# Get customer by ID
GET /api/customers/:id

# Get customer by email
GET /api/customers/email/:email

# Create customer
POST /api/customers
Body: {
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "0123456789",
  "address": "123 Street"
}
```

### Authentication API

```bash
# Register
POST /api/auth/register
Body: {
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "0123456789",
  "address": "123 Street"
}

# Login
POST /api/auth/login
Body: {
  "email": "john@example.com",
  "password": "password123"
}

# Verify token
POST /api/auth/verify
Body: {
  "token": "jwt-token"
}
```

---

## 👨‍💼 Admin Panel

### Access

**Local:** http://localhost:3000/admin  
**AWS:** http://<alb-url>/admin

⚠️ **Note:** Admin panel is currently NOT protected. Add authentication before production.

### Features

**Product Management** (`/admin/products`)
- Add new products with multiple sizes
- Upload images to S3
- Set prices per size
- View all products (`/admin/products/list`)

**Order Management** (`/admin/orders`)
- View all orders with pagination
- Update order status (PENDING → CONFIRMED → PREPARING → READY → DELIVERED)
- View customer details
- Cancel orders

**Customer Management** (`/admin/customers`)
- View all customers
- See order history per customer
- Contact information

**Category Management** (`/admin/categories`)
- Add/edit/delete categories
- View products per category

**Database Tools** (`/admin/migrate`)
- Run Prisma migrations
- Seed database with sample data
- Database health check

---

## 🐛 Troubleshooting

### Local Development

**Database connection failed:**
```bash
# Check if Docker is running
docker ps

# Restart database
docker-compose -f docker-compose.dev.yml restart

# Reset database
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d
```

**Port already in use:**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <process-id> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

**Prisma client not generated:**
```bash
cd be
npx prisma generate
```

### AWS Deployment

**Services not starting:**
```bash
# Check service status
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend

# View logs
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow
```

**ECR repository not found:**
```bash
# Create repositories
.\scripts\create-ecr-repos.ps1
```

**Database connection failed:**
```bash
# Check RDS security group allows ECS
aws ec2 describe-security-groups --filters "Name=group-name,Values=sweetdream-ecs-sg"
```

**Images not loading:**
```bash
# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket sweetdream-products
```

### GitHub Actions

**Workflow failed:**
1. Go to GitHub → Actions
2. Click on failed workflow
3. Check error logs
4. Fix issue and push again

**ECR login failed:**
- Check AWS credentials in GitHub secrets
- Verify IAM permissions

---

## 📊 Monitoring

### CloudWatch Logs

```bash
# View all logs
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow

# Filter errors
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow --filter-pattern "ERROR"

# View specific service
aws logs tail /ecs/sweetdream-sweetdream-service-frontend --follow
```

### Metrics

**ECS Metrics:**
- CPU/Memory utilization
- Task count
- Service health

**ALB Metrics:**
- Request count
- Response time
- HTTP errors

**RDS Metrics:**
- Database connections
- CPU utilization
- Storage usage

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📝 License

This project is for educational purposes.

---

## 🆘 Support

**Issues?**
1. Check this README
2. Review CloudWatch logs
3. Check GitHub Issues
4. Create new issue with details

---

## 🎯 Quick Commands Reference

```bash
# Local Development
docker-compose -f docker-compose.dev.yml up -d  # Start database
.\check-services.ps1                            # Check health
cd be && npm run dev                            # Start backend
cd fe && npm run dev                            # Start frontend

# Database
cd be && npx prisma migrate dev                 # Run migrations
cd be && npm run seed                           # Seed data
cd be && npx prisma studio                      # View database

# AWS Deployment
cd terraform && terraform apply                 # Deploy infrastructure
git push origin dev                             # Auto-deploy code
aws logs tail /ecs/sweetdream --follow          # View logs

# Docker
docker-compose -f docker-compose.dev.yml logs -f  # View logs
docker-compose -f docker-compose.dev.yml down     # Stop services
```

---

**Ready to start?** Follow the [Quick Start](#-quick-start) guide! 🚀

**Need help?** Check the [Troubleshooting](#-troubleshooting) section or create an issue.

**Want to deploy to AWS?** See the [AWS Deployment](#-aws-deployment) section.
