# SweetDream E-Commerce Platform

A full-stack e-commerce platform built with modern cloud-native architecture on AWS.

## 🏗️ Architecture

### Microservices
- **Frontend**: Next.js 14 - Customer-facing web application
- **Backend**: Express.js - Product catalog and cart management
- **User Service**: Express.js - Authentication and user management
- **Order Service**: Express.js - Order processing

### Infrastructure
- **Cloud**: AWS (ECS Fargate, RDS PostgreSQL, ALB, S3)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch with analytics export to S3

## 🚀 Quick Start

### Local Development

```bash
# Clone and setup
git clone <repository-url>
cd sweetdream

# Copy environment files
cp be/.env.example be/.env
cp fe/.env.example fe/.env
cp order-service/.env.example order-service/.env

# Start with Docker Compose
docker-compose up -d
```

**Access**:
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- Order Service: http://localhost:3002
- User Service: http://localhost:3003

### AWS Deployment

```bash
# Configure AWS
aws configure

# Deploy infrastructure
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform apply

# GitHub Actions handles image builds and deployments automatically
```

## 📁 Project Structure

```
sweetdream/
├── be/                      # Backend service
├── fe/                      # Frontend (Next.js)
├── order-service/           # Order processing
├── user-service/            # Authentication
├── terraform/               # Infrastructure as Code
│   └── modules/
│       ├── vpc/
│       ├── ecs/
│       ├── rds/
│       ├── alb/
│       ├── cloudwatch-analytics/
│       └── bastion/
├── .github/workflows/       # CI/CD pipelines
└── scripts/                 # Utility scripts
    ├── set-user-role.ps1
    └── setup-admin.ps1
```

## 🔑 Features

### Customer
- Product catalog with search and filtering
- Shopping cart management
- User authentication
- Order placement and tracking

### Admin
- Order management and status updates
- Customer analytics dashboard

### Technical
- Microservices architecture
- Auto-scaling with ECS Fargate
- CloudWatch logging and monitoring
- Daily analytics export to S3
- Service discovery with AWS Cloud Map

## 📊 Analytics

Customer behavior analytics with daily S3 export:
- Product views and cart additions
- Purchase funnel analysis
- Best-selling products
- Customer frequency metrics

View analytics: CloudWatch Insights or S3 exports at `s3://sweetdream-analytics-*/user-actions/`

## 🔐 Security

- AWS Secrets Manager for credentials
- VPC with public/private subnets
- Security groups for network isolation
- IAM roles with least privilege
- HTTPS/TLS via ALB

## 🛠️ Development

### Database Migrations
```bash
cd be
npx prisma migrate dev
npx prisma generate
npm run seed
```

### Admin Setup

Admin user is **automatically created** on container startup:
- Email: `admin@sweetdream.com`
- Password: `admin123`

No manual steps required! Just run:
```bash
docker-compose up -d --build
```

### User Role Management
```bash
# Change user role
.\scripts\set-user-role.ps1 -Email "user@example.com" -Role "ADMIN"
.\scripts\set-user-role.ps1 -Email "user@example.com" -Role "CUSTOMER"
```

Note: Users must log in again after role changes to receive a new token with updated permissions.

### Testing
```bash
# Backend
cd be && npm test

# Frontend
cd fe && npm test
```

## 📝 API Endpoints

### Backend (3001)
- `GET /api/products` - List products
- `GET /api/products/:id` - Product details
- `POST /api/cart` - Add to cart
- `GET /api/cart/:userId` - Get cart

### User Service (3003)
- `POST /api/auth/register` - Register
- `POST /api/auth/login` - Login
- `POST /api/auth/verify` - Verify token
- `GET /api/customers` - List customers
- `GET /api/customers/:id` - Get customer
- `PATCH /api/customers/:id/role` - Update role (admin)
- `PATCH /api/customers/email/:email/role` - Update role by email (admin)

### Order Service (3002)
- `POST /api/orders` - Create order
- `GET /api/orders/user/:userId` - User orders
- `PATCH /api/orders/:id/status` - Update status

## 🚢 Deployment

### Automated (GitHub Actions)
Push to `main` or `dev` branch triggers:
1. Smart change detection
2. Parallel service builds
3. ECR image push
4. ECS deployment

See `.github/workflows/README.md` for details.

### Manual Scripts
```powershell
# Setup admin user (if needed)
.\scripts\setup-admin.ps1

# Change user role
.\scripts\set-user-role.ps1 -Email "user@example.com" -Role "ADMIN"
```

## 🔧 Troubleshooting

### View logs
```bash
aws logs tail /ecs/sweetdream-sweetdream-service-backend --follow
```

### Check service status
```bash
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend
```

### Database access
```bash
# Enable bastion in terraform.tfvars
enable_bastion = true
terraform apply

# Connect
aws ssm start-session --target <bastion-instance-id>
```

## 📦 Environment Variables

### Backend
```env
DATABASE_URL=postgresql://user:password@host:5432/database
PORT=3001
NODE_ENV=production
```

### Frontend
```env
NEXT_PUBLIC_BACKEND_URL=http://backend-url:3001
NEXT_PUBLIC_USER_SERVICE_URL=http://user-service-url:3003
NEXT_PUBLIC_ORDER_SERVICE_URL=http://order-service-url:3002
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/name`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/name`)
5. Open Pull Request

## 📄 License

MIT License

---

**Note**: Demo project. Ensure proper security, monitoring, and backups for production use.
