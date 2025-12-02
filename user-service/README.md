# User Service

Authentication and user management service for the SweetDream e-commerce platform.

## 🔑 Responsibilities

- User registration and authentication
- JWT token generation and validation
- User profile management
- **Role management (CUSTOMER/ADMIN)**
- Customer data CRUD operations

## 🚀 Quick Start

### Local Development

```bash
npm install
cp .env.example .env

# Run migrations and seed admin user
npx prisma migrate dev
npm run seed

# Start server
npm run dev
```

This creates the default admin user:
- **Email:** admin@sweetdream.com
- **Password:** admin123
- **Role:** ADMIN

### Environment Variables

```env
PORT=3003
DATABASE_URL=postgresql://user:password@localhost:5432/sweetdream
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
FRONTEND_URL=http://localhost:3000
```

## 📝 API Endpoints

### Authentication

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "1234567890",
  "address": "123 Main St"
}
```

Response includes JWT token with user role.

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

Response includes JWT token with user role.

#### Verify Token
```http
POST /api/auth/verify
Content-Type: application/json

{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Customer Management

#### List Customers
```http
GET /api/customers?page=1&limit=10&search=john
```

#### Get Customer by ID
```http
GET /api/customers/:id
```

#### Get Customer by Email
```http
GET /api/customers/email/:email
```

#### Create Customer
```http
POST /api/customers
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "phone": "0987654321",
  "address": "456 Oak Ave"
}
```

#### Update Customer
```http
PUT /api/customers/:id
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane.smith@example.com",
  "phone": "0987654321",
  "address": "456 Oak Ave"
}
```

### Role Management

#### Update Role by ID
```http
PATCH /api/customers/:id/role
Content-Type: application/json

{
  "role": "ADMIN"
}
```

#### Update Role by Email
```http
PATCH /api/customers/email/:email/role
Content-Type: application/json

{
  "role": "ADMIN"
}
```

Valid roles: `CUSTOMER`, `ADMIN`

**Important:** Users must log in again after role changes to receive a new token with updated permissions.

## 🔐 JWT Token Structure

Tokens include the following claims:

```json
{
  "userId": 1,
  "email": "user@example.com",
  "role": "CUSTOMER",
  "iat": 1234567890,
  "exp": 1234567890
}
```

The `role` field is read from the database and included in every token. Other services should trust this role value when validating tokens.

## 🏗️ Architecture

- **Framework**: Express.js + TypeScript
- **Database**: PostgreSQL via Prisma ORM
- **Authentication**: JWT tokens
- **Password Hashing**: bcrypt
- **Validation**: Joi

## 🔗 Related Services

- **Backend**: [be/](../be/) - Product catalog and cart management
- **Order Service**: [order-service/](../order-service/) - Order processing
- **Frontend**: [fe/](../fe/) - Customer-facing web application
