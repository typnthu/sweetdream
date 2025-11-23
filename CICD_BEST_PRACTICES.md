# CI/CD Best Practices for Terraform

## Your Current Setup

You have **two separate workflows**:

### 1. `infrastructure.yml` 
- Triggers: When `terraform/**` files change
- Action: Deploys infrastructure only
- Manual control via `workflow_dispatch`

### 2. `deploy.yml`
- Triggers: Every push to `dev`/`main`
- Action: Deploys application code only
- Assumes infrastructure exists

## Is This Best Practice? ✅ YES!

Your current setup follows **industry best practices** for production environments.

---

## Three Common Approaches

### Approach 1: Separate Workflows (Your Current Setup) ⭐

**When to use:**
- ✅ Production environments
- ✅ Mature projects
- ✅ Multiple environments (dev, staging, prod)
- ✅ When infrastructure changes are infrequent

**Pros:**
- ✅ Infrastructure changes are deliberate and controlled
- ✅ Prevents accidental infrastructure destruction
- ✅ Faster application deployments (no Terraform overhead)
- ✅ Clear separation of concerns
- ✅ Easier to review infrastructure changes
- ✅ Can require manual approval for infrastructure

**Cons:**
- ⚠️ Two-step process for initial deployment
- ⚠️ Need to remember to run infrastructure workflow first

**Workflow:**
```
1. First deployment:
   - Run infrastructure.yml (manual or on terraform/** changes)
   - Run deploy.yml (automatic on code push)

2. Subsequent deployments:
   - deploy.yml runs automatically
   - infrastructure.yml only runs when terraform files change
```

---

### Approach 2: Integrated Workflow

**When to use:**
- Development environments
- New projects
- Rapid prototyping
- Single developer

**Pros:**
- ✅ Single command deployment
- ✅ Infrastructure and app always in sync
- ✅ Simpler for beginners

**Cons:**
- ❌ Slower deployments (Terraform runs every time)
- ❌ Risk of accidental infrastructure changes
- ❌ Harder to review changes
- ❌ More expensive (more CI/CD minutes)

**Workflow:**
```
Every push:
1. Run Terraform (even if no changes)
2. Build Docker images
3. Deploy to ECS
```

---

### Approach 3: Hybrid with Smart Detection (New Option) ⭐⭐

**When to use:**
- ✅ Best of both worlds
- ✅ Production with frequent infrastructure updates
- ✅ Teams that want automation + safety

**Pros:**
- ✅ Automatic infrastructure deployment when needed
- ✅ Fast deployments when no infrastructure changes
- ✅ Single workflow to maintain
- ✅ Smart detection of changes

**Cons:**
- ⚠️ Slightly more complex workflow
- ⚠️ Need good git practices

**Workflow:**
```
Every push:
1. Check if infrastructure exists
2. Check if terraform files changed
3. If yes → Deploy infrastructure
4. If no → Skip to application deployment
5. Build and deploy application
```

I've created this for you: `.github/workflows/deploy-with-infra-check.yml`

---

## Recommendation for Your Project

### For Initial Deployment: Use Current Setup ✅

**Step 1: Deploy Infrastructure (One Time)**
```bash
# Option A: Manual deployment
cd terraform
terraform init
terraform apply -var-file="environments/dev.tfvars"

# Option B: Use GitHub Actions
# Go to Actions → Infrastructure Deployment → Run workflow
```

**Step 2: Deploy Application (Automatic)**
```bash
# Just push to dev branch
git push origin dev

# GitHub Actions automatically:
# - Builds Docker images
# - Pushes to ECR
# - Updates ECS services
```

### For Production: Keep Separate Workflows ⭐

**Why?**
1. **Safety**: Infrastructure changes require review
2. **Speed**: Application deployments are fast
3. **Control**: Manual approval for infrastructure
4. **Cost**: Don't run Terraform unnecessarily

### For Development: Consider Hybrid Approach

If you want automatic infrastructure updates in dev:
1. Rename `deploy.yml` to `deploy-app-only.yml`
2. Use `deploy-with-infra-check.yml` as main workflow
3. Keep `infrastructure.yml` for manual control

---

## Industry Best Practices

### 1. Separate Terraform State by Environment

```
terraform/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── backend/
    ├── dev.tf
    ├── staging.tf
    └── prod.tf
```

### 2. Use Terraform Remote State

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "sweetdream-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Require Manual Approval for Production

```yaml
# .github/workflows/infrastructure.yml
deploy-infrastructure:
  environment: 
    name: production
    # Requires manual approval in GitHub
```

### 4. Use Terraform Plan in PRs

```yaml
# Show plan in PR comments
- name: Terraform Plan
  if: github.event_name == 'pull_request'
  run: terraform plan -no-color
```

### 5. Separate Application and Infrastructure Repos

**Large organizations:**
```
sweetdream-app/          # Application code
sweetdream-infrastructure/  # Terraform only
```

**Your project:** Single repo is fine ✅

---

## Comparison Table

| Feature | Separate Workflows | Integrated | Hybrid |
|---------|-------------------|------------|--------|
| **Speed** | ⭐⭐⭐ Fast | ⭐ Slow | ⭐⭐⭐ Fast |
| **Safety** | ⭐⭐⭐ Safe | ⭐ Risky | ⭐⭐ Safe |
| **Simplicity** | ⭐⭐ Medium | ⭐⭐⭐ Simple | ⭐ Complex |
| **Control** | ⭐⭐⭐ High | ⭐ Low | ⭐⭐ Medium |
| **Cost** | ⭐⭐⭐ Low | ⭐ High | ⭐⭐ Low |
| **Best for** | Production | Dev/Prototype | Both |

---

## Your Current Workflow Explained

### Initial Deployment

```bash
# 1. Deploy infrastructure (one time)
# Go to: Actions → Infrastructure Deployment → Run workflow
# Or: cd terraform && terraform apply

# 2. Push application code
git push origin dev

# 3. GitHub Actions automatically:
#    - Builds Docker images
#    - Pushes to ECR
#    - Updates ECS services
#    - Runs migrations
```

### Daily Development

```bash
# Just push code changes
git add .
git commit -m "Add new feature"
git push origin dev

# GitHub Actions automatically deploys
# Infrastructure workflow doesn't run (no terraform changes)
```

### Infrastructure Updates

```bash
# 1. Update terraform files
vim terraform/main.tf

# 2. Commit and push
git add terraform/
git commit -m "Update infrastructure"
git push origin dev

# 3. Infrastructure workflow automatically runs
#    (triggered by terraform/** path changes)

# 4. Application workflow also runs
#    (triggered by push to dev)
```

---

## Recommendations

### ✅ Keep Your Current Setup If:
- You're deploying to production
- Infrastructure changes are infrequent
- You want manual control over infrastructure
- You want fast application deployments

### 🔄 Switch to Hybrid If:
- You're in active development
- Infrastructure changes frequently
- You want full automation
- You trust your team's git practices

### 📝 Add These Improvements:

1. **Remote State Backend**
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://sweetdream-terraform-state
aws s3api put-bucket-versioning \
  --bucket sweetdream-terraform-state \
  --versioning-configuration Status=Enabled
```

2. **Manual Approval for Production**
```yaml
# In infrastructure.yml
environment: 
  name: production
  # Add protection rules in GitHub Settings
```

3. **Terraform Plan in PRs**
```yaml
# Already in your infrastructure.yml ✅
- name: Update Pull Request
  uses: actions/github-script@v7
```

4. **Cost Estimation**
```yaml
# Add Infracost to see cost changes
- name: Run Infracost
  uses: infracost/actions/setup@v2
```

---

## Summary

**Your current setup is EXCELLENT for production! ✅**

You have:
- ✅ Separate infrastructure and application workflows
- ✅ Automatic application deployments
- ✅ Controlled infrastructure changes
- ✅ Fast CI/CD pipeline
- ✅ Clear separation of concerns

**Optional improvements:**
- Add remote state backend (S3 + DynamoDB)
- Add manual approval for production
- Consider hybrid workflow for development environment

**Don't change unless:**
- You need faster infrastructure iteration
- You want single-command deployment
- You're okay with slightly more complexity

---

## Quick Decision Guide

**Q: Is this my first deployment?**
- Use: Manual Terraform + Automatic App Deployment

**Q: Do I change infrastructure often?**
- Yes → Consider Hybrid workflow
- No → Keep separate workflows ✅

**Q: Is this production?**
- Yes → Keep separate workflows ✅
- No → Either approach works

**Q: Do I want maximum safety?**
- Yes → Keep separate workflows ✅

**Q: Do I want maximum speed?**
- Yes → Use Hybrid workflow

---

## Files in Your Project

1. **`.github/workflows/infrastructure.yml`** (Current)
   - Deploys infrastructure only
   - Triggered by terraform/** changes
   - Manual workflow_dispatch option

2. **`.github/workflows/deploy.yml`** (Current)
   - Deploys application only
   - Triggered by every push
   - Assumes infrastructure exists

3. **`.github/workflows/deploy-with-infra-check.yml`** (New Option)
   - Smart detection of infrastructure changes
   - Deploys both if needed
   - Single workflow

**Choose one approach and disable the others!**

---

## Next Steps

### Option A: Keep Current Setup (Recommended) ✅
```bash
# No changes needed!
# Just deploy infrastructure first, then push code
```

### Option B: Switch to Hybrid
```bash
# 1. Disable old workflows
mv .github/workflows/deploy.yml .github/workflows/deploy.yml.disabled
mv .github/workflows/infrastructure.yml .github/workflows/infrastructure.yml.disabled

# 2. Rename new workflow
mv .github/workflows/deploy-with-infra-check.yml .github/workflows/deploy.yml

# 3. Push and test
git add .
git commit -m "Switch to hybrid CI/CD"
git push origin dev
```

---

**Bottom line:** Your current setup follows best practices. The separate workflows are intentional and correct for production environments! 🎉
