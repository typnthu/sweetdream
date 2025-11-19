# SweetDream E-commerce Platform

A full-stack e-commerce platform for selling cakes and desserts.

## 🚀 Quick Start

See [START_HERE.md](./START_HERE.md) for detailed setup instructions.

## 📁 Project Structure

- `fe/` - Frontend (Next.js + React)
- `be/` - Backend (Express + Prisma)
- `terraform/` - AWS Infrastructure
- `.github/workflows/` - CI/CD Pipelines

## 🛠️ Tech Stack

- **Frontend:** Next.js 15, React 19, TypeScript, Tailwind CSS
- **Backend:** Express.js, Prisma, PostgreSQL, TypeScript
- **Infrastructure:** AWS ECS, RDS, ALB, Terraform
- **CI/CD:** GitHub Actions

## 📚 Documentation

- [Getting Started](./START_HERE.md)
- [Backend API](./be/README.md)
- [Frontend](./fe/README.md)
- [Infrastructure](./terraform/README.md)

## 🔧 Development

```bash
# Backend
cd be && npm install && npm run dev

# Frontend
cd fe && npm install && npm run dev
```

## 🚀 Deployment

```bash
# Setup AWS resources
.\scripts\setup-cicd.ps1  # Windows
./scripts/setup-cicd.sh   # Linux/Mac

# Deploy via GitHub Actions
git push origin dev
```

## 📝 License

MIT
