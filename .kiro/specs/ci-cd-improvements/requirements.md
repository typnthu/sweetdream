# Requirements Document

## Introduction

Cải thiện CI/CD pipeline cho SweetDream E-commerce Platform. Hiện tại, CI workflow (ci.yml) và Deploy workflow (deploy.yml) hoạt động độc lập, không có sự liên kết. Yêu cầu là CI phải chạy thành công trước khi Deploy được phép chạy. Đồng thời, cần triển khai thêm môi trường Production bên cạnh môi trường Development hiện có.

## Glossary

- **CI (Continuous Integration)**: Quy trình tự động build, test và validate code khi có thay đổi
- **CD (Continuous Deployment)**: Quy trình tự động deploy code lên môi trường sau khi CI thành công
- **GitHub Actions**: Nền tảng CI/CD của GitHub để tự động hóa workflows
- **Workflow**: Một quy trình tự động được định nghĩa trong file YAML
- **ECS (Elastic Container Service)**: Dịch vụ AWS để chạy containers
- **ECR (Elastic Container Registry)**: Dịch vụ AWS để lưu trữ Docker images
- **Terraform**: Công cụ Infrastructure as Code để quản lý hạ tầng AWS
- **Environment**: Môi trường triển khai (development, production)

## Requirements

### Requirement 1

**User Story:** As a DevOps engineer, I want CI to run before deployment, so that only validated code gets deployed to any environment.

#### Acceptance Criteria

1. WHEN code is pushed to main or dev branch THEN the CI workflow SHALL run first to validate the code
2. WHEN CI workflow completes successfully THEN the Deploy workflow SHALL be triggered automatically
3. WHEN CI workflow fails THEN the Deploy workflow SHALL NOT be triggered
4. WHEN a pull request is created THEN the CI workflow SHALL run but Deploy workflow SHALL NOT be triggered

### Requirement 2

**User Story:** As a DevOps engineer, I want separate deployment pipelines for dev and prod environments, so that I can safely deploy to production with proper controls.

#### Acceptance Criteria

1. WHEN code is pushed to dev branch THEN the system SHALL deploy to development environment only
2. WHEN code is pushed to main branch THEN the system SHALL deploy to production environment only
3. WHEN deploying to production THEN the system SHALL require manual approval before deployment starts
4. WHEN deploying to any environment THEN the system SHALL use environment-specific configurations (cluster name, region, secrets)

### Requirement 3

**User Story:** As a DevOps engineer, I want the workflows to be consolidated into a single file, so that the CI-CD dependency is clear and maintainable.

#### Acceptance Criteria

1. WHEN the unified workflow runs THEN the system SHALL execute CI jobs first (build, test, lint)
2. WHEN CI jobs complete THEN the system SHALL execute Deploy jobs with explicit dependency on CI success
3. WHEN viewing the workflow THEN the system SHALL display clear job dependencies in the GitHub Actions UI
4. WHEN a service has no changes THEN the system SHALL skip both CI and Deploy for that service

### Requirement 4

**User Story:** As a DevOps engineer, I want environment-specific GitHub configurations, so that each environment has its own secrets and variables.

#### Acceptance Criteria

1. WHEN deploying to development THEN the system SHALL use development GitHub environment secrets
2. WHEN deploying to production THEN the system SHALL use production GitHub environment secrets
3. WHEN configuring environments THEN the system SHALL document required secrets and variables for each environment
4. WHEN production deployment is triggered THEN the system SHALL enforce environment protection rules

### Requirement 5

**User Story:** As a DevOps engineer, I want the Terraform configurations to work with the new CI/CD pipeline, so that infrastructure is properly managed for both environments.

#### Acceptance Criteria

1. WHEN deploying to development THEN the system SHALL use terraform/environments/dev configuration
2. WHEN deploying to production THEN the system SHALL use terraform/environments/prod configuration
3. WHEN Terraform files change THEN the system SHALL apply infrastructure changes before deploying services
4. WHEN deploying services THEN the system SHALL use correct ECR repositories and ECS clusters for each environment
