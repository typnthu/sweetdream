# GitHub Actions Workflows Explained

## Current Workflows (11 files)

### ✅ KEEP - Essential Workflows

#### 1. `deploy-hybrid.yml` ⭐ **RECOMMENDED**
**Purpose:** Hybrid deployment - deploys application code only  
**Triggers:** Push to dev/main, changes in code directories  
**What it does:**
- Checks if infrastructure exists
- Builds Docker images for all 4 services
- Pushes to ECR
- Updates ECS services
- Fast deployments (5-10 min)

**Keep because:** This is your main deployment workflow for the hybrid approach

---

#### 2. `backend-ci.yml` ✅
**Purpose:** Test backend code  
**Triggers:** Push/PR to dev/main with backend changes  
**What it does:**
- Runs tests
- Builds TypeScript
- Runs migrations
- Security scan

**Keep because:** Ensures backend code quality before deployment

---

#### 3. `frontend-ci.yml` ✅
**Purpose:** Test frontend code  
**Triggers:** Push/PR to dev/main with frontend changes  
**What it does:**
- Runs linter
- Builds Next.js
- Runs tests
- Security scan

**Keep because:** Ensures frontend code quality before deployment

---

#### 4. `pr-checks.yml` ✅
**Purpose:** Comprehensive PR validation  
**Triggers:** Pull requests  
**What it does:**
- Lint & format check
- Security scan with Trivy
- Build verification
- PR summary

**Keep because:** Prevents bad code from being merged

---

### ❌ DELETE - Redundant/Unused Workflows

#### 5. `deploy.yml` ❌ **DELETE**
**Purpose:** Old deployment workflow (only backend/frontend)  
**Why delete:** 
- Doesn't include microservices (order-service, user-service)
- Replaced by `deploy-hybrid.yml`
- Causes confusion with multiple deploy workflows

---

#### 6. `deploy-with-infra-check.yml` ❌ **DELETE**
**Purpose:** Deploy with automatic infrastructure deployment  
**Why delete:**
- Conflicts with hybrid approach (infrastructure should be manual)
- Too complex
- Can accidentally deploy infrastructure changes
- Replaced by `deploy-hybrid.yml`

---

#### 7. `infrastructure.yml` ❌ **DELETE**
**Purpose:** Auto-deploy Terraform infrastructure  
**Why delete:**
- Conflicts with hybrid approach
- Infrastructure should be deployed manually locally
- Risk of accidental infrastructure changes
- Can cause state file conflicts

---

#### 8. `database-migration.yml` ⚠️ **OPTIONAL**
**Purpose:** Manual database migrations via GitHub Actions  
**Keep if:** You want to run migrations from GitHub UI  
**Delete if:** You prefer running migrations via admin panel or locally

**Recommendation:** Keep for now, useful for manual migrations

---

#### 9. `integration-tests.yml` ⚠️ **OPTIONAL**
**Purpose:** Full integration tests (backend + frontend + database)  
**Keep if:** You want comprehensive testing  
**Delete if:** CI tests are sufficient

**Recommendation:** Keep if you have time to maintain tests, delete if not used

---

#### 10. `backend-ci-pg15.yml.example` ❌ **DELETE**
**Purpose:** Example file  
**Why delete:** It's just an example, not used

---

#### 11. `deploy-with-cache.yml.example` ❌ **DELETE**
**Purpose:** Example file  
**Why delete:** It's just an example, not used

---

## Recommended Configuration

### Keep These (5 workflows):
1. ✅ `deploy-hybrid.yml` - Main deployment
2. ✅ `backend-ci.yml` - Backend testing
3. ✅ `frontend-ci.yml` - Frontend testing
4. ✅ `pr-checks.yml` - PR validation
5. ✅ `database-migration.yml` - Manual migrations (optional)

### Delete These (6 workflows):
1. ❌ `deploy.yml`
2. ❌ `deploy-with-infra-check.yml`
3. ❌ `infrastructure.yml`
4. ❌ `integration-tests.yml` (unless you use it)
5. ❌ `backend-ci-pg15.yml.example`
6. ❌ `deploy-with-cache.yml.example`

---

## Workflow Triggers Summary

### Automatic (on push):
- `deploy-hybrid.yml` → Deploys application
- `backend-ci.yml` → Tests backend
- `frontend-ci.yml` → Tests frontend

### On Pull Request:
- `pr-checks.yml` → Validates PR
- `backend-ci.yml` → Tests backend changes
- `frontend-ci.yml` → Tests frontend changes

### Manual Only:
- `database-migration.yml` → Run migrations manually

---

## Why So Many Workflows?

You have many workflows because:
1. **Multiple deployment strategies** - Old workflows not cleaned up
2. **Example files** - `.example` files should be deleted
3. **Overlapping functionality** - Multiple deploy workflows doing similar things
4. **Evolution** - Project evolved, old workflows remained

---

## After Cleanup

You'll have a clean, simple setup:

```
.github/workflows/
├── deploy-hybrid.yml          # Main deployment ⭐
├── backend-ci.yml             # Backend tests
├── frontend-ci.yml            # Frontend tests
├── pr-checks.yml              # PR validation
└── database-migration.yml     # Manual migrations (optional)
```

**Total:** 4-5 workflows (down from 11)

---

## How They Work Together

```
Developer pushes code to dev branch
         ↓
    [backend-ci.yml] Tests backend
    [frontend-ci.yml] Tests frontend
         ↓
    Both pass? ✅
         ↓
    [deploy-hybrid.yml] Deploys to AWS
         ↓
    Application updated! 🚀
```

**For Pull Requests:**
```
Developer creates PR
         ↓
    [pr-checks.yml] Validates everything
    [backend-ci.yml] Tests backend
    [frontend-ci.yml] Tests frontend
         ↓
    All pass? ✅
         ↓
    PR can be merged
```

---

## Cost Impact

**Current (11 workflows):**
- More GitHub Actions minutes used
- Confusing which workflow runs
- Potential conflicts

**After cleanup (5 workflows):**
- Less GitHub Actions minutes
- Clear workflow purposes
- No conflicts
- Still within free tier (2000 min/month)

---

## Migration Steps

See `CLEANUP_WORKFLOWS.md` for step-by-step instructions to delete unnecessary workflows.
