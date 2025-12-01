#!/bin/bash
# Quick script to deploy analytics Lambda functions

echo "🚀 Deploying Analytics Lambda Functions"
echo ""

cd terraform

echo "📋 Step 1: Initialize Terraform"
terraform init

echo ""
echo "📊 Step 2: Plan deployment (analytics only)"
terraform plan \
  -target=module.backend_analytics \
  -target=module.order_analytics \
  -var="enable_customer_analytics=true"

echo ""
read -p "Do you want to apply these changes? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
  echo ""
  echo "🔨 Step 3: Applying changes..."
  terraform apply \
    -target=module.backend_analytics \
    -target=module.order_analytics \
    -var="enable_customer_analytics=true" \
    -auto-approve
  
  echo ""
  echo "✅ Deployment complete!"
  echo ""
  echo "🔍 Verifying Lambda functions..."
  aws lambda list-functions --query 'Functions[?contains(FunctionName, `sweetdream`)].FunctionName'
  
  echo ""
  echo "📦 Verifying S3 buckets..."
  aws s3 ls | grep sweetdream-analytics
  
  echo ""
  echo "🎉 Analytics Lambda is now deployed!"
  echo ""
  echo "📝 Next steps:"
  echo "1. Test the Lambda:"
  echo "   aws lambda invoke --function-name sweetdream-service-backend-export-logs --payload '{\"test_mode\": true}' response.json"
  echo ""
  echo "2. Check the result:"
  echo "   cat response.json | jq ."
  echo ""
  echo "3. View exported data:"
  echo "   aws s3 ls s3://sweetdream-analytics-typnthu-backend-production/user-actions/ --recursive"
else
  echo "❌ Deployment cancelled"
fi
