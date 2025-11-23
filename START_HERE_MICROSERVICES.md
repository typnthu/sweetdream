# Start Microservices - Simple Guide

## Current Status
✅ Database is running!

## 3 Terminals Needed

### Terminal 1: User Service

```powershell
cd user-service
$env:DATABASE_URL="postgresql://dev:dev123@localhost:5432/sweetdream"
$env:PORT="3001"
$env:JWT_SECRET="local-dev-secret-key"
npm install
npx prisma generate
npx prisma db push --accept-data-loss
npm run dev
```

**Wait for:** `User Service running on port 3001`

---

### Terminal 2: Order Service

```powershell
cd order-service
$env:DATABASE_URL="postgresql://dev:dev123@localhost:5432/sweetdream"
$env:PORT="3002"
$env:USER_SERVICE_URL="http://localhost:3001"
npm install
npx prisma generate
npm run dev
```

**Wait for:** `Order Service running on port 3002`

---

### Terminal 3: Test

```powershell
.\test-microservices-now.ps1
```

**You should see:**
```
[OK] User Service is running on port 3001
[OK] Order Service is running on port 3002
SUCCESS! Order Created

Service Communication:
  Customer verified/created via User Service
  Order created in Order Service

MICROSERVICES COMMUNICATION VERIFIED!
```

---

## What This Proves

✅ **Two Services:**
1. User Service (registration/authentication)
2. Order Service (purchase processing)

✅ **Service Communication:**
- Order Service calls User Service via HTTP
- You can see it in the Order Service terminal logs

✅ **Meets Rubric Requirements!**

---

## Troubleshooting

### Database not running?
```powershell
docker-compose -f docker-compose.dev.yml up -d
# Wait 10 seconds
```

### Port already in use?
```powershell
Get-Process -Name node | Stop-Process -Force
```

### Can't reach database?
Make sure you're using `localhost:5432` not `postgres:5432`

---

## Quick Test (Manual)

```powershell
# Test services
curl http://localhost:3001/health
curl http://localhost:3002/health

# Create order
curl -X POST http://localhost:3002/api/orders -H "Content-Type: application/json" -d '{\"customer\":{\"name\":\"Test\",\"email\":\"test@test.com\"},\"items\":[{\"productId\":1,\"size\":\"12cm\",\"price\":90000,\"quantity\":1}]}'
```

---

## Success!

When you see the Order Service logs showing:
```
Calling User Service: http://localhost:3001/api/customers/email/...
Customer created in User Service
Order created successfully
```

**You've successfully demonstrated microservices communication!** 🎉
