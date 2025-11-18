# Script to seed the database via ECS Exec
# This connects to a running backend task and runs the seed command

Write-Host "🌱 Seeding Database..." -ForegroundColor Green
Write-Host ""

# Get the backend task ARN
Write-Host "📋 Finding backend task..." -ForegroundColor Cyan
$TASK_ARN = aws ecs list-tasks `
    --cluster sweetdream-cluster `
    --service-name sweetdream-service-backend `
    --desired-status RUNNING `
    --query 'taskArns[0]' `
    --output text

if (!$TASK_ARN -or $TASK_ARN -eq "None") {
    Write-Host "❌ No running backend tasks found!" -ForegroundColor Red
    Write-Host "Make sure the backend service is running." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found task: $TASK_ARN" -ForegroundColor Green
Write-Host ""

# Check if ECS Exec is enabled
Write-Host "🔍 Checking ECS Exec status..." -ForegroundColor Cyan
$TASK_INFO = aws ecs describe-tasks `
    --cluster sweetdream-cluster `
    --tasks $TASK_ARN `
    --query 'tasks[0].enableExecuteCommand' `
    --output text

if ($TASK_INFO -eq "False") {
    Write-Host "⚠️  ECS Exec is not enabled on this task." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Run seed via GitHub Actions" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/typnthu/sweetdream/actions" -ForegroundColor White
    Write-Host "2. Select 'Database Migration' workflow" -ForegroundColor White
    Write-Host "3. Click 'Run workflow'" -ForegroundColor White
    Write-Host "4. Select action: 'seed'" -ForegroundColor White
    Write-Host ""
    
    # Alternative: Connect to task and run command manually
    Write-Host "Or enable ECS Exec and update the service:" -ForegroundColor Cyan
    Write-Host "aws ecs update-service --cluster sweetdream-cluster --service sweetdream-service-backend --enable-execute-command" -ForegroundColor White
    exit 1
}

Write-Host "✅ ECS Exec is enabled" -ForegroundColor Green
Write-Host ""

# Run the seed command
Write-Host "🌱 Running seed command..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

aws ecs execute-command `
    --cluster sweetdream-cluster `
    --task $TASK_ARN `
    --container sweetdream-backend `
    --interactive `
    --command "npm run seed"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Database seeded successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Seed command failed!" -ForegroundColor Red
    Write-Host "Check the logs for more details:" -ForegroundColor Yellow
    Write-Host "aws logs tail /ecs/sweetdream --follow --filter-pattern backend" -ForegroundColor White
}
