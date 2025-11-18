# Simple script to seed database via ECS task

Write-Host "Seeding Database..." -ForegroundColor Green

# Get network config from existing service
$serviceInfo = aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend --output json | ConvertFrom-Json
$subnets = $serviceInfo.services[0].networkConfiguration.awsvpcConfiguration.subnets
$securityGroups = $serviceInfo.services[0].networkConfiguration.awsvpcConfiguration.securityGroups

# Create network config JSON
$networkConfig = @{
    awsvpcConfiguration = @{
        subnets = $subnets
        securityGroups = $securityGroups
        assignPublicIp = "DISABLED"
    }
} | ConvertTo-Json -Compress -Depth 10

# Create overrides JSON
$overrides = @{
    containerOverrides = @(
        @{
            name = "sweetdream-backend"
            command = @("npm", "run", "seed:prod")
        }
    )
} | ConvertTo-Json -Compress -Depth 10

Write-Host "Starting seed task..."

# Run task
$result = aws ecs run-task `
    --cluster sweetdream-cluster `
    --task-definition sweetdream-task-backend `
    --launch-type FARGATE `
    --network-configuration $networkConfig `
    --overrides $overrides `
    --output json | ConvertFrom-Json

$taskArn = $result.tasks[0].taskArn

Write-Host "Task started: $taskArn" -ForegroundColor Green
Write-Host ""
Write-Host "Waiting for completion (this may take 2-3 minutes)..."

# Wait for task
Start-Sleep -Seconds 30

for ($i = 0; $i -lt 12; $i++) {
    $taskInfo = aws ecs describe-tasks --cluster sweetdream-cluster --tasks $taskArn --output json | ConvertFrom-Json
    $status = $taskInfo.tasks[0].lastStatus
    
    Write-Host "Status: $status"
    
    if ($status -eq "STOPPED") {
        $exitCode = $taskInfo.tasks[0].containers[0].exitCode
        
        if ($exitCode -eq 0) {
            Write-Host ""
            Write-Host "SUCCESS! Database seeded." -ForegroundColor Green
            Write-Host "Visit: http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com"
        } else {
            Write-Host ""
            Write-Host "FAILED! Exit code: $exitCode" -ForegroundColor Red
            Write-Host "Check logs: aws logs tail /ecs/sweetdream --follow"
        }
        break
    }
    
    Start-Sleep -Seconds 15
}
