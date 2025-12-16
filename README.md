# SweetDream E-Commerce Platform

A production-ready, cloud-native e-commerce platform built with microservices architecture on AWS. Features automated CI/CD deployments, real-time analytics, comprehensive customer behavior tracking, and multi-environment support.

**Key Highlights:**
- Fully automated CI/CD pipeline with GitHub Actions
- Microservices architecture with 4 independent services
- Real-time customer behavior analytics with S3 export
- Zero-downtime blue-green deployments
- Infrastructure as Code with Terraform
- Cost-optimized AWS infrastructure (~$120-220/month)
- Enterprise-grade security and monitoring
- Multi-environment support (dev/prod)

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Multi-Environment Setup](#multi-environment-setup)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Analytics System](#analytics-system)
- [Deployment Guide](#deployment-guide)
- [Development](#development)
- [Security](#security)
- [Monitoring & Cost](#monitoring--cost)
- [Troubleshooting](#troubleshooting)
- [Production Fixes](#production-fixes)

## Project Overview

### Mission Statement
SweetDream demonstrates modern cloud-native e-commerce architecture using AWS best practices, showcasing automated DevOps workflows, real-time analytics, and scalable microservices design.

### Success Metrics
- 99.9% uptime with auto-scaling
- Page load times under 2 seconds
- Deployment times under 10 minutes
- Automated daily analytics export
- Zero-downtime deployments
- Cost-optimized infrastructure

## Architecture

### Microservices Design

| Service | Technology | Port | Purpose | Database |
|---------|-----------|------|---------|----------|
| **Frontend** | Next.js 14 | 3000 | Customer-facing web application | - |
| **Backend** | Express.js + Prisma | 3001 | Product catalog & cart management | PostgreSQL |
| **User Service** | Express.js + Prisma | 3003 | Authentication & user management | PostgreSQL |
| **Order Service** | Express.js + Prisma | 3002 | Order processing & fulfillment | PostgreSQL |

### Multi-Environment AWS Infrastructure

```
AWS Account (Single Account, Multi-Region)
├── us-east-1 (Development)
│   ├── VPC: 10.1.0.0/16
│   ├── ECS Cluster: sweetdream-dev-cluster
│   ├── S3 State: sweetdream-terraform-state-dev
│   └── ALB: dev-sweetdream-alb
└── us-west-2 (Production)
    ├── VPC: 10.0.0.0/16
    ├── ECS Cluster: sweetdream-prod-cluster
    ├── S3 State: sweetdream-terraform-state-prod
    └── ALB: prod-sweetdream-alb
```

### Detailed Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Load Balancer               │
│                    (Public-facing endpoint)                  │
│              Path-based routing to services                  │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│  Public Subnet │       │  Public Subnet │
│   (AZ-a)       │       │   (AZ-b)       │
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
            │    (Multi-AZ)   │
            │   Auto-Backup   │
            └─────────────────┘
```

### Core AWS Services

**Compute & Networking:**
- **ECS Fargate**: Serverless container orchestration with auto-scaling
- **Application Load Balancer**: Path-based routing with health checks
- **VPC**: Multi-AZ deployment with public/private subnets
- **NAT Gateway**: Secure outbound internet access

**Data & Storage:**
- **RDS PostgreSQL**: Multi-AZ managed database with automated backups
- **S3**: Analytics data storage with lifecycle policies
- **ECR**: Container image registry with vulnerability scanning

**Monitoring & Analytics:**
- **CloudWatch**: Comprehensive logging, monitoring, and alerting
- **Lambda**: Scheduled analytics export with duplicate prevention
- **EventBridge**: Automated scheduling and event-driven architecture

**Security & Management:**
- **AWS Secrets Manager**: Secure credential management
- **IAM**: Least-privilege access control
- **AWS Cloud Map**: Service discovery for microservices communication

### Environment Differences

| Feature | Development (us-east-1) | Production (us-west-2) |
|---------|-------------------------|------------------------|
| **VPC CIDR** | 10.1.0.0/16 | 10.0.0.0/16 |
| **Log Retention** | 7 days | 30 days |
| **Scaling** | Min: 1, Max: 3 | Min: 2, Max: 10 |
| **Deployment** | Rolling updates | Blue-Green |
| **SSL Certificate** | HTTP only | HTTPS with ACM |
| **Bastion Host** | Optional | Disabled |
| **Backup Retention** | 7 days | 30 days |

## Features

### Customer Features
- Product catalog with search and filtering
- Shopping cart management
- User registration and authentication
- Order placement and tracking
- Order history and status updates
- Responsive design (mobile-friendly)

### Admin Features
- Order management dashboard
- Order status updates
- Customer analytics and insights
- User role management
- Real-time monitoring

### Technical Features
- **Microservices architecture** with service discovery
- **Auto-scaling** based on CPU/memory usage
- **Blue-green deployments** with zero downtime
- **Automated CI/CD** with GitHub Actions
- **Smart change detection** (only rebuild changed services)
- **CloudWatch Insights** for log analysis
- **Daily analytics export** to S3 with duplicate prevention
- **Infrastructure as Code** with Terraform
- **Container-based** deployment
- **Health checks** and automatic recovery
- **Secrets management** with AWS Secrets Manager

## Quick Start

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

### AWS Deployment (Automated via GitHub Actions)

#### Option 1: Automated CI/CD (Recommended)

```bash
# 1. Configure AWS credentials
aws configure

# 2. Setup GitHub repository secrets and variables
# Go to GitHub → Settings → Secrets and variables → Actions

# Required Secrets:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY  
# - DB_PASSWORD
# - DB_USERNAME
# - ALERT_EMAIL

# Required Variables:
# - AWS_REGION (us-east-1 for dev, us-west-2 for prod)
# - ENVIRONMENT (development/production)
# - VPC_CIDR
# - CLUSTER_NAME
# - DB_NAME
# - S3_BUCKET_NAME
# - ENABLE_ANALYTICS (true/false)
# - LOG_RETENTION_DAYS

# 3. Push to trigger deployment
git push origin dev     # Deploy to development
git push origin main    # Deploy to production
```

#### Option 2: Manual Terraform Deployment

```bash
# 1. Setup Terraform backend
cd terraform/environments/dev  # or prod
terraform init

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 3. Deploy infrastructure
terraform plan
terraform apply

# 4. Build and push images manually
./scripts/deploy-images.sh
```

**GitHub Actions automatically handles:**
- Smart change detection (only rebuild changed services)
- Parallel Docker image builds
- ECR image pushing with proper tagging
- ECS service deployments with health checks
- Infrastructure updates via Terraform
- Analytics Lambda deployment

## Multi-Environment Setup

### Environment Strategy

The platform supports isolated development and production environments across different AWS regions:

```bash
# Development Environment (us-east-1)
- Branch: dev
- VPC: 10.1.0.0/16
- Cluster: sweetdream-dev-cluster
- State: sweetdream-terraform-state-dev
- Deployment: Rolling updates
- Cost optimized: Shorter retention, smaller instances

# Production Environment (us-west-2)  
- Branch: main
- VPC: 10.0.0.0/16
- Cluster: sweetdream-prod-cluster
- State: sweetdream-terraform-state-prod
- Deployment: Blue-Green with confirmation
- Production ready: Extended retention, SSL, monitoring
```

### Quick Multi-Environment Setup

```bash
# 1. Setup S3 backends for both environments
chmod +x scripts/setup-s3-backends.sh
./scripts/setup-s3-backends.sh

# 2. Deploy development environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# 3. Deploy production environment  
cd terraform/environments/prod
terraform init
terraform plan
terraform apply

# 4. Configure GitHub Actions
# Set environment-specific secrets and variables
# Push to respective branches to trigger deployments
```

### Environment-Specific Configuration

**Development Features:**
- Relaxed security groups for debugging
- Shorter log retention (cost optimization)
- HTTP only (no SSL certificate required)
- Optional bastion host for database access
- Smaller instance sizes and scaling limits

**Production Features:**
- Strict security groups and network isolation
- Extended log retention for compliance
- HTTPS with ACM certificate
- Bastion host disabled by default
- Deployment confirmation prompts
- Enhanced monitoring and alerting

### CI/CD Branch Strategy

```yaml
# Automatic deployments based on branch
on:
  push:
    branches:
      - dev     # → Development environment
      - main    # → Production environment
  
  pull_request: # → Run tests only, no deployment
```

## Project Structure

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
│   ├── environments/                # Environment-specific configs
│   │   ├── dev/                     # Development (us-east-1)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── outputs.tf
│   │   └── prod/                    # Production (us-west-2)
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── outputs.tf
│   ├── modules/                     # Reusable infrastructure modules
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
│   ├── main.tf                      # Legacy single-env config
│   ├── variables.tf                 # Legacy variables
│   ├── outputs.tf                   # Legacy outputs
│   └── terraform.tfvars             # Legacy config (gitignored)
│
├── .github/workflows/               # CI/CD Pipelines
│   ├── ci.yml                       # Continuous Integration
│   └── deploy.yml                   # Deployment
│
├── scripts/                         # Utility Scripts
│   ├── set-user-role.ps1           # Change user roles
│   └── setup-admin.ps1             # Create admin user
│
├── docker-compose.yml               # Local development
├── ANALYTICS_DEPLOYMENT_GUIDE.md    # Analytics setup
└── README.md                        # This file
```

## API Documentation

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

## Analytics System

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

## Deployment Guide

### Automated CI/CD Pipeline (GitHub Actions)

#### Deployment Triggers
```yaml
# Automatic deployments
Push to 'dev' branch    → Development environment (us-east-1)
Push to 'main' branch   → Production environment (us-west-2)
Pull requests          → Tests only (no deployment)

# Manual deployments
GitHub Actions UI      → Choose environment + force deploy option
```

#### Pipeline Workflow

**1. Change Detection & Validation**
```bash
# Smart change detection
- Analyzes git diff to identify changed services
- Skips unchanged services (faster deployments)
- Validates CI success before deployment
- Checks for hardcoded secrets in code
```

**2. Infrastructure Deployment**
```bash
# Terraform operations (if infrastructure changed)
- Terraform init, validate, plan
- Apply infrastructure changes
- Handle resource conflicts and cleanup
- Update task definitions with new images
```

**3. Service Deployment**
```bash
# Parallel service builds (only changed services)
- Build Docker images with optimized layers
- Push to ECR with SHA and latest tags
- Update ECS task definitions
- Trigger rolling deployments with health checks
```

**4. Verification & Monitoring**
```bash
# Post-deployment validation
- Wait for service stability
- Verify target group health
- Test Lambda analytics functions
- Generate deployment summary
```

#### Deployment Performance
- **Single service**: 5-8 minutes
- **All services**: 10-15 minutes  
- **Infrastructure only**: 3-5 minutes
- **Force deploy all**: 12-18 minutes

### Manual Deployment Options

#### Option 1: Legacy Scripts (Deprecated)
```bash
# Note: These scripts are now legacy since GitHub Actions handles deployment
# See scripts/README.md for details

# Build and push images
./scripts/deploy-images.sh

# Deploy infrastructure  
./scripts/deploy-dev.sh     # Development
./scripts/deploy-prod.sh    # Production (with confirmation)
```

#### Option 2: Direct AWS CLI
```bash
# Build and push specific service
cd be
docker build -t sweetdream-backend .
docker tag sweetdream-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest

# Update ECS service
aws ecs update-service \
  --cluster sweetdream-cluster \
  --service sweetdream-service-backend \
  --force-new-deployment
```

#### Option 3: Terraform Direct
```bash
# Deploy to specific environment
cd terraform/environments/dev  # or prod
terraform init
terraform plan
terraform apply

# Update with new image tags
terraform apply -var="image_tag=v1.2.3"
```

### Deployment Strategies

#### Development Environment
- **Strategy**: Rolling updates
- **Downtime**: Minimal (health check dependent)
- **Rollback**: Automatic on health check failure
- **Confirmation**: None required

#### Production Environment  
- **Strategy**: Blue-Green deployment
- **Downtime**: Zero (traffic switching)
- **Rollback**: Instant traffic switch back
- **Confirmation**: Manual approval for infrastructure changes

### Blue-Green Deployment Details

```bash
# ALB Target Group Configuration
Blue Environment (Current):
├── Target Group: sweetdream-tg-blue
├── Health Checks: /health endpoint
└── Traffic Weight: 100% → 0% (during deployment)

Green Environment (New):
├── Target Group: sweetdream-tg-green  
├── Health Checks: /health endpoint
└── Traffic Weight: 0% → 100% (after validation)

# Deployment Process:
1. Deploy new version to Green environment
2. Run health checks and smoke tests
3. Gradually shift traffic: 10% → 50% → 100%
4. Monitor metrics and error rates
5. Complete switch or rollback if issues detected
```

### Deployment Monitoring

#### Real-time Monitoring
```bash
# Watch deployment progress
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend

# Monitor logs during deployment
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

#### GitHub Actions Dashboard
- Real-time deployment status
- Service-by-service progress
- Infrastructure change summary
- Cost impact estimation
- Rollback instructions if needed

### Rollback Procedures

#### Automatic Rollback
```bash
# ECS automatically rolls back if:
- Health checks fail for 5 minutes
- Task startup fails repeatedly
- Memory/CPU limits exceeded
```

#### Manual Rollback
```bash
# Rollback via GitHub Actions
1. Go to Actions → Deploy to AWS
2. Select "Run workflow"
3. Choose environment
4. Set image tag to previous version
5. Enable "Force deploy"

# Rollback via AWS CLI
aws ecs update-service \
  --cluster sweetdream-cluster \
  --service sweetdream-service-backend \
  --task-definition sweetdream-task-backend:PREVIOUS_REVISION
```

### Deployment Best Practices

#### Pre-deployment Checklist
- All tests passing in CI
- Database migrations tested
- Environment variables updated
- Secrets rotated if needed
- Monitoring alerts configured

#### Post-deployment Validation
- All services healthy and stable
- API endpoints responding correctly
- Database connections working
- Analytics export functioning
- No error spikes in logs

#### Emergency Procedures
```bash
# Stop all deployments
aws ecs update-service --cluster sweetdream-cluster --service <service-name> --desired-count 0

# Scale up quickly
aws ecs update-service --cluster sweetdream-cluster --service <service-name> --desired-count 4

# Emergency database access
# Enable bastion host in terraform.tfvars: enable_bastion = true
terraform apply
aws ssm start-session --target <bastion-instance-id>
```

## Development

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

## Security

### Network Security
- VPC with public/private subnets
- Security groups with least privilege
- Private subnets for ECS and RDS
- NAT Gateway for outbound traffic
- HTTPS/TLS via ALB

### Application Security
- JWT-based authentication
- Password hashing with bcrypt
- Role-based access control (RBAC)
- Input validation and sanitization
- SQL injection prevention (Prisma ORM)

### AWS Security
- IAM roles with least privilege
- Secrets Manager for credentials
- Encrypted S3 buckets (AES-256)
- Encrypted RDS storage
- CloudWatch audit logs

### Best Practices
- No hardcoded credentials
- Environment-based configuration
- Regular security updates
- Automated vulnerability scanning

## Troubleshooting

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

## Monitoring & Cost

### Comprehensive Monitoring Setup

#### CloudWatch Dashboards
Access via AWS Console → CloudWatch → Dashboards

**Pre-configured Dashboards:**
- **SweetDream-BlueGreen-Dashboard-Dev**: Development environment metrics
- **SweetDream-BlueGreen-Dashboard-Prod**: Production environment metrics

**Key Metrics Monitored:**
```bash
Application Performance:
├── ECS CPU/Memory utilization per service
├── ALB request count, latency, and error rates
├── Target group health and response times
└── Container startup and failure rates

Database Performance:
├── RDS connections and query performance
├── Database CPU, memory, and storage usage
├── Slow query logs and deadlock detection
└── Backup status and replication lag

Analytics & Storage:
├── Lambda invocation success/failure rates
├── S3 storage usage and request patterns
├── CloudWatch log ingestion and retention
└── Data export completion status
```

#### Automated Alerting

**Critical Alerts** (sent to `alert_email`):
```bash
Infrastructure Alerts:
├── ECS service unhealthy targets (>2 minutes)
├── High CPU usage (>80% for 5 minutes)
├── High memory usage (>80% for 5 minutes)
├── RDS storage low (<20% remaining)
└── ALB 5xx error rate (>5% for 2 minutes)

Application Alerts:
├── Lambda function errors (>3 failures/hour)
├── Database connection failures
├── Analytics export failures
├── Container deployment failures
└── Health check failures across services
```

**Warning Alerts**:
```bash
Performance Warnings:
├── Response time degradation (>2 seconds)
├── Increased error rates (>1% 4xx errors)
├── Database query slowdown (>500ms average)
└── Unusual traffic patterns

Cost Warnings:
├── Monthly spend exceeding budget
├── Unexpected resource scaling
├── High data transfer costs
└── Storage growth beyond projections
```

### Cost Analysis & Optimization

#### Detailed Cost Breakdown

**Monthly AWS Costs (Estimated):**

| Service Category | Development | Production | Total |
|------------------|-------------|------------|-------|
| **Compute (ECS Fargate)** | $25-40 | $50-80 | $75-120 |
| **Database (RDS)** | $15-25 | $30-50 | $45-75 |
| **Load Balancer (ALB)** | $10-15 | $20-30 | $30-45 |
| **Storage (S3)** | $1-2 | $3-8 | $4-10 |
| **Monitoring (CloudWatch)** | $2-5 | $8-15 | $10-20 |
| **Networking (Data Transfer)** | $3-8 | $10-25 | $13-33 |
| **Analytics (Lambda)** | <$1 | $1-3 | $1-4 |
| **Container Registry (ECR)** | $1-2 | $2-5 | $3-7 |
| **Secrets Manager** | $1-2 | $2-4 | $3-6 |
| **NAT Gateway** | $15-20 | $30-40 | $45-60 |
| **TOTAL** | **$73-120** | **$156-260** | **$229-380** |

#### Cost Optimization Strategies

**Implemented Optimizations:**
```bash
Compute Optimization:
├── Fargate Spot instances for non-critical tasks
├── Auto-scaling based on CPU/memory thresholds
├── Right-sized task definitions (CPU/memory)
└── Scheduled scaling for predictable traffic

Storage Optimization:
├── S3 Lifecycle policies (Glacier after 90 days)
├── CloudWatch log retention policies (7-30 days)
├── ECR image lifecycle policies (keep 10 images)
└── RDS automated backup retention (7-30 days)

Network Optimization:
├── VPC endpoints for S3 access (reduce NAT costs)
├── CloudFront for static content (future enhancement)
├── Compression enabled on ALB
└── Regional data transfer optimization
```

**Additional Cost Savings:**
```bash
Development Environment:
├── Smaller instance sizes (0.25 vCPU, 512 MB)
├── Shorter log retention (7 days vs 30 days)
├── Single AZ deployment option
├── Scheduled shutdown during off-hours (optional)
└── Spot instances for batch processing

Production Environment:
├── Reserved instances for predictable workloads
├── Savings plans for compute usage
├── Multi-AZ only where required
├── Automated resource cleanup
└── Cost allocation tags for tracking
```

### Performance Monitoring

#### Application Performance Targets
```bash
Response Time Targets:
├── Page load time: <2 seconds (95th percentile)
├── API response time: <500ms (average)
├── Database queries: <100ms (average)
└── Image loading: <1 second

Availability Targets:
├── Overall uptime: 99.9% (8.76 hours downtime/year)
├── Service availability: 99.95% per service
├── Database availability: 99.99% (Multi-AZ)
└── Load balancer availability: 99.99%

Scalability Targets:
├── Auto-scale trigger: 70% CPU or 80% memory
├── Scale-out time: <2 minutes
├── Maximum concurrent users: 1000+
└── Peak traffic handling: 10x normal load
```

#### Real-time Monitoring Commands
```bash
# Monitor ECS services
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View real-time logs
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow

# Monitor Lambda analytics
aws lambda get-function --function-name sweetdream-service-backend-export-logs

# Check RDS performance
aws rds describe-db-instances --db-instance-identifier sweetdream-db

# S3 analytics storage usage
aws s3 ls s3://your-analytics-bucket --recursive --human-readable --summarize
```

### Cost Monitoring Tools

#### AWS Cost Management
```bash
# Set up billing alerts
aws budgets create-budget --account-id <account-id> --budget file://budget.json

# Monitor daily costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity DAILY

# Cost allocation by service
aws ce get-dimension-values --dimension SERVICE --time-period Start=2024-01-01,End=2024-01-31
```

#### Custom Cost Tracking
- ✅ Environment-specific cost allocation tags
- ✅ Service-level cost breakdown
- ✅ Daily cost reports via Lambda
- ✅ Budget alerts at 50%, 80%, 100% thresholds
- ✅ Cost optimization recommendations

### Monitoring Best Practices

#### Proactive Monitoring
- ✅ Set up synthetic monitoring for critical user journeys
- ✅ Monitor business metrics (orders, revenue, user activity)
- ✅ Track deployment success rates and rollback frequency
- ✅ Monitor security events and access patterns
- ✅ Regular performance baseline reviews

#### Incident Response
```bash
Incident Severity Levels:
├── P0 (Critical): Complete service outage
├── P1 (High): Major feature unavailable
├── P2 (Medium): Performance degradation
└── P3 (Low): Minor issues or warnings

Response Times:
├── P0: Immediate response (<5 minutes)
├── P1: 15 minutes
├── P2: 1 hour
└── P3: Next business day
```

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

## 🔧 Production Fixes

### Infrastructure Issues Resolved

This section documents critical infrastructure issues that were identified and resolved during production deployment.

#### 1. Region Mismatch Resolution
**Problem**: Production environment was configured for `us-east-2` but Terraform state bucket was in `us-west-2`
```bash
# Solution Applied:
- Updated production configuration to use us-west-2 region consistently
- Modified terraform/environments/prod/main.tf and terraform.tfvars
- Ensured all AWS resources deploy to the same region
```

#### 2. VPC CIDR Configuration
**Problem**: VPC module was missing CIDR block configuration causing deployment failures
```bash
# Solution Applied:
- Added vpc_cidr = "10.0.0.0/16" to production configuration
- Updated terraform/environments/prod/terraform.tfvars
- Ensured non-overlapping CIDR blocks between environments
```

#### 3. Dynamic Availability Zones
**Problem**: VPC module used hardcoded `us-east-1` availability zones
```bash
# Solution Applied:
- Updated terraform/modules/vpc/main.tf to use dynamic AZ selection
- Implemented data.aws_availability_zones.available
- Made infrastructure region-agnostic for multi-environment support
```

#### 4. IAM Resource Naming Conflicts
**Problem**: IAM resources had static names causing conflicts between environments
```bash
# Solution Applied:
- Made IAM resource names environment-specific
- Added environment parameter to terraform/modules/iam/
- Updated all IAM roles, policies, and instance profiles
```

#### 5. RDS Security Group Integration
**Problem**: RDS module didn't accept security group parameter for proper isolation
```bash
# Solution Applied:
- Added rds_security_group_id parameter to RDS module
- Updated terraform/modules/rds/main.tf and variables.tf
- Ensured proper network isolation between services
```

#### 6. ALB Routing Rules Implementation
**Problem**: User service and order service target groups weren't associated with ALB listener rules
```bash
# Solution Applied:
- Added conditional ALB routing rules for production environment
- Implemented path-based routing: /api/users/*, /api/auth/*, /api/orders/*
- Updated terraform/modules/alb/main.tf with proper listener rules
```

#### 7. Target Group Dependencies
**Problem**: ECS services failed to create because target groups weren't associated with load balancer
```bash
# Solution Applied:
- Added explicit dependencies between target groups and ALB
- Implemented proper listener rules for all services
- Updated production configuration to use CodeDeploy Blue/Green
- Added dependency management in terraform/environments/prod/main.tf
```

### Current Production Status

#### Successfully Deployed Components
```bash
Infrastructure Status:
├── VPC with public/private subnets (us-west-2)
├── Security groups with proper isolation
├── ALB with target groups and routing rules
├── ECS cluster with all 4 services
├── RDS PostgreSQL with Multi-AZ
├── CodeDeploy applications and deployment groups
├── Target groups associated with load balancer
├── Service discovery and secrets management
└── CloudWatch logging and monitoring
```

#### 🏗️ Architecture Summary
```bash
Service Deployment Strategy:
├── Backend Service: ECS with service discovery (Running - 2/2 tasks)
├── Frontend: CodeDeploy Blue/Green (Awaiting initial deployment)
├── User Service: CodeDeploy Blue/Green (Awaiting initial deployment)
└── Order Service: CodeDeploy Blue/Green (Awaiting initial deployment)

Database Configuration:
├── RDS PostgreSQL with proper security group isolation
├── Multi-AZ deployment for high availability
├── Automated backups and maintenance windows
└── Connection pooling and performance monitoring
```

#### 🌐 Load Balancer Configuration
```bash
ALB Routing Rules:
├── Frontend: Default route (/) → Blue/Green target groups
├── Backend API: /api/* → Service discovery (running)
├── User Service: /api/users/*, /api/auth/* → Blue/Green target groups
└── Order Service: /api/orders/* → Blue/Green target groups

Current Status:
├── ALB DNS: sweetdream-alb-*.us-west-2.elb.amazonaws.com
├── Health Status: 503 Service Unavailable (expected - awaiting deployments)
├── Target Groups: Created and properly associated
└── SSL/TLS: Ready for ACM certificate attachment
```

### Lessons Learned & Best Practices

#### Infrastructure as Code Improvements
```bash
Best Practices Implemented:
├── Environment-specific variable files
├── Dynamic resource naming with environment prefixes
├── Proper dependency management between modules
├── Region-agnostic infrastructure code
├── Comprehensive output values for integration
└── Modular design for reusability
```

#### Multi-Environment Strategy
```bash
Separation Strategy:
├── Separate AWS regions (dev: us-east-1, prod: us-west-2)
├── Isolated Terraform state buckets
├── Environment-specific CIDR blocks
├── Different scaling and retention policies
├── Separate ECR repositories with lifecycle policies
└── Environment-aware CI/CD pipelines
```

#### Security Enhancements
```bash
Security Improvements:
├── Least-privilege IAM roles per service
├── Network isolation with security groups
├── Secrets management with AWS Secrets Manager
├── Encrypted storage for RDS and S3
├── VPC Flow Logs for network monitoring
└── Regular security group auditing
```

### Future Enhancements

#### Planned Improvements
```bash
Infrastructure Roadmap:
├── Auto-scaling policies based on custom metrics
├── CloudFront distribution for global content delivery
├── WAF integration for application security
├── ElastiCache for session and data caching
├── Route 53 health checks and failover
└── Cross-region backup and disaster recovery

Monitoring Enhancements:
├── Custom CloudWatch metrics for business KPIs
├── Distributed tracing with AWS X-Ray
├── Synthetic monitoring for user journeys
├── Cost optimization recommendations automation
└── Predictive scaling based on historical patterns
```

#### Operational Excellence
```bash
DevOps Improvements:
├── Automated infrastructure testing with Terratest
├── Policy as Code with AWS Config rules
├── Automated security scanning in CI/CD
├── Infrastructure drift detection and remediation
└── Chaos engineering for resilience testing
```

**Built with love for learning cloud-native architecture**
