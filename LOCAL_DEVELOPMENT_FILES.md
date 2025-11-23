# 🔧 Local Development Files Explained

## Overview

These 4 files help you run the application locally on your computer for development and testing.

---

## 1. `docker-compose.dev.yml` 🐳

**Purpose:** Runs ONLY the PostgreSQL database in Docker

**What it does:**
- Starts PostgreSQL 15 in a Docker container
- Creates database named `sweetdream`
- Username: `dev`, Password: `dev123`
- Exposes port `5432` (standard PostgreSQL port)
- Stores data in a Docker volume (persists between restarts)

**When to use:**
- When you want to run services manually (recommended for development)
- When you need just the database

**How to use:**
```powershell
# Start database
docker-compose -f docker-compose.dev.yml up -d

# Stop database
docker-compose -f docker-compose.dev.yml down

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Remove database and data
docker-compose -f docker-compose.dev.yml down -v
```

**Advantages:**
- ✅ Fast startup
- ✅ Easy to debug services (run in separate terminals)
- ✅ Can restart individual services
- ✅ See logs clearly for each service

---

## 2. `docker-compose.microservices.yml` 🐳🐳🐳🐳

**Purpose:** Runs ALL services (database + 4 services) in Docker

**What it does:**
- Starts PostgreSQL database
- Starts User Service (port 3001)
- Starts Order Service (port 3002)
- Starts Backend Service (port 3003)
- Starts Frontend (port 3000)
- Connects them all in a Docker network
- Automatically runs migrations and seeds data

**When to use:**
- When you want everything running with one command
- When testing the complete system
- When you don't need to debug individual services

**How to use:**
```powershell
# Start all services
docker-compose -f docker-compose.microservices.yml up -d

# View logs
docker-compose -f docker-compose.microservices.yml logs -f

# Stop all services
docker-compose -f docker-compose.microservices.yml down

# Rebuild and restart
docker-compose -f docker-compose.microservices.yml up -d --build
```

**Advantages:**
- ✅ One command to start everything
- ✅ Consistent environment
- ✅ Good for testing full system

**Disadvantages:**
- ❌ Slower to start (builds Docker images)
- ❌ Harder to debug (logs mixed together)
- ❌ Need to rebuild after code changes

---

## 3. `start-all-services.ps1` 🚀

**Purpose:** Helper script to start services manually (recommended)

**What it does:**
1. Checks if database is running
2. Starts database if not running
3. Shows instructions to start each service in separate terminals

**When to use:**
- **Recommended for development**
- When you want to see each service's logs clearly
- When you need to restart individual services
- When debugging

**How to use:**
```powershell
# Run the script
.\start-all-services.ps1

# Then follow the instructions to open 4 terminals
```

**What you'll do:**
1. **Terminal 1:** Start User Service
2. **Terminal 2:** Start Order Service
3. **Terminal 3:** Start Backend Service
4. **Terminal 4:** Start Frontend

**Advantages:**
- ✅ Clear logs for each service
- ✅ Easy to restart individual services
- ✅ Fast code changes (no Docker rebuild)
- ✅ Easy to debug
- ✅ Can see errors immediately

---

## 4. `check-services.ps1` ✅

**Purpose:** Health check script to verify all services are running

**What it does:**
- Checks User Service (port 3001)
- Checks Order Service (port 3002)
- Checks Backend Service (port 3003)
- Checks Frontend (port 3000)
- Shows which services are running/not running

**When to use:**
- After starting services
- When troubleshooting
- To verify everything is working

**How to use:**
```powershell
# Run the health check
.\check-services.ps1
```

**Output example:**
```
========================================
Checking Microservices Status
========================================

User Service (3001)... [OK]
  Service: user-service

Order Service (3002)... [OK]
  Service: order-service

Backend Service (3003)... [OK]
  Status: OK

Frontend (3000)... [OK]

========================================
ALL SERVICES RUNNING!

Visit: http://localhost:3000
```

---

## Comparison: Which Method to Use?

### Method 1: Manual (Recommended) ⭐

**Use:** `docker-compose.dev.yml` + `start-all-services.ps1`

```powershell
# 1. Start database
docker-compose -f docker-compose.dev.yml up -d

# 2. Follow instructions from script
.\start-all-services.ps1

# 3. Open 4 terminals and start each service
```

**Best for:**
- ✅ Daily development
- ✅ Debugging
- ✅ Learning the system
- ✅ Making code changes

**Pros:**
- Fast code changes (no rebuild)
- Clear logs
- Easy to restart services
- Can debug with breakpoints

**Cons:**
- Need to open multiple terminals
- Manual setup

---

### Method 2: Docker Compose All

**Use:** `docker-compose.microservices.yml`

```powershell
# Start everything
docker-compose -f docker-compose.microservices.yml up -d
```

**Best for:**
- ✅ Quick testing
- ✅ Demos
- ✅ CI/CD testing
- ✅ When you don't need to change code

**Pros:**
- One command
- Consistent environment
- Good for testing

**Cons:**
- Slow to rebuild
- Mixed logs
- Harder to debug

---

## Recommended Workflow

### For Development (Daily Work)

```powershell
# Day 1: Setup
docker-compose -f docker-compose.dev.yml up -d
.\start-all-services.ps1
# Follow instructions to start services

# Day 2+: Just start services
# Database is already running
# Open 4 terminals and start services

# Check if everything is running
.\check-services.ps1
```

### For Testing Complete System

```powershell
# Start everything
docker-compose -f docker-compose.microservices.yml up -d

# Check status
.\check-services.ps1

# View logs
docker-compose -f docker-compose.microservices.yml logs -f

# Stop when done
docker-compose -f docker-compose.microservices.yml down
```

---

## Port Reference

| Service | Port | URL |
|---------|------|-----|
| Frontend | 3000 | http://localhost:3000 |
| User Service | 3001 | http://localhost:3001 |
| Order Service | 3002 | http://localhost:3002 |
| Backend Service | 3003 | http://localhost:3003 |
| PostgreSQL | 5432 | localhost:5432 |

---

## Database Connection

**Connection String:**
```
postgresql://dev:dev123@localhost:5432/sweetdream
```

**Details:**
- Host: `localhost`
- Port: `5432`
- Database: `sweetdream`
- Username: `dev`
- Password: `dev123`

---

## Common Commands

### Database

```powershell
# Start database only
docker-compose -f docker-compose.dev.yml up -d

# Stop database
docker-compose -f docker-compose.dev.yml down

# Reset database (delete all data)
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d

# View database logs
docker-compose -f docker-compose.dev.yml logs -f postgres
```

### All Services (Docker)

```powershell
# Start all
docker-compose -f docker-compose.microservices.yml up -d

# Stop all
docker-compose -f docker-compose.microservices.yml down

# Rebuild and start
docker-compose -f docker-compose.microservices.yml up -d --build

# View logs
docker-compose -f docker-compose.microservices.yml logs -f

# View specific service logs
docker-compose -f docker-compose.microservices.yml logs -f frontend
```

### Health Checks

```powershell
# Check all services
.\check-services.ps1

# Check individual services
curl http://localhost:3001/health  # User Service
curl http://localhost:3002/health  # Order Service
curl http://localhost:3003/health  # Backend Service
curl http://localhost:3000         # Frontend
```

---

## Troubleshooting

### Database won't start

```powershell
# Check if port 5432 is in use
netstat -ano | findstr :5432

# Stop existing database
docker-compose -f docker-compose.dev.yml down

# Remove volumes and restart
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d
```

### Service won't start

```powershell
# Check if port is in use
netstat -ano | findstr :3001  # Replace with your port

# Kill process using port
taskkill /PID <process-id> /F

# Restart service
```

### Docker Compose not working

```powershell
# Check Docker is running
docker ps

# Restart Docker Desktop

# Rebuild images
docker-compose -f docker-compose.microservices.yml build --no-cache
```

---

## Summary

| File | Purpose | When to Use |
|------|---------|-------------|
| `docker-compose.dev.yml` | Database only | Development (recommended) |
| `docker-compose.microservices.yml` | All services | Quick testing |
| `start-all-services.ps1` | Start helper | Development setup |
| `check-services.ps1` | Health check | Verify services |

**Recommended for development:**
1. Use `docker-compose.dev.yml` for database
2. Use `start-all-services.ps1` for instructions
3. Run services manually in separate terminals
4. Use `check-services.ps1` to verify

**Quick testing:**
1. Use `docker-compose.microservices.yml`
2. One command to start everything

---

**Questions?** Check `GETTING_STARTED.md` for complete setup guide!
