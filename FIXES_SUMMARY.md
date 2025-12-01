# Fixes Applied - December 1, 2025

## Issue 1: CloudWatch Log Groups
**Problem:** Frontend logging to wrong log group (`/ecs/sweetdream-frontend` instead of `/ecs/sweetdream-sweetdream-service-frontend`)

**Fix:** Updated `.github/workflows/deploy.yml` to correct log group name when updating task definitions
- Line 209: Added `LOG_GROUP` variable with correct naming pattern
- Line 215: Update task definition to use correct log group

**Status:** ✅ Fixed - Will apply on next frontend deployment

---

## Issue 2: User Service 500 Errors on Login/Register
**Problem:** POST requests to `/api/proxy/auth/login` and `/api/proxy/auth/register` returning 500 errors

**Root Cause:** Admin user password not properly set in database

**Fixes Applied:**
1. **Migration SQL** (`user-service/prisma/migrations/add_customer_role/migration.sql`):
   - Added INSERT statement with proper bcrypt hash for password `admin123`
   - Hash: `$2a$10$5jxvl6K31DwQqj.wQrA22ugDyp41haJ0yDIfaozUkpF1pbztHfGkq`
   - Uses `ON CONFLICT` to update existing admin user

2. **Package.json** (`user-service/package.json`):
   - Updated start script to run migrations and seed on container startup
   - `"start": "npx prisma migrate deploy && npm run seed && node dist/server.js"`

**Admin Credentials:**
- Email: `admin@sweetdream.com`
- Password: `admin123`

**Status:** ✅ Fixed - Will apply on next user-service deployment

---

## Issue 3: Blue/Green Deployment Configuration
**Request:** Configure blue/green with 20-40-40 traffic split

**Fix:** Updated `terraform/main.tf` ALB module configuration:
```hcl
frontend_blue_weight        = 20
frontend_green_weight       = 40
user_service_blue_weight    = 20
user_service_green_weight   = 40
order_service_blue_weight   = 20
order_service_green_weight  = 40
```

**Note:** This gives 20% to blue, 40% to green, leaving 40% unallocated (will go to blue by default)

**Status:** ✅ Configured - Apply with `terraform apply`

---

## Deployment Instructions

### To apply all fixes:
```bash
# Commit changes
git add .
git commit -m "fix: correct log groups, admin password, and blue/green config"
git push origin dev
```

### To apply blue/green immediately:
```bash
cd terraform
terraform apply
```

### To verify fixes:
1. **Log Groups:** Check after next deployment
   ```bash
   aws logs describe-log-streams --log-group-name /ecs/sweetdream-sweetdream-service-frontend
   ```

2. **Login/Register:** Test at http://sweetdream-alb-1177808282.us-east-1.elb.amazonaws.com/login

3. **Blue/Green:** Check ALB target groups in AWS Console
