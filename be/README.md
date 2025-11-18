# SweetDream Backend API

A Node.js/Express backend API for the SweetDream e-commerce platform, designed to run on AWS ECS with MySQL RDS.

## 🏗️ Architecture

- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL (AWS RDS)
- **ORM**: Prisma
- **Container**: Docker
- **Deployment**: AWS ECS Fargate
- **Load Balancer**: AWS Application Load Balancer

## 🚀 Quick Start

### Local Development

1. **Install dependencies**:
```bash
npm install
```

2. **Set up environment variables**:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

3. **Set up database**:
```bash
# Generate Prisma client
npm run generate

# Run migrations
npm run migrate

# Or push schema to database
npm run db:push
```

4. **Start development server**:
```bash
npm run dev
```

The API will be available at `http://localhost:3001`

### Using Docker Compose (Local)

1. **Start all services**:
```bash
docker-compose up -d
```

This will start:
- PostgreSQL database on port 5432
- Backend API on port 3001

2. **Run migrations**:
```bash
docker-compose exec api npm run migrate
```

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
- `PATCH /api/orders/:id/status` - Update order status
- `DELETE /api/orders/:id` - Delete order

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

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Docker** installed
3. **AWS Account** with ECS, RDS, and ECR access

### Step 1: Deploy Infrastructure

```bash
# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name sweetdream-infrastructure \
  --template-body file://aws/cloudformation-infrastructure.yml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=DBUsername,ParameterValue=sweetdream \
               ParameterKey=DBPassword,ParameterValue=YourSecurePassword123 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Step 2: Create Secrets in AWS Secrets Manager

```bash
# Database URL secret
aws secretsmanager create-secret \
  --name "sweetdream/database-url" \
  --description "Database connection URL for SweetDream" \
  --secret-string "postgresql://admin:YourSecurePassword123@your-rds-endpoint.region.rds.amazonaws.com:5432/sweetdream"

# JWT Secret
aws secretsmanager create-secret \
  --name "sweetdream/jwt-secret" \
  --description "JWT secret for SweetDream API" \
  --secret-string "your-super-secret-jwt-key-change-this-in-production"
```

### Step 3: Update Configuration Files

1. **Update `aws/task-definition.json`**:
   - Replace `YOUR_ACCOUNT_ID` with your AWS account ID
   - Replace `YOUR_REGION` with your AWS region
   - Update secret ARNs

2. **Update `aws/service-definition.json`**:
   - Replace subnet IDs and security group IDs from CloudFormation outputs
   - Update target group ARN

3. **Update `deploy.sh`**:
   - Set your AWS account ID and region

### Step 4: Deploy Application

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Step 5: Run Database Migrations

```bash
# Connect to ECS task and run migrations
aws ecs execute-command \
  --cluster sweetdream-cluster \
  --task TASK_ID \
  --container sweetdream-api \
  --interactive \
  --command "npm run migrate"
```

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
| `DATABASE_URL` | MySQL connection string | - |
| `JWT_SECRET` | JWT signing secret | - |
| `FRONTEND_URL` | Frontend URL for CORS | http://localhost:3000 |

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

1. **Database**: Use RDS with Multi-AZ for high availability
2. **Scaling**: Configure ECS auto-scaling based on CPU/memory
3. **SSL/TLS**: Add HTTPS listener to ALB with ACM certificate
4. **Monitoring**: Set up CloudWatch alarms and dashboards
5. **Backup**: Configure automated RDS backups
6. **Security**: Use AWS WAF for additional protection

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

For detailed API documentation, you can:

1. Import the Postman collection (coming soon)
2. Use the health check endpoint to verify the API is running
3. Check the route files in `src/routes/` for endpoint details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.