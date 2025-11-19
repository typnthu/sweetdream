# 🚀 SweetDream E-commerce Platform

Welcome to the SweetDream project! This is a full-stack e-commerce platform built with Next.js and Express.

## 📁 Project Structure

```
sweetdream/
├── fe/              # Frontend (Next.js)
├── be/              # Backend (Express + Prisma)
├── terraform/       # AWS Infrastructure
├── .github/         # CI/CD Workflows
└── scripts/         # Automation Scripts
```

## 🏃 Quick Start

### Local Development

1. **Backend Setup:**
   ```bash
   cd be
   npm install
   cp .env.example .env
   # Edit .env with your database URL
   npx prisma migrate dev
   npm run dev
   ```

2. **Frontend Setup:**
   ```bash
   cd fe
   npm install
   cp .env.example .env
   # Edit .env with backend API URL
   npm run dev
   ```

3. **Access:**
   - Frontend: http://localhost:3000
   - Backend: http://localhost:3001

### AWS Deployment

1. **Configure AWS:**
   ```bash
   aws configure
   ```

2. **Run Setup:**
   ```powershell
   # Windows
   .\scripts\setup-cicd.ps1
   
   # Linux/Mac
   chmod +x scripts/setup-cicd.sh
   ./scripts/setup-cicd.sh
   ```

3. **Configure GitHub Secrets:**
   - Go to: Settings → Secrets and variables → Actions
   - Add: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

4. **Deploy:**
   ```bash
   git checkout -b dev
   git push -u origin dev
   ```

## 🔧 Key Features

- ✅ Full-stack e-commerce platform
- ✅ Product catalog with categories
- ✅ Shopping cart functionality
- ✅ Order management
- ✅ AWS deployment ready
- ✅ CI/CD with GitHub Actions

## 📚 Documentation

- **Backend API:** See `be/README.md`
- **Frontend:** See `fe/README.md`
- **Infrastructure:** See `terraform/README.md`

## 🛠️ Tech Stack

**Frontend:**
- Next.js 15
- React 19
- TypeScript
- Tailwind CSS

**Backend:**
- Express.js
- Prisma ORM
- PostgreSQL
- TypeScript

**Infrastructure:**
- AWS ECS (Fargate)
- AWS RDS (PostgreSQL)
- AWS ALB
- Terraform

## 🚀 CI/CD Pipeline

The project includes automated workflows for:
- Code quality checks
- Testing (Backend, Frontend, Integration)
- Building Docker images
- Deploying to AWS
- Database migrations

## 📞 Need Help?

Check the README files in each directory for detailed information:
- Backend: `be/README.md`
- Frontend: `fe/README.md`
- Infrastructure: `terraform/README.md`
