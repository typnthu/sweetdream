# Fix: Deploy Workflow Not Triggering

## Problem Identified

The deploy workflow is not receiving triggers from CI because:

1. **Your default branch is `master`**
2. **The deploy.yml file on master is completely commented out**
3. **GitHub reads workflow_run triggers from the default branch only**

When you push to `dev`, GitHub looks at `master` branch for the deploy.yml file to see if it should trigger. Since it's commented out on master, the trigger never fires.

## Solution Options

### Option 1: Merge dev to master (Recommended)

This will make the active deploy.yml available on master:

```bash
# Make sure you're on dev and have latest changes
git checkout dev
git pull origin dev

# Merge to master
git checkout master
git pull origin master
git merge dev

# Push to master
git push origin master
```

After this, pushes to dev will trigger the deploy workflow.

### Option 2: Uncomment deploy.yml on master

If you don't want to merge everything, just uncomment deploy.yml on master:

```bash
# Checkout master
git checkout master
git pull origin master

# Edit .github/workflows/deploy.yml and uncomment it
# Or copy from dev:
git checkout dev -- .github/workflows/deploy.yml

# Commit and push
git add .github/workflows/deploy.yml
git commit -m "Enable deploy workflow on master"
git push origin master

# Go back to dev
git checkout dev
```

### Option 3: Use push trigger instead (Alternative)

If you can't modify master, change deploy.yml on dev to use push trigger:

```yaml
on:
  push:
    branches: [main, master, dev]
  workflow_dispatch:
    # ... existing inputs
```

This will make deploy run on every push (like CI), but you can add a condition to check if CI passed first.

## Why This Happens

GitHub Actions workflow_run trigger has this behavior:

- The workflow file with `workflow_run` trigger must exist on the **default branch**
- It doesn't matter which branch you push to
- GitHub always reads the workflow file from default branch to decide if it should trigger
- This is a security feature to prevent malicious workflow triggers from feature branches

## Verification

After applying the fix, test it:

1. Make a small change on dev branch
2. Push to dev
3. Check GitHub Actions:
   - CI should run immediately
   - Deploy should start after CI completes
   - You should see "triggered by workflow_run" in deploy workflow

## Current Status

- Default branch: `master`
- deploy.yml on master: **COMMENTED OUT** (entire file is `# ...`)
- deploy.yml on dev: **ACTIVE** (with workflow_run trigger)
- Result: workflow_run trigger **CANNOT WORK** until deploy.yml is active on master

## Recommended Action

**Merge dev to master** to sync the workflows. This ensures:
- workflow_run trigger works for all branches
- Both branches have the same workflow configuration
- Future changes are consistent
