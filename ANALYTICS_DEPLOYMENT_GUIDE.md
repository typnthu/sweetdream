# Analytics Lambda Deployment Guide

## Current Situation

Your Terraform configuration includes a Lambda function for exporting user action logs from CloudWatch to S3, but it's **not deployed to AWS yet**.

## What the Lambda Does

The Lambda function (`cloudwatch-analytics` module):
- ✅ Exports user action logs from CloudWatch to S3
- ✅ Runs daily at **midnight Vietnam time** (17:00 UTC)
- ✅ Filters logs with `category: "user_action"` 
- ✅ Exports in JSON or CSV format
- ✅ Organizes data: `s3://bucket/user-actions/year=2024/month=12/day=02/user_actions.json`

## User Actions Being Logged

### Backend Service (be)
- Product Viewed
- Product Search
- Add to Cart
- Checkout Started

### Order Service
- Order Completed (with product details, quantities, prices)

## Deployment Steps

### 1. Review Configuration

Check `terraform/main.tf` - both analytics modules are configured:

```hcl
# Backend Analytics
module "backend_analytics" {
  count  = var.enable_customer_analytics ? 1 : 0
  source = "./modules/cloudwatch-analytics"
  
  service_name          = "sweetdream-service-backend"
  log_group_name        = "/ecs/sweetdream-sweetdream-service-backend"
  analytics_bucket_name = "sweetdream-analytics-backend-production"
  export_format         = "json"
  enable_lambda_export  = true  # ✅ Lambda enabled
}

# Order Service Analytics
module "order_analytics" {
  count  = var.enable_customer_analytics ? 1 : 0
  source = "./modules/cloudwatch-analytics"
  
  service_name          = "sweetdream-service-order-service"
  log_group_name        = "/ecs/sweetdream-sweetdream-service-order-service"
  analytics_bucket_name = "sweetdream-analytics-order-production"
  export_format         = "json"
  enable_lambda_export  = true  # ✅ Lambda enabled
}
```

### 2. Deploy to AWS

```bash
cd terraform

# Initialize (if needed)
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

This will create:
- 2 S3 buckets for analytics data
- 2 Lambda functions (one for backend, one for order-service)
- 2 EventBridge rules for daily triggers
- IAM roles and permissions
- CloudWatch Insights queries

### 3. Test the Lambda

After deployment, test manually:

```bash
# Test backend analytics Lambda
aws lambda invoke \
  --function-name sweetdream-service-backend-export-logs \
  --payload '{"test_mode": true}' \
  response.json

# Test order analytics Lambda
aws lambda invoke \
  --function-name sweetdream-service-order-service-export-logs \
  --payload '{"test_mode": true}' \
  response.json

# Check results
cat response.json
```

### 4. Verify S3 Exports

Check if data is exported:

```bash
# Backend analytics
aws s3 ls s3://sweetdream-analytics-backend-production/user-actions/ --recursive

# Order analytics
aws s3 ls s3://sweetdream-analytics-order-production/user-actions/ --recursive
```

### 5. View CloudWatch Insights Queries

After deployment, go to AWS Console:
1. CloudWatch → Insights → Saved queries
2. Look for queries like:
   - `sweetdream-service-backend/analytics/product-views-by-user`
   - `sweetdream-service-backend/analytics/purchases`
   - `sweetdream-service-order-service/analytics/purchases`

## Data Structure

### Exported JSON Format

```json
[
  {
    "@timestamp": "2024-12-02T10:30:00.000Z",
    "level": "info",
    "service": "backend",
    "category": "user_action",
    "message": "Product Viewed",
    "userId": 123,
    "userName": "John Doe",
    "sessionId": "abc123",
    "metadata": {
      "productId": 45,
      "productName": "Áo thun nam",
      "price": 299000,
      "category": "Áo"
    }
  }
]
```

## Cost Estimate

- Lambda executions: 2 per day × $0.20 per million = ~$0.01/month
- S3 storage: ~$0.023 per GB/month
- CloudWatch Logs: Already included in your log retention
- **Total: < $1/month** for analytics

## Troubleshooting

### Lambda not exporting data?

1. Check Lambda logs:
```bash
aws logs tail /aws/lambda/sweetdream-service-backend-export-logs --follow
```

2. Verify log group exists:
```bash
aws logs describe-log-groups --log-group-name-prefix "/ecs/sweetdream"
```

3. Check if user actions are being logged:
```bash
aws logs filter-log-events \
  --log-group-name "/ecs/sweetdream-sweetdream-service-backend" \
  --filter-pattern "user_action" \
  --max-items 5
```

### No data in S3?

- Lambda runs at midnight Vietnam time (17:00 UTC)
- It exports **yesterday's** logs
- Use `test_mode: true` to export today's logs for testing

## Next Steps

After deployment, you can:
1. Query data using AWS Athena (create table pointing to S3)
2. Build dashboards in QuickSight
3. Export to your analytics platform
4. Use CloudWatch Insights for quick queries
