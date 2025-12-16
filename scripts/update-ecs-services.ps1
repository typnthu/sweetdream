# Update ECS Services with new images
param(
    [string]$Environment = "dev"
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Reset = "`e[0m"

# Configuration
$AWS_REGION = "us-east-1"
$CLUSTER_NAME = "sweetdream-dev-cluster"

Write-Host "${Green}🔄 Updating ECS services with new images...${Reset}"

# Function to update ECS service
function Update-Service {
    param(
        [string]$ServiceName
    )
    
    Write-Host "${Yellow}🔄 Updating ${ServiceName}...${Reset}"
    
    try {
        # Force new deployment
        $result = aws ecs update-service `
            --region $AWS_REGION `
            --cluster $CLUSTER_NAME `
            --service $ServiceName `
            --force-new-deployment `
            --query 'service.serviceName' `
            --output text
        
        Write-Host "${Green}✅ ${ServiceName} update initiated${Reset}"
        return $true
    } catch {
        Write-Host "${Red}❌ Failed to update ${ServiceName}${Reset}"
        return $false
    }
}

# Update all services
Write-Host "${Yellow}📋 Updating ECS services...${Reset}"

$services = @(
    "sweetdream-dev-service-backend",
    "sweetdream-dev-service-user-service", 
    "sweetdream-dev-service-order-service",
    "sweetdream-dev-service-frontend"
)

$success = $true
foreach ($service in $services) {
    if (-not (Update-Service -ServiceName $service)) {
        $success = $false
    }
    Start-Sleep -Seconds 2
}

if ($success) {
    Write-Host "${Green}🎉 ECS services update completed!${Reset}"
    Write-Host "${Green}📋 Monitor deployment status:${Reset}"
    Write-Host "   aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --services $($services -join ' ')"
    
    # Wait for services to stabilize
    Write-Host "${Yellow}⏳ Waiting for services to stabilize (this may take a few minutes)...${Reset}"
    try {
        aws ecs wait services-stable `
            --region $AWS_REGION `
            --cluster $CLUSTER_NAME `
            --services $services
        
        Write-Host "${Green}✅ All services are stable and running!${Reset}"
        Write-Host "${Green}🌐 Application URL: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com${Reset}"
    } catch {
        Write-Host "${Yellow}⚠️  Services are updating. Check AWS Console for status.${Reset}"
    }
} else {
    Write-Host "${Red}❌ Some services failed to update${Reset}"
    exit 1
}