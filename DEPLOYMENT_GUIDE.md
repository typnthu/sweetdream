# AWS Deployment Guide

## Current Status

✅ **AWS Infrastructure Created:**
- VPC with public/private subnets
- ECS Cluster: `sweetdream-cluster`
- RDS PostgreSQL Database
- Application Load Balancer
- S3 Buckets for logs and products
- ECR Repositories for Docker images

**Application URL:** http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com

## Next Steps to Deploy Your Application

### Step 1: Configure GitHub Secrets

1. Go to your GitHub repository settings:
   ```
   https://github.com/typnthu/sweetdream/settings/secrets/actions
   ```

2. Click "New repository secret" and add these secrets:

   **AWS_ACCESS_KEY_ID**
   - Value: Your AWS Access Key ID
   - Get it from: AWS Console → IAM → Users → Your User → Security Credentials

   **AWS_SECRET_ACCESS_KEY**
   - Value: Your AWS Secret Access Key
   - Get it from: Same place as above

   **DB_PASSWORD**
   - Value: `admin123!`
   - This is the database password from terraform.tfvars

   **BACKEND_API_URL**
   - Value: `http://backend.sweetdream.local:3001`
   - This is the internal service discovery URL

### Step 2: Create GitHub Environments

1. Go to:
   ```
   https://github.com/typnthu/sweetdream/settings/environments
   ```

2. Click "New environment" and create:
   - Name: `development`
   - Click "Configure environment"
   - No protection rules needed for dev
   - Save

3. Create another environment:
   - Name: `production`
   - Add protection rules if desired
   - Save

### Step 3: Trigger Deployment

The deployment has already been triggered! Check the status:

```bash
gh run list
```

Or visit:
```
https://github.com/typnthu/sweetdream/actions
```

### Step 4: Monitor Deployment

The deployment workflow will:

1. ✅ **Build Backend Image** (~2-3 minutes)
   - Builds Docker image from `be/Dockerfile`
   - Pushes to ECR: `sweetdream-backend`

2. ✅ **Build Frontend Image** (~2-3 minutes)
   - Builds Docker image from `fe/Dockerfile`
   - Pushes to ECR: `sweetdream-frontend`

3. ✅ **Deploy to ECS** (~5-10 minutes)
   - Updates ECS task definitions
   - Deploys backend service
   - Deploys frontend service
   - Runs database migrations

4. ✅ **Health Checks** (~2-3 minutes)
   - ALB checks if services are healthy
   - Services become available

**Total Time:** ~15-20 minutes

### Step 5: Verify Deployment

Once deployment completes:

1. **Check ECS Services:**
   ```bash
   aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend sweetdream-service-frontend
   ```

2. **Check Application:**
   ```
   http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com
   ```

3. **Check Logs:**
   ```bash
   aws logs tail /ecs/sweetdream --follow
   ```

## Troubleshooting

### If Deployment Fails

1. **Check GitHub Actions logs:**
   - Go to Actions tab
   - Click on the failed workflow
   - Check which step failed

2. **Common Issues:**

   **AWS Credentials Error:**
   - Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set correctly
   - Check IAM user has required permissions

   **Docker Build Fails:**
   - Check Dockerfile syntax
   - Ensure all dependencies are in package.json

   **ECS Service Unhealthy:**
   - Check CloudWatch logs: `aws logs tail /ecs/sweetdream --follow`
   - Verify environment variables in task definition
   - Check security group rules

   **Database Connection Error:**
   - Verify DB_PASSWORD secret matches terraform.tfvars
   - Check RDS security group allows connections from ECS

### Manual Deployment (If GitHub Actions Fails)

If you need to deploy manually:

```bash
# 1. Build and push images
cd be
docker build -t 482364569701.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 482364569701.dkr.ecr.us-east-1.amazonaws.com
docker push 482364569701.dkr.ecr.us-east-1.amazonaws.com/sweetdream-backend:latest

cd ../fe
docker build -t 482364569701.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:latest .
docker push 482364569701.dkr.ecr.us-east-1.amazonaws.com/sweetdream-frontend:latest

# 2. Update ECS services
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-backend --force-new-deployment
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-frontend --force-new-deployment
```

## Database Setup

After first deployment, you need to seed the database:

```bash
# Get backend task ARN
TASK_ARN=$(aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-service-backend --desired-status RUNNING --query 'taskArns[0]' --output text)

# Run seed command
aws ecs execute-command \
  --cluster sweetdream-cluster \
  --task $TASK_ARN \
  --container sweetdream-backend \
  --interactive \
  --command "npm run seed"
```

Or use the GitHub Actions workflow:
- Go to Actions → Database Migration
- Click "Run workflow"
- Select "seed" action

## Monitoring

### CloudWatch Logs
```bash
# View all logs
aws logs tail /ecs/sweetdream --follow

# View backend logs only
aws logs tail /ecs/sweetdream --follow --filter-pattern "backend"

# View frontend logs only
aws logs tail /ecs/sweetdream --follow --filter-pattern "frontend"
```

### ECS Service Status
```bash
# Check service health
aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend sweetdream-service-frontend

# Check running tasks
aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-service-backend
aws ecs list-tasks --cluster sweetdream-cluster --service-name sweetdream-service-frontend
```

### ALB Target Health
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:482364569701:targetgroup/sweetdream-frontend-tg/4b4ad1063532b43b
```

## Cost Estimation

**Monthly Costs (Development):**
- ECS Fargate: ~$15-20 (2 tasks running 24/7)
- RDS db.t4g.micro: ~$15
- NAT Gateway: ~$32
- ALB: ~$16
- S3 & CloudWatch: ~$5

**Total: ~$80-90/month**

**To Reduce Costs:**
- Stop ECS services when not in use
- Use smaller RDS instance
- Remove NAT Gateway (use public subnets for dev)

## Useful Commands

```bash
# Stop all ECS services (save costs)
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-backend --desired-count 0
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-frontend --desired-count 0

# Start ECS services
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-backend --desired-count 2
aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-frontend --desired-count 2

# View database endpoint
cd terraform
terraform output db_endpoint

# Destroy all infrastructure (when done)
cd terraform
terraform destroy
```

## Next Steps After Deployment

1. **Set up custom domain** (optional)
   - Register domain in Route 53
   - Create SSL certificate in ACM
   - Update ALB listener to use HTTPS

2. **Configure CI/CD for automatic deployments**
   - Already set up! Just push to `dev` branch

3. **Set up monitoring alerts**
   - CloudWatch alarms for high CPU/memory
   - SNS notifications for failures

4. **Backup strategy**
   - RDS automated backups (already enabled)
   - S3 versioning (already enabled)

## Support

If you encounter issues:
1. Check CloudWatch logs
2. Review GitHub Actions workflow logs
3. Verify all secrets are configured correctly
4. Check AWS Console for resource status

---

**Your infrastructure is ready! Just configure the GitHub Secrets and the deployment will complete automatically.**
