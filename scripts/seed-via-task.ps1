# Script to seed database by running a one-time ECS task
# This doesn't require ECS Exec

Write-Host "🌱 Seeding Database via ECS Task..." -ForegroundColor Green
Write-Host ""

# Configuration
$CLUSTER = "sweetdream-cluster"
$TASK_DEFINITION = "sweetdream-task-backend"
$CONTAINER_NAME = "sweetdream-backend"

# Get VPC configuration from existing service
Write-Host "📋 Getting network configuration..." -ForegroundColor Cyan
$SERVICE_INFO = aws ecs describe-services `
    --cluster $CLUSTER `
    --services sweetdream-service-backend `
    --query 'services[0].networkConfiguration.awsvpcConfiguration' `
    --output json | ConvertFrom-Json

$SUBNETS = $SERVICE_INFO.subnets -join ','
$SECURITY_GROUPS = $SERVICE_INFO.securityGroups -join ','

Write-Host "✅ Network config retrieved" -ForegroundColor Green
Write-Host ""

# Run one-time task with seed command
Write-Host "🚀 Starting seed task..." -ForegroundColor Cyan
Write-Host "This will take a few minutes..." -ForegroundColor Yellow
Write-Host ""

$TASK_ARN = aws ecs run-task `
    --cluster $CLUSTER `
    --task-definition $TASK_DEFINITION `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUPS],assignPublicIp=DISABLED}" `
    --overrides "{`"containerOverrides`":[{`"name`":`"$CONTAINER_NAME`",`"command`":[`"npm`",`"run`",`"seed:prod`"]}]}" `
    --query 'tasks[0].taskArn' `
    --output text

if (!$TASK_ARN) {
    Write-Host "❌ Failed to start task!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Task started: $TASK_ARN" -ForegroundColor Green
Write-Host ""

# Wait for task to complete
Write-Host "⏳ Waiting for task to complete..." -ForegroundColor Cyan
Write-Host "Checking status every 10 seconds..." -ForegroundColor Yellow
Write-Host ""

$MAX_WAIT = 300  # 5 minutes
$ELAPSED = 0

while ($ELAPSED -lt $MAX_WAIT) {
    Start-Sleep -Seconds 10
    $ELAPSED += 10
    
    $STATUS = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $TASK_ARN `
        --query 'tasks[0].lastStatus' `
        --output text
    
    Write-Host "Status: $STATUS (${ELAPSED}s elapsed)" -ForegroundColor Cyan
    
    if ($STATUS -eq "STOPPED") {
        break
    }
}

# Check exit code
Write-Host ""
Write-Host "📊 Checking result..." -ForegroundColor Cyan

$TASK_DETAILS = aws ecs describe-tasks `
    --cluster $CLUSTER `
    --tasks $TASK_ARN `
    --query 'tasks[0]' `
    --output json | ConvertFrom-Json

$EXIT_CODE = $TASK_DETAILS.containers[0].exitCode
$STOP_REASON = $TASK_DETAILS.stoppedReason

if ($EXIT_CODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Database seeded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Your application should now display products!" -ForegroundColor Green
    Write-Host "Visit: http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ Seed task failed!" -ForegroundColor Red
    Write-Host "Exit code: $EXIT_CODE" -ForegroundColor Yellow
    Write-Host "Reason: $STOP_REASON" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check logs for details:" -ForegroundColor Cyan
    Write-Host "aws logs tail /ecs/sweetdream --follow --filter-pattern backend" -ForegroundColor White
}

Write-Host ""
Write-Host "Task ARN: $TASK_ARN" -ForegroundColor Gray
