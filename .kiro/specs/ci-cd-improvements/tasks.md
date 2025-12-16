# Implementation Plan

## Tasks

- [x] 1. Create unified CI/CD workflow file
  - [x] 1.1 Create new `.github/workflows/ci-cd.yml` file with proper triggers
    - Define `on` triggers for push (main, dev) and pull_request
    - Set up environment variables (NODE_VERSION, TERRAFORM_VERSION)
    - Set up permissions (contents: read, id-token: write)
    - _Requirements: 1.1, 1.4_

  - [x] 1.2 Implement change detection job
    - Use `dorny/paths-filter@v3` action
    - Define filters for backend, frontend, order-service, user-service, terraform
    - Output changed services for downstream jobs
    - _Requirements: 3.4_

  - [x] 1.3 Implement CI jobs for each service
    - Create `ci-backend` job with PostgreSQL service container
    - Create `ci-frontend` job with build and lint
    - Create `ci-order-service` job with build
    - Create `ci-user-service` job with build
    - Create `ci-terraform` job with format check and validate
    - All CI jobs depend on `changes` job
    - _Requirements: 1.1, 3.1_

  - [x] 1.4 Implement environment selection logic
    - Create job to determine target environment based on branch
    - Output environment name (development/production) for deploy jobs
    - Output AWS region, ECS cluster name, Terraform directory
    - _Requirements: 2.1, 2.2, 2.4_

  - [x] 1.5 Implement infrastructure deployment job
    - Add `needs: [ci-backend, ci-frontend, ci-order-service, ci-user-service, ci-terraform]`
    - Use dynamic environment based on branch
    - Run Terraform init, plan, apply in correct environment directory
    - Only run when terraform files changed or force_deploy
    - _Requirements: 1.2, 1.3, 3.2, 5.1, 5.2, 5.3_

  - [x] 1.6 Implement service deployment jobs
    - Add `needs: [deploy-infrastructure]` dependency
    - Use matrix strategy for parallel service deployment
    - Build Docker images and push to ECR
    - Update ECS services with new images
    - Wait for services to stabilize
    - _Requirements: 1.2, 1.3, 3.2, 5.4_

  - [x] 1.7 Implement deployment summary job
    - Show deployment status for all services
    - Display application URL
    - Show which services were deployed
    - _Requirements: 3.3_

- [x] 2. Configure GitHub Environments
  - [x] 2.1 Document development environment setup
    - Create documentation for required secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DB_PASSWORD)
    - Document required variables (AWS_REGION, ECS_CLUSTER)
    - No protection rules needed
    - _Requirements: 4.1, 4.3_

  - [x] 2.2 Document production environment setup
    - Create documentation for required secrets
    - Document required variables
    - Document protection rules (required reviewers, deployment branches)
    - _Requirements: 2.3, 4.2, 4.3, 4.4_

- [x] 3. Cleanup old workflow files
  - [x] 3.1 Remove or archive old workflow files
    - Remove `.github/workflows/ci.yml` (content is commented out)
    - Remove `.github/workflows/deploy.yml` (content is commented out)
    - Keep `.github/workflows/pr-checks.yml` if still needed
    - _Requirements: 3.1_

- [x] 4. Update documentation
  - [x] 4.1 Update `.github/workflows/README.md`
    - Document new unified workflow
    - Update workflow diagram
    - Document environment setup steps
    - Document branch strategy
    - _Requirements: 4.3_

  - [x] 4.2 Update main README.md deployment section
    - Update CI/CD documentation
    - Add environment-specific deployment instructions
    - _Requirements: 4.3_

- [x] 5. Checkpoint - Verify workflow configuration
  - Ensure all tests pass, ask the user if questions arise.
