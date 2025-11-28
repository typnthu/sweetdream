# Import All Existing AWS Resources into Terraform State
# Run this to sync Terraform state with actual AWS resources

$ErrorActionPreference = "Stop"

Write-Host "Importing all existing AWS resources..." -ForegroundColor Cyan

cd terraform

# CloudWatch Log Groups
Write-Host "`nImporting CloudWatch Log Groups..." -ForegroundColor Yellow
terraform import 'module.ecs_backend.module.cloudwatch_logs.aws_cloudwatch_log_group.app' /ecs/sweetdream-sweetdream-service-backend
terraform import 'module.ecs_frontend.module.cloudwatch_logs.aws_cloudwatch_log_group.app' /ecs/sweetdream-sweetdream-service-frontend
terraform import 'module.ecs_order_service.module.cloudwatch_logs.aws_cloudwatch_log_group.app' /ecs/sweetdream-sweetdream-service-order-service
terraform import 'module.ecs_user_service.module.cloudwatch_logs.aws_cloudwatch_log_group.app' /ecs/sweetdream-sweetdream-service-user-service

# IAM Policies
Write-Host "`nImporting IAM Policies..." -ForegroundColor Yellow
$s3PolicyArn = aws iam list-policies --query "Policies[?PolicyName=='sweetdream-s3-access-policy'].Arn" --output text
$cwPolicyArn = aws iam list-policies --query "Policies[?PolicyName=='sweetdream-cloudwatch-logs-policy'].Arn" --output text
terraform import "module.iam.aws_iam_policy.s3_access" $s3PolicyArn
terraform import "module.iam.aws_iam_policy.cloudwatch_logs" $cwPolicyArn

Write-Host ""
Write-Host "Import complete!" -ForegroundColor Green
Write-Host "Now you can run terraform apply safely" -ForegroundColor Cyan

cd ..
