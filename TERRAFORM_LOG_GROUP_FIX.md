# 🔧 Terraform Log Group & RDS Username Fix

## Issues Fixed

### 1. ❌ CloudWatch Log Group Conflict
**Problem:** All 4 ECS services were trying to create the same log group `/ecs/sweetdream`

**Error:**
```
Error: creating CloudWatch Logs Log Group (/ecs/sweetdream): 
ResourceAlreadyExistsException: The specified log group already exists
```

**Root Cause:** 
The ECS module was hardcoded to use `/ecs/sweetdream` for all services, causing conflicts when multiple services tried to create it.

**Solution:**
Changed log group name to be unique per service:
```terraform
# Before (modules/ecs/main.tf)
name = "/ecs/sweetdream"

# After
name = "/ecs/sweetdream-${var.service_name}"
```

**Result:**
Now each service gets its own log group:
- `/ecs/sweetdream-sweetdream-backend`
- `/ecs/sweetdream-sweetdream-frontend`
- `/ecs/sweetdream-sweetdream-user-service`
- `/ecs/sweetdream-sweetdream-order-service`

---

### 2. ❌ RDS Reserved Username
**Problem:** Using "admin" as database username, which is reserved in RDS PostgreSQL

**Error:**
```
Error: creating RDS DB Instance (sweetdream-db): 
InvalidParameterValue: MasterUsername admin cannot be used as it is a reserved word
```

**Reserved Usernames in RDS PostgreSQL:**
- `admin`
- `rdsadmin`
- `rds_superuser`
- `postgres` (sometimes, but generally safe)

**Solution:**
Changed default username from "admin" to "postgres":
```terraform
# variables.tf
variable "db_username" {
  description = "Database username"
  default     = "postgres"  # Changed from "admin"
  sensitive   = true
}
```

---

## Files Changed

### 1. `terraform/modules/ecs/main.tf`
```diff
resource "aws_cloudwatch_log_group" "app" {
-  name              = "/ecs/sweetdream"
+  name              = "/ecs/sweetdream-${var.service_name}"
   retention_in_days = 7

   tags = {
-    Name = "SweetDream ECS Logs"
+    Name = "SweetDream ECS Logs - ${var.service_name}"
   }
}
```

### 2. `terraform/variables.tf`
```diff
variable "db_username" {
   description = "Database username"
-  default     = "admin"
+  default     = "postgres"
   sensitive   = true
}
```

---

## CloudWatch Log Groups Created

After this fix, you'll have 4 separate log groups:

| Service | Log Group Name | Port |
|---------|---------------|------|
| Backend | `/ecs/sweetdream-sweetdream-backend` | 3001 |
| Frontend | `/ecs/sweetdream-sweetdream-frontend` | 3000 |
| User Service | `/ecs/sweetdream-sweetdream-user-service` | 3001 |
| Order Service | `/ecs/sweetdream-sweetdream-order-service` | 3002 |

---

## Database Connection Strings

All services will now connect using:
```
postgresql://postgres:YourPassword@sweetdream-db.xxx.us-east-1.rds.amazonaws.com/sweetdream
```

**Environment Variables:**
```bash
DB_USER=postgres
DB_PASSWORD=YourSecurePassword
DB_HOST=sweetdream-db.xxx.us-east-1.rds.amazonaws.com
DB_NAME=sweetdream
```

---

## Deployment Steps

### 1. Clean Up Existing Resources (if needed)
If you have existing log groups or RDS instance, you may need to:

```powershell
# Delete existing log groups (if any)
aws logs delete-log-group --log-group-name /ecs/sweetdream

# Or import existing resources
terraform import module.ecs_backend.aws_cloudwatch_log_group.app /ecs/sweetdream-sweetdream-backend
```

### 2. Apply Terraform
```powershell
cd terraform
terraform plan -var="db_password=YourSecurePassword123!"
terraform apply -var="db_password=YourSecurePassword123!"
```

### 3. Verify Log Groups
```powershell
# List all log groups
aws logs describe-log-groups --log-group-name-prefix /ecs/sweetdream

# Should show 4 log groups
```

---

## Why This Happens

**Terraform State vs AWS Reality:**
- Terraform tracks resources in state file
- If state is lost/reset, Terraform doesn't know resources exist
- When you run `terraform apply`, it tries to create them again
- AWS rejects because resources already exist

**Prevention:**
1. Always use remote state (S3 backend) ✅ (Already configured)
2. Use unique names for resources ✅ (Fixed in this commit)
3. Use `terraform import` for existing resources
4. Add lifecycle rules to prevent conflicts

---

## Testing

After applying, verify each service can write logs:

```powershell
# Check backend logs
aws logs tail /ecs/sweetdream-sweetdream-backend --follow

# Check frontend logs
aws logs tail /ecs/sweetdream-sweetdream-frontend --follow

# Check user service logs
aws logs tail /ecs/sweetdream-sweetdream-user-service --follow

# Check order service logs
aws logs tail /ecs/sweetdream-sweetdream-order-service --follow
```

---

## Summary

✅ **Fixed:** Unique log group names per service  
✅ **Fixed:** Changed DB username from "admin" to "postgres"  
✅ **Result:** Terraform can now create all 4 services without conflicts  

**Ready to deploy!** 🚀
