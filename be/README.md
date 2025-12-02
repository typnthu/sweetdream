# SweetDream Backend Service

Node.js/Express backend API for the SweetDream e-commerce platform. Handles products, categories, orders, and customers in a microservices architecture.

## 🏗️ Architecture

- **Runtime**: Node.js 20 + Express + TypeScript
- **Database**: PostgreSQL 15 (AWS RDS)
- **ORM**: Prisma 5
- **Container**: Docker
- **Deployment**: AWS ECS Fargate
- **Port**: 3001

## 🚀 Quick Start

### Local Development

1. **Start database** (from project root):
```bash
docker-compose -f docker-compose.dev.yml up -d
```

2. **Install dependencies**:
```bash
npm install
```

3. **Set up environment**:
```bash
cp .env.example .env
```

Edit `.env`:
```env
DATABASE_URL=postgresql://dev:dev123@localhost:5432/sweetdream
PORT=3001
```

4. **Set up database**:
```bash
npx prisma generate
npx prisma migrate dev
npm run seed
```

5. **Start development server**:
```bash
npm run dev
```

The API will be available at `http://localhost:3001`

## 📊 API Endpoints

### Products
- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get product by ID
- `GET /api/products/category/:categoryId` - Get products by category
- `POST /api/products` - Create new product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Categories
- `GET /api/categories` - Get all categories
- `GET /api/categories/:id` - Get category by ID
- `POST /api/categories` - Create new category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Orders
- `GET /api/orders` - Get all orders (with pagination)
- `GET /api/orders/:id` - Get order by ID
- `POST /api/orders` - Create new order
- `POST /api/orders/:id/cancel` - Cancel order
- `PATCH /api/orders/:id/status` - Update order status (Admin)
- `DELETE /api/orders/:id` - Delete order (Admin)

### Customers
- `GET /api/customers` - Get all customers (with pagination)
- `GET /api/customers/:id` - Get customer by ID
- `GET /api/customers/email/:email` - Get customer by email
- `POST /api/customers` - Create new customer
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer

### Health Check
- `GET /health` - Health check endpoint

## 🏗️ AWS Deployment

Deployment is automated via GitHub Actions. See the main [README.md](../README.md) for full deployment instructions.

### Manual Build & Push

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push
docker build -t $ECR_REGISTRY/sweetdream-backend:latest .
docker push $ECR_REGISTRY/sweetdream-backend:latest
```

### Environment Variables (AWS)

Set in ECS task definition:
- `DATABASE_URL`: RDS connection string (from Terraform output)
- `PORT`: 3001
- `NODE_ENV`: production

## 🗄️ Database Schema

The database includes the following tables:

- **categories**: Product categories
- **products**: Product information
- **product_sizes**: Product size and pricing variants
- **customers**: Customer information
- **orders**: Order records
- **order_items**: Individual items in orders

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/production) | development |
| `PORT` | Server port | 3001 |
| `DATABASE_URL` | PostgreSQL connection string | - |
| `S3_BUCKET` | S3 bucket for product images | sweetdream-products |

## 🔒 Security Features

- **Helmet.js**: Security headers
- **CORS**: Cross-origin resource sharing
- **Input validation**: Joi validation schemas
- **SQL injection protection**: Prisma ORM
- **Environment variables**: Sensitive data protection

## 📈 Monitoring & Logging

- **Health checks**: `/health` endpoint
- **CloudWatch Logs**: Centralized logging
- **ECS Service monitoring**: Built-in AWS monitoring
- **Application Load Balancer**: Health checks and traffic distribution

## 🚀 Production Considerations

1. **Database**: RDS PostgreSQL with automated backups
2. **Scaling**: ECS auto-scaling configured (2-10 tasks)
3. **Monitoring**: CloudWatch logs and metrics enabled
4. **Security**: Private subnets, security groups, IAM roles
5. **Images**: Product images stored in S3

## 🛠️ Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Database operations
npm run generate    # Generate Prisma client
npm run migrate     # Run migrations
npm run db:push     # Push schema changes
npm run db:studio   # Open Prisma Studio

# Docker operations
docker build -t sweetdream-backend .
docker run -p 3001:3001 sweetdream-backend
```

## 📝 API Documentation

See the main [README.md](../README.md#-api-documentation) for complete API documentation.

## 🔗 Related Services

- **Frontend**: [fe/](../fe/)
- **User Service**: [user-service/](../user-service/)
- **Order Service**: [order-service/](../order-service/)
- **Infrastructure**: [terraform/](../terraform/)