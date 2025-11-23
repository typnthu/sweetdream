# 🚀 Getting Started - SweetDream E-commerce

## Quick Overview

SweetDream is a full-stack e-commerce platform with:
- 🎨 Next.js frontend
- 🔧 Microservices backend (4 services)
- 🗄️ PostgreSQL database
- ☁️ AWS deployment ready
- 🔄 CI/CD with GitHub Actions

---

## Choose Your Path

### 🏠 Local Development (Start Here)
**Time:** 10 minutes  
**Best for:** Development, testing features  
→ See [Part 1: Local Development](#part-1-local-development)

### ☁️ AWS Deployment
**Time:** 30 minutes + setup  
**Best for:** Production deployment  
→ See [Part 2: AWS Deployment](#part-2-aws-deployment)

---

# Part 1: Local Development

## Prerequisites

- ✅ Node.js 20+ installed
- ✅ Docker Desktop installed and running
- ✅ Git installed

## Step 1: Clone & Install

```powershell
# Clone repository
git clone <your-repo-url>
cd sweetdream

# Install dependencies for all services
cd be && npm install && cd ..
cd fe && npm install && cd ..
cd order-service && npm install && cd ..
cd user-service && npm install && cd ..
```

## Step 2: Start Database

```powershell
# Start PostgreSQL in Docker
docker-compose -f docker-compose.dev.yml up -d

# Verify it's running
docker ps
```

## Step 3: Setup Backend Service

```powershell
cd be

# Create .env file
copy .env.example .env

# Edit .env with your settings:
# DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
# PORT=3003

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Seed database with sample data
npm run seed

# Start backend
npm run dev
```

**Backend running at:** http://localhost:3003

## Step 4: Setup Order Service

```powershell
# Open new terminal
cd order-service

# Create .env file
copy .env.example .env

# Edit .env:
# DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
# PORT=3002
# USER_SERVICE_URL=http://localhost:3001

# Generate Prisma client
npx prisma generate

# Start service
npm run dev
```

**Order Service running at:** http://localhost:3002

## Step 5: Setup User Service

```powershell
# Open new terminal
cd user-service

# Create .env file
copy .env.example .env

# Edit .env:
# DATABASE_URL=postgresql://postgres:postgres@localhost:5432/sweetdream
# PORT=3001

# Generate Prisma client
npx prisma generate

# Start service
npm run dev
```

**User Service running at:** http://localhost:3001

## Step 6: Setup Frontend

```powershell
# Open new terminal
cd fe

# Create .env.local file
copy .env.example .env.local

# Edit .env.local:
# NEXT_PUBLIC_API_URL=http://localhost:3000/api/proxy

# Start frontend
npm run dev
```

**Frontend running at:** http://localhost:3000

## Step 7: Test Your Application

1. **Open browser:** http://localhost:3000
2. **Browse products** - Should see sample products
3. **Register account** - Create a test account
4. **Add to cart** - Add some products
5. **Place order** - Complete checkout
6. **Admin panel:** http://localhost:3000/admin
   - Email: `admin@sweetdream.com`
   - Password: `admin123`

## Quick Start Script (Alternative)

Instead of manual steps, use the start script:

```powershell
# Start all services at once
.\start-all-services.ps1
```

This will:
- Start database
- Start all 4 services
- Open browser automatically

---

# Part 2: AWS Deployment

## Overview

**Deployment Strategy:** Hybrid Approach
- **Infrastructure (Terraform):** Deploy manually once
- **Application (Code):** Auto-deploy via GitHub Actions

**Monthly Cost:** ~$100 USD

## Prerequisites

1. ✅ AWS Account
2. ✅ AWS CLI installed
3. ✅ Terraform installed
4. ✅ Docker Desktop running
5. ✅ GitHub account

## Step 1: Install Tools

### AWS CLI (Windows)
```powershell
# Download and install
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify
aws --version
```

### Terraform (Windows)
```powershell
# Download from: https://www.terraform.io/downloads
# Or use Chocolatey:
choco install terraform

# Verify
terraform --version
```

## Step 2: Configure AWS

```powershell
# Configure AWS credentials
aws configure
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: us-east-1
# Default output format: json
```

**Get AWS credentials:**
1. Go to AWS Console → IAM
2. Create user with `AdministratorAccess`
3. Create access key
4. Save credentials

## Step 3: Deploy Infrastructure (One-Time)

```powershell
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan -var="db_password=YourSecurePassword123!"

# Deploy (takes 10-15 minutes)
terraform apply -var="db_password=YourSecurePassword123!" -auto-approve

# Save outputs
$ALB_URL = terraform output -raw alb_url
$DB_ENDPOINT = terraform output -raw db_endpoint
$S3_BUCKET = terraform output -raw s3_bucket_name

Write-Host "✅ Infrastructure deployed!"
Write-Host "ALB URL: $ALB_URL"

cd ..
```

**What this creates:**
- VPC with subnets
- RDS PostgreSQL database
- ECS Cluster
- Application Load Balancer
- S3 bucket for images
- Security groups & IAM roles

## Step 4: Create ECR Repositories

```powershell
# Get AWS account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Create repositories
aws ecr create-repository --repository-name sweetdream-backend --region us-east-1
aws ecr create-repository --repository-name sweetdream-frontend --region us-east-1
aws ecr create-repository --repository-name sweetdream-order-service --region us-east-1
aws ecr create-repository --repository-name sweetdream-user-service --region us-east-1
```

## Step 5: Build & Push Initial Images

```powershell
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Build and push backend
cd be
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest" .
docker push "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest"

# Build and push frontend
cd ../fe
docker build --build-arg NEXT_PUBLIC_API_URL="http://$ALB_URL" -t "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:latest" .
docker push "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:latest"

# Build and push order-service
cd ../order-service
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-order-service:latest" .
docker push "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-order-service:latest"

# Build and push user-service
cd ../user-service
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-user-service:latest" .
docker push "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/sweetdream-user-service:latest"

cd ..
```

## Step 6: Initialize Database

**Option A: Via Admin Panel (Easiest)**
1. Wait 2-3 minutes for services to start
2. Visit: `http://<alb-url>/admin/migrate`
3. Click "Run Migrations"
4. Click "Seed Database"

**Option B: Via Command Line**
```powershell
# Get backend task ARN
$TASK_ARN = aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-backend --query 'taskArns[0]' --output text

# Run migrations
aws ecs execute-command --cluster sweetdream-cluster --task $TASK_ARN --container sweetdream-backend --interactive --command "npm run migrate"
```

## Step 7: Upload Product Images

```powershell
# Upload images to S3
cd be/prisma/products
aws s3 sync . "s3://$S3_BUCKET/" --exclude "*.json" --acl public-read
cd ../../..
```

## Step 8: Setup GitHub Actions (Auto-Deploy)

### Configure GitHub Secrets

Go to: **GitHub → Settings → Secrets and variables → Actions**

Add these secrets:

| Secret Name | Value |
|------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_REGION` | `us-east-1` |
| `AWS_ACCOUNT_ID` | Your AWS account ID |

### Enable Auto-Deployment

```powershell
# Create dev branch
git checkout -b dev

# Push to trigger deployment
git add .
git commit -m "Setup AWS deployment"
git push -u origin dev
```

**GitHub Actions will automatically:**
- Build Docker images
- Push to ECR
- Deploy to ECS
- Show deployment status

## Step 9: Test Your Deployment

```powershell
# Open your application
Start-Process "http://$ALB_URL"
```

**Test:**
- ✅ Browse products
- ✅ Add to cart
- ✅ Register account
- ✅ Place order
- ✅ Admin panel: `http://<alb-url>/admin`

---

# Daily Workflow

## Local Development

```powershell
# Start all services
.\start-all-services.ps1

# Make changes to code
code .

# Test locally
# Visit http://localhost:3000

# Stop services
# Ctrl+C in each terminal
```

## Deploy to AWS

```powershell
# Make changes
code .

# Commit and push
git add .
git commit -m "Update feature"
git push origin dev

# GitHub Actions deploys automatically!
# Check status: GitHub → Actions tab
```

---

# Common Tasks

## Add New Product

1. Go to: http://localhost:3000/admin/products
2. Fill in product details
3. Add sizes and prices
4. Submit

## Add New Category

1. Go to: http://localhost:3000/admin/categories
2. Enter category name and description
3. Submit

## View Orders

**Admin:**
- http://localhost:3000/admin/orders

**User:**
- http://localhost:3000/success

## Run Database Migrations

**Local:**
```powershell
cd be
npx prisma migrate dev
```

**AWS:**
- Go to: GitHub → Actions → Database Migration → Run workflow

## View Logs

**Local:**
- Check terminal output

**AWS:**
```powershell
aws logs tail /ecs/sweetdream --follow
```

---

# Troubleshooting

## Local Development Issues

### Database connection failed
```powershell
# Check if Docker is running
docker ps

# Restart database
docker-compose -f docker-compose.dev.yml restart
```

### Port already in use
```powershell
# Find process using port
netstat -ano | findstr :3000

# Kill process
taskkill /PID <process-id> /F
```

### Prisma client not generated
```powershell
cd be
npx prisma generate
```

## AWS Deployment Issues

### Services not starting
```powershell
# Check service status
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-backend

# View logs
aws logs tail /ecs/sweetdream --follow
```

### Images not loading
```powershell
# Check S3 bucket
aws s3 ls "s3://$S3_BUCKET/"

# Make images public
aws s3api put-public-access-block --bucket $S3_BUCKET --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### GitHub Actions failed
1. Go to: GitHub → Actions
2. Click on failed workflow
3. Check error logs
4. Fix issue and push again

---

# Project Structure

```
sweetdream/
├── fe/                          # Frontend (Next.js)
│   ├── src/app/                 # Pages and components
│   ├── src/context/             # React contexts
│   └── public/                  # Static files
│
├── be/                          # Backend Service
│   ├── src/routes/              # API routes
│   ├── src/validators/          # Input validation
│   └── prisma/                  # Database schema
│
├── order-service/               # Order Management
│   └── src/                     # Order logic
│
├── user-service/                # User Management
│   └── src/                     # User/auth logic
│
├── terraform/                   # Infrastructure as Code
│   ├── modules/                 # Reusable modules
│   └── environments/            # Dev/prod configs
│
└── .github/workflows/           # CI/CD pipelines
    ├── deploy-hybrid.yml        # Main deployment
    ├── backend-ci.yml           # Backend tests
    ├── frontend-ci.yml          # Frontend tests
    └── pr-checks.yml            # PR validation
```

---

# Additional Resources

## Documentation

- **`PROJECT_OVERVIEW.md`** - Architecture details
- **`HYBRID_DEPLOYMENT_GUIDE.md`** - Detailed AWS deployment
- **`GITHUB_WORKFLOWS_EXPLAINED.md`** - CI/CD workflows
- **`FULL_STACK_MICROSERVICES.md`** - Microservices architecture
- **`START_HERE_MICROSERVICES.md`** - Local microservices setup
- **`CICD_BEST_PRACTICES.md`** - CI/CD best practices

## Scripts

- **`start-all-services.ps1`** - Start all services locally
- **`check-services.ps1`** - Check service health

## Docker Compose

- **`docker-compose.dev.yml`** - Local database
- **`docker-compose.microservices.yml`** - All services

---

# Quick Reference

## Local URLs

- Frontend: http://localhost:3000
- User Service: http://localhost:3001
- Order Service: http://localhost:3002
- Backend: http://localhost:3003
- Admin Panel: http://localhost:3000/admin

## Default Credentials

**Admin:**
- Email: `admin@sweetdream.com`
- Password: `admin123`

**Test User:**
- Email: `user@example.com`
- Password: `123456`

## Useful Commands

```powershell
# Start database
docker-compose -f docker-compose.dev.yml up -d

# Stop database
docker-compose -f docker-compose.dev.yml down

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Reset database
cd be
npx prisma migrate reset

# Deploy to AWS
git push origin dev

# View AWS logs
aws logs tail /ecs/sweetdream --follow

# Check AWS services
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-backend
```

---

# Next Steps

1. ✅ **Complete local setup** - Get everything running locally
2. ✅ **Test features** - Browse, cart, checkout, admin
3. ✅ **Deploy to AWS** - Follow Part 2 when ready
4. ✅ **Setup CI/CD** - Enable GitHub Actions
5. ✅ **Customize** - Add your products and branding

---

**Need help?** Check the documentation files or create an issue on GitHub.

**Ready to start?** Begin with [Part 1: Local Development](#part-1-local-development)! 🚀
