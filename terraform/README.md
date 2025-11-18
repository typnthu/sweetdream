# SweetDream Infrastructure - Terraform

This Terraform configuration deploys the complete infrastructure for the SweetDream e-commerce application on AWS.

## Architecture

The infrastructure includes:

- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **ALB**: Application Load Balancer for distributing traffic
- **ECS Fargate**: Container orchestration for running the application
- **RDS PostgreSQL**: Managed database for storing products and orders
- **S3**: Storage for logs and user interaction data
- **Auto Scaling**: Automatic scaling based on CPU and memory utilization
- **CloudWatch**: Monitoring and logging
- **IAM**: Roles and policies for secure access

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.2
- AWS account with necessary permissions

## Quick Start

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your values:**
   - Set a strong `db_password`
   - Update `s3_bucket_name` to be globally unique
   - Update `container_image` with your application image

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Get the application URL:**
   ```bash
   terraform output alb_url
   ```

## Modules

- **vpc**: Network infrastructure with public/private subnets, NAT gateway, security groups
- **iam**: IAM roles and policies for ECS tasks
- **s3**: S3 bucket for logs and data storage
- **alb**: Application Load Balancer and target groups
- **rds**: PostgreSQL database instance
- **ecs**: ECS cluster, task definitions, services, and auto-scaling

## Outputs

After deployment, you can access:

- `alb_url`: The URL to access your application
- `ecs_cluster_name`: Name of the ECS cluster
- `s3_bucket_name`: Name of the S3 bucket for logs

## Security Features

- Private subnets for ECS and RDS
- Security groups with least privilege access
- Encrypted RDS storage
- S3 bucket encryption and versioning
- IAM roles with minimal required permissions

## Auto Scaling

The ECS service automatically scales between 2-10 tasks based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)

## Cost Optimization

- NAT Gateway: ~$32/month
- RDS db.t3.micro: ~$15/month
- ECS Fargate: Pay per task (varies)
- ALB: ~$16/month + data transfer
- S3: Pay per usage

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete all data including the database and S3 bucket contents.
