# Force ECS Service Deployment
# This script forces all ECS services to redeploy with the latest Docker images

Write-Host "Forcing ECS service deployments..." -ForegroundColor Cyan

$services = @(
    "sweetdream-service-backend",
    "sweetdream-service-frontend",
    "sweetdream-service-user-service",
    "sweetdream-service-order-service"
)

foreach ($service in $services) {
    Write-Host "`nUpdating $service..." -ForegroundColor Yellow

    aws ecs update-service `
        --cluster sweetdream-cluster `
        --service $service `
        --force-new-deployment `
        --query 'service.[serviceName,status,desiredCount,runningCount]' `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment initiated for $service" -ForegroundColor Green
    } else {
        Write-Host "Failed to update $service" -ForegroundColor Red
    }
}

Write-Host "`nWaiting for deployments to complete..." -ForegroundColor Cyan
Write-Host "You can monitor progress with:" -ForegroundColor Gray

$servicesStr = $services -join ' '
Write-Host "  aws ecs describe-services --cluster sweetdream-cluster --services $servicesStr" -ForegroundColor Gray

Write-Host "`nOr check the AWS ECS Console:" -ForegroundColor Gray
$consoleUrl = "https://console.aws.amazon.com/ecs/v2/clusters/sweetdream-cluster/services"
Write-Host ("  {0}" -f $consoleUrl) -ForegroundColor Gray
