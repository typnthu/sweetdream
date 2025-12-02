# SweetDream Frontend

Next.js 15 frontend for the SweetDream e-commerce platform with App Router and TailwindCSS.

## 🏗️ Architecture

- **Framework**: Next.js 15 (App Router)
- **UI Library**: React 19
- **Styling**: TailwindCSS 4
- **Language**: TypeScript 5
- **State**: React Context API
- **API**: Proxy routes to backend microservices
- **Port**: 3000

## 🚀 Quick Start

### Local Development

1. **Install dependencies**:
```bash
npm install
```

2. **Set up environment**:
```bash
cp .env.example .env.local
```

Edit `.env.local` for **monolithic mode** (single backend):
```env
NEXT_PUBLIC_API_URL=http://localhost:3001
BACKEND_API_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3001
ORDER_SERVICE_URL=http://localhost:3001
```

Or for **microservices mode**:
```env
NEXT_PUBLIC_API_URL=/api/proxy
BACKEND_API_URL=http://localhost:3003
USER_SERVICE_URL=http://localhost:3001
ORDER_SERVICE_URL=http://localhost:3002
```

3. **Start development server**:
```bash
npm run dev
```

The app will be available at `http://localhost:3000`

## 📱 Features

### Customer Pages
- `/` - Home page with featured products
- `/menu` - Product catalog with category filter
- `/product/[id]` - Product details with size selection
- `/cart` - Shopping cart
- `/success` - Order confirmation
- `/login` - Customer login

### Admin Pages
- `/admin` - Admin dashboard
- `/admin/products` - Add new products
- `/admin/products/list` - Manage products
- `/admin/orders` - Order management
- `/admin/customers` - Customer management
- `/admin/categories` - Category management
- `/admin/migrate` - Database tools

## 🔌 API Integration

The frontend uses a proxy pattern to communicate with backend microservices:

```
Frontend Request → /api/proxy/[...path] → Backend Service
```

### Proxy Routes

| Path | Target Service | Port |
|------|---------------|------|
| `/api/proxy/products` | Backend | 3003 |
| `/api/proxy/categories` | Backend | 3003 |
| `/api/proxy/customers` | User Service | 3001 |
| `/api/proxy/auth` | User Service | 3001 |
| `/api/proxy/orders` | Order Service | 3002 |

### Example API Calls

```typescript
// Get products
const response = await fetch('/api/proxy/products');
const products = await response.json();

// Create order
const response = await fetch('/api/proxy/orders', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(orderData)
});
```

## 🎨 Styling

Uses TailwindCSS 4 with custom configuration:

- **Colors**: Pink theme (`pink-500`, `pink-600`)
- **Responsive**: Mobile-first design
- **Icons**: React Icons library
- **Fonts**: System fonts

## 🔧 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | Public API URL (client-side) | `http://localhost:3001` |
| `BACKEND_API_URL` | Backend service URL (server-side) | `http://localhost:3003` |
| `USER_SERVICE_URL` | User service URL (server-side) | `http://localhost:3001` |
| `ORDER_SERVICE_URL` | Order service URL (server-side) | `http://localhost:3002` |

**Note**: Variables prefixed with `NEXT_PUBLIC_` are exposed to the browser.

## 🐳 Docker Build

```bash
# Build image
docker build -t sweetdream-frontend .

# Run container
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=/api/proxy \
  -e BACKEND_API_URL=http://backend:3003 \
  sweetdream-frontend
```

## 🚀 AWS Deployment

Deployment is automated via GitHub Actions. The frontend is deployed to ECS Fargate.

### Manual Build & Push

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push
docker build -t $ECR_REGISTRY/sweetdream-frontend:latest .
docker push $ECR_REGISTRY/sweetdream-frontend:latest
```

### Environment Variables (AWS)

Set in ECS task definition:
```env
NEXT_PUBLIC_API_URL=/api/proxy
BACKEND_API_URL=http://sweetdream-service-backend.local:3003
USER_SERVICE_URL=http://sweetdream-service-user.local:3001
ORDER_SERVICE_URL=http://sweetdream-service-order.local:3002
```

## 📂 Project Structure

```
fe/
├── src/
│   ├── app/                    # Pages (App Router)
│   │   ├── admin/              # Admin panel
│   │   ├── api/proxy/          # API proxy routes
│   │   ├── cart/               # Shopping cart
│   │   ├── login/              # Login page
│   │   ├── menu/               # Product catalog
│   │   ├── product/            # Product details
│   │   ├── success/            # Order confirmation
│   │   ├── layout.tsx          # Root layout
│   │   └── page.tsx            # Home page
│   ├── components/             # React components
│   │   ├── AuthGuard.tsx       # Authentication wrapper
│   │   ├── Navbar.tsx          # Navigation bar
│   │   └── ...
│   └── context/                # State management
│       └── CartContext.tsx     # Shopping cart state
├── public/                     # Static assets
├── Dockerfile                  # Container image
├── next.config.ts              # Next.js configuration
├── tailwind.config.ts          # TailwindCSS configuration
└── package.json
```

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

# Lint code
npm run lint
```

## 🔗 Related Services

- **Backend**: [../be/](../be/)
- **User Service**: [../user-service/](../user-service/)
- **Order Service**: [../order-service/](../order-service/)
- **Infrastructure**: [../terraform/](../terraform/)
- **Main README**: [../README.md](../README.md)
