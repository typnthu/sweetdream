# 🍰 SweetDream E-commerce Platform

A full-stack e-commerce platform with microservices architecture, ready for AWS deployment.

## ⚡ Quick Start

**New here?** → Read **[GETTING_STARTED.md](GETTING_STARTED.md)** ⭐

### Local Development (10 minutes)
```powershell
# Start database
docker-compose -f docker-compose.dev.yml up -d

# Start all services
.\start-all-services.ps1

# Open browser
http://localhost:3000
```

### AWS Deployment (30 minutes)
```powershell
# Deploy infrastructure (one-time)
cd terraform
terraform apply -var="db_password=YourPassword"

# Setup GitHub Actions for auto-deploy
# See GETTING_STARTED.md Part 2
```

---

## 🏗️ Architecture

```
Frontend (Next.js) → http://localhost:3000
    ├─→ User Service (Auth) → http://localhost:3001
    ├─→ Order Service (Orders) → http://localhost:3002
    └─→ Backend Service (Products) → http://localhost:3003
```

**Microservices:**
- **Frontend:** Next.js, React, TailwindCSS
- **User Service:** Authentication, customer management
- **Order Service:** Order processing, communicates with User Service
- **Backend Service:** Products, categories, database

---

## 📁 Project Structure

```
sweetdream/
├── GETTING_STARTED.md              ⭐ Start here!
├── README.md                       # This file
│
├── fe/                             # Frontend (Next.js)
├── be/                             # Backend Service
├── order-service/                  # Order Management
├── user-service/                   # User Management
│
├── terraform/                      # AWS Infrastructure
├── .github/workflows/              # CI/CD Pipelines
│   ├── deploy-hybrid.yml           # Auto-deployment
│   ├── backend-ci.yml              # Backend tests
│   ├── frontend-ci.yml             # Frontend tests
│   └── pr-checks.yml               # PR validation
│
├── docker-compose.dev.yml          # Local database
├── docker-compose.microservices.yml # All services
├── start-all-services.ps1          # Quick start script
└── check-services.ps1              # Health check script
```

---

## 📚 Documentation

| File | Purpose |
|------|---------|
| **[GETTING_STARTED.md](GETTING_STARTED.md)** | Complete setup guide ⭐ |
| [HYBRID_DEPLOYMENT_GUIDE.md](HYBRID_DEPLOYMENT_GUIDE.md) | AWS deployment (hybrid approach) |
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | Architecture details |
| [GITHUB_WORKFLOWS_EXPLAINED.md](GITHUB_WORKFLOWS_EXPLAINED.md) | CI/CD workflows |
| [FULL_STACK_MICROSERVICES.md](FULL_STACK_MICROSERVICES.md) | Microservices guide |
| [START_HERE_MICROSERVICES.md](START_HERE_MICROSERVICES.md) | Local microservices |
| [CICD_BEST_PRACTICES.md](CICD_BEST_PRACTICES.md) | CI/CD best practices |

---

## ✨ Features

- 🛍️ Product catalog with categories
- 🛒 Shopping cart
- 👤 User authentication
- 📦 Order management
- 👨‍💼 Admin panel
- 🔄 Real-time order status
- 📱 Responsive design
- ☁️ AWS deployment ready
- 🚀 CI/CD with GitHub Actions

---

## 🚀 Technologies

**Frontend:**
- Next.js 15
- React 19
- TypeScript
- TailwindCSS

**Backend:**
- Node.js
- Express
- Prisma ORM
- PostgreSQL

**Infrastructure:**
- AWS ECS (Fargate)
- AWS RDS (PostgreSQL)
- AWS ALB (Load Balancer)
- AWS S3 (Image storage)
- Terraform (IaC)

**CI/CD:**
- GitHub Actions
- Docker
- AWS ECR

---

## 🎯 Quick Commands

```powershell
# Local Development
docker-compose -f docker-compose.dev.yml up -d  # Start database
.\start-all-services.ps1                        # Start all services
.\check-services.ps1                            # Check health

# AWS Deployment
cd terraform && terraform apply                 # Deploy infrastructure
git push origin dev                             # Auto-deploy code

# Database
cd be && npx prisma migrate dev                 # Run migrations
cd be && npm run seed                           # Seed data

# Logs
docker-compose -f docker-compose.dev.yml logs -f  # Local logs
aws logs tail /ecs/sweetdream --follow            # AWS logs
```

---

## 🔑 Default Credentials

**Admin:**
- Email: `admin@sweetdream.com`
- Password: `admin123`

**Test User:**
- Email: `user@example.com`
- Password: `123456`

---

## 💰 AWS Cost Estimate

**Monthly:** ~$100 USD
- RDS PostgreSQL: ~$30
- ECS Fargate: ~$40
- Application Load Balancer: ~$20
- S3 Storage: ~$1
- Data Transfer: ~$9

**Can be reduced by:**
- Stopping services when not in use
- Using smaller RDS instance
- Scaling down ECS tasks

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

**Issues?** Check:
1. [GETTING_STARTED.md](GETTING_STARTED.md) - Setup guide
2. GitHub Issues - Report bugs
3. Documentation files - Detailed guides

---

**Ready to start?** → [GETTING_STARTED.md](GETTING_STARTED.md) ⭐

2. **Start Services:** (4 terminals)
   ```bash
   # See START_HERE_MICROSERVICES.md for detailed commands
   .\start-all-services.ps1  # Shows instructions
   ```

3. **Access:**
   - Frontend: http://localhost:3000
   - User Service: http://localhost:3001
   - Order Service: http://localhost:3002
   - Backend Service: http://localhost:3003

### AWS Deployment

```bash
# Deploy infrastructure and application
.\deploy-to-aws.ps1

# Or follow step-by-step guide
# See: AWS_DEPLOYMENT_CHECKLIST.md
```

## 🛠️ Tech Stack

**Frontend:**
- Next.js 16, React 19, TypeScript, Tailwind CSS

**Microservices:**
- User Service: Express.js, JWT Authentication
- Order Service: Express.js, HTTP Communication
- Backend Service: Express.js, Prisma ORM

**Infrastructure:**
- AWS ECS Fargate, RDS PostgreSQL, ALB
- Terraform (Infrastructure as Code)
- GitHub Actions (CI/CD)

**Database:**
- PostgreSQL 15

## 📚 Documentation

### Getting Started
- **[START_HERE_MICROSERVICES.md](./START_HERE_MICROSERVICES.md)** - Quick start guide
- **[FULL_STACK_MICROSERVICES.md](./FULL_STACK_MICROSERVICES.md)** - Complete microservices guide
- **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)** - Full project documentation

### Deployment
- **[AWS_DEPLOYMENT_CHECKLIST.md](./AWS_DEPLOYMENT_CHECKLIST.md)** - AWS deployment
- **[CICD_BEST_PRACTICES.md](./CICD_BEST_PRACTICES.md)** - CI/CD explanation

### Analysis
- **[RUBRIC_ANALYSIS.md](./RUBRIC_ANALYSIS.md)** - Rubric requirements analysis

## ✅ Features

### Customer Features
- Browse products by category
- Add to cart with size selection
- Place orders with customer information
- Order confirmation

### Admin Features
- Product management
- Order management
- Customer management
- Category management

### Microservices
- **User Service:** User registration and authentication
- **Order Service:** Order processing (communicates with User Service)
- **Backend Service:** Product catalog management

## 🔧 Development Commands

```bash
# Check service health
.\check-services.ps1

# Start all services
.\start-all-services.ps1

# Deploy to AWS
.\deploy-to-aws.ps1
```

## 🎯 Rubric Requirements

✅ **Two Microservices:**
- User Service (registration/authentication)
- Order Service (purchase processing)

✅ **Service Communication:**
- Order Service calls User Service via HTTP REST API

✅ **Full Stack Application:**
- Frontend, Backend, Database
- 12+ pages (exceeds requirement)

✅ **Cloud Deployment:**
- AWS ECS, RDS, ALB
- Infrastructure as Code (Terraform)
- CI/CD (GitHub Actions)

## 📊 Architecture Benefits

- **Scalability:** Each service scales independently
- **Maintainability:** Clear separation of concerns
- **Flexibility:** Services can use different technologies
- **Reliability:** Fault isolation between services

## 🆘 Troubleshooting

```bash
# Check if all services are running
.\check-services.ps1

# View service logs
docker-compose -f docker-compose.microservices.yml logs -f

# Restart services
docker-compose -f docker-compose.microservices.yml restart
```

## 📝 License

MIT

---

**For detailed instructions, see [START_HERE_MICROSERVICES.md](./START_HERE_MICROSERVICES.md)**
