# GitHub Actions Workflows

## Overview

This project uses three main workflows:

1. **pr-checks.yml** - Fast validation on Pull Requests
2. **ci.yml** - Full CI pipeline on branch pushes
3. **deploy.yml** - Deployment to AWS (triggered after CI completes)

## Workflow Triggers

### PR Checks (pr-checks.yml)
- Triggers: Pull request creation/updates
- Purpose: Fast feedback for PRs
- Runs: Lint, type check, basic validation

### CI (ci.yml)
- Triggers: Push to main, master, or dev branches
- Purpose: Full build and test
- Runs: Build, test, security audit for all services

### Deploy (deploy.yml)
- Triggers: 
  - Automatically after CI completes successfully (workflow_run)
  - Manually via workflow_dispatch
- Purpose: Deploy to AWS infrastructure

## Important: workflow_run Trigger Limitation

The `workflow_run` trigger has a critical limitation:

**It only works when the workflow file exists on the default branch (main/master)**

### What this means:

1. If you push to `dev` branch, the deploy workflow will only trigger if `deploy.yml` exists on your default branch
2. The workflow_run trigger reads the workflow file from the default branch, not from the branch being pushed
3. Changes to `deploy.yml` on feature branches won't affect the trigger until merged to default branch

### Solutions:

#### Option 1: Ensure deploy.yml is on default branch (Recommended)
```bash
# Make sure deploy.yml is merged to main/master
git checkout main
git pull
# Verify deploy.yml exists
ls .github/workflows/deploy.yml
```

#### Option 2: Use manual deployment for feature branches
```bash
# Go to GitHub Actions tab
# Select "Deploy to AWS" workflow
# Click "Run workflow"
# Choose your branch and environment
```

#### Option 3: Alternative trigger (if workflow_run doesn't work)
If workflow_run continues to fail, you can modify deploy.yml to use push trigger with a condition:

```yaml
on:
  push:
    branches: [main, master, dev]
  workflow_dispatch:
    # ... existing inputs

jobs:
  # Add a job that waits for CI
  wait-for-ci:
    runs-on: ubuntu-latest
    steps:
      - name: Wait for CI
        uses: lewagon/wait-on-check-action@v1.3.1
        with:
          ref: ${{ github.sha }}
          check-name: 'CI Summary'
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

## Testing the Workflow

To test if workflow_run is working:

1. Make a small change to any service
2. Push to dev/main branch
3. Check GitHub Actions tab:
   - CI workflow should start immediately
   - Deploy workflow should start after CI completes
   - Look for "triggered by workflow_run" in deploy workflow

## Debugging

If deploy workflow doesn't trigger:

1. Check if deploy.yml exists on default branch
2. Verify workflow name matches exactly: "CI" (case-sensitive)
3. Check CI workflow completed successfully (not failed/cancelled)
4. Look at deploy workflow's debug output in check-ci job
5. Use manual trigger as fallback

## Current Configuration

- **CI runs on**: Push to main, master, dev
- **Deploy runs on**: After CI completes (workflow_run) + manual trigger
- **PR Checks run on**: Pull request events
- **No duplicate runs**: PR trigger removed from CI to prevent double runs
