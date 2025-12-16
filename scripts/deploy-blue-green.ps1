# Blue-Green Deployment Script for SweetDream
# This script triggers a blue-green deployment using AWS CodeDeploy

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$ImageTag,
    
    [string]$ProjectName = "sweetdream",
    [string]$Region = "us-east-1",
    [string]$ClusterName = "sweetdream-cluster",
    [bool]$WaitForCompletion = $true
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Blue-Green Deployment for $ServiceName" -ForegroundColor Green
Write-Host "Image Tag: $ImageTag" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow

# Validate service name
$validServices = @("frontend", "backend", "user-service", "order-service")
if ($ServiceName -notin $validServices) {
    Write-Error "Invalid service name. Valid options: $($validServices -join ', ')"
    exit 1
}

# Check AWS CLI
try {
    aws --version | Out-Null
} catch {
    Write-Error "AWS CLI not found. Please install AWS CLI first."
    exit 1
}

# Get current AWS account ID
try {
    $accountId = aws sts get-caller-identity --query Account --output text
    Write-Host "AWS Account ID: $accountId" -ForegroundColor Yellow
} catch {
    Write-Error "Failed to get AWS account ID. Please check your AWS credentials."
    exit 1
}

# Construct ECR repository URL
$ecrRepo = "$accountId.dkr.ecr.$Region.amazonaws.com/$ProjectName-$ServiceName"
$imageUri = "$ecrRepo`:$ImageTag"

Write-Host "Image URI: $imageUri" -ForegroundColor Yellow

# Create task definition revision with new image
Write-Host "📝 Creating new task definition revision..." -ForegroundColor Blue

$taskDefName = "$ProjectName-service-$ServiceName"

# Get current task definition
try {
    $currentTaskDef = aws ecs describe-task-definition --task-definition $taskDefName --query 'taskDefinition' --output json | ConvertFrom-Json
} catch {
    Write-Error "Failed to get current task definition for $taskDefName"
    exit 1
}

# Update image URI in container definitions
foreach ($container in $currentTaskDef.containerDefinitions) {
    if ($container.name -eq $ServiceName) {
        $container.image = $imageUri
        Write-Host "Updated container image: $($container.name) -> $imageUri" -ForegroundColor Green
    }
}

# Remove read-only fields
$newTaskDef = @{
    family = $currentTaskDef.family
    taskRoleArn = $currentTaskDef.taskRoleArn
    executionRoleArn = $currentTaskDef.executionRoleArn
    networkMode = $currentTaskDef.networkMode
    requiresCompatibilities = $currentTaskDef.requiresCompatibilities
    cpu = $currentTaskDef.cpu
    memory = $currentTaskDef.memory
    containerDefinitions = $currentTaskDef.containerDefinitions
}

# Add optional fields if they exist
if ($currentTaskDef.volumes) { $newTaskDef.volumes = $currentTaskDef.volumes }
if ($currentTaskDef.placementConstraints) { $newTaskDef.placementConstraints = $currentTaskDef.placementConstraints }

# Convert to JSON and register new task definition
$taskDefJson = $newTaskDef | ConvertTo-Json -Depth 10 -Compress
$tempFile = [System.IO.Path]::GetTempFileName()
$taskDefJson | Out-File -FilePath $tempFile -Encoding UTF8

try {
    $newRevision = aws ecs register-task-definition --cli-input-json file://$tempFile --query 'taskDefinition.revision' --output text
    Write-Host "✅ Created task definition revision: $newRevision" -ForegroundColor Green
} catch {
    Write-Error "Failed to register new task definition"
    exit 1
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

# Create CodeDeploy deployment
Write-Host "🔄 Starting CodeDeploy blue-green deployment..." -ForegroundColor Blue

$appName = "$ProjectName-codedeploy-app"
$deploymentGroupName = "$ServiceName-deployment-group"
$deploymentDescription = "Blue-green deployment for $ServiceName with image tag $ImageTag"

# Create appspec content
$appSpec = @{
    version = "0.0"
    Resources = @(
        @{
            TargetService = @{
                Type = "AWS::ECS::Service"
                Properties = @{
                    TaskDefinition = "$taskDefName`:$newRevision"
                    LoadBalancerInfo = @{
                        ContainerName = $ServiceName
                        ContainerPort = switch ($ServiceName) {
                            "frontend" { 3000 }
                            "backend" { 3001 }
                            "user-service" { 3003 }
                            "order-service" { 3002 }
                            default { 3000 }
                        }
                    }
                    PlatformVersion = "LATEST"
                }
            }
        }
    )
}

$appSpecJson = $appSpec | ConvertTo-Json -Depth 10 -Compress

# Create deployment
try {
    $deploymentId = aws deploy create-deployment `
        --application-name $appName `
        --deployment-group-name $deploymentGroupName `
        --description $deploymentDescription `
        --revision "revisionType=AppSpecContent,appSpecContent={content='$appSpecJson'}" `
        --query 'deploymentId' --output text

    Write-Host "✅ Created deployment: $deploymentId" -ForegroundColor Green
    Write-Host "🔗 Monitor deployment: https://console.aws.amazon.com/codesuite/codedeploy/deployments/$deploymentId" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to create CodeDeploy deployment"
    exit 1
}

# Wait for deployment completion if requested
if ($WaitForCompletion) {
    Write-Host "⏳ Waiting for deployment to complete..." -ForegroundColor Yellow
    
    do {
        Start-Sleep -Seconds 30
        try {
            $status = aws deploy get-deployment --deployment-id $deploymentId --query 'deploymentInfo.status' --output text
            Write-Host "Deployment status: $status" -ForegroundColor Yellow
        } catch {
            Write-Error "Failed to get deployment status"
            exit 1
        }
    } while ($status -in @("Created", "Queued", "InProgress"))
    
    if ($status -eq "Succeeded") {
        Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
        
        # Get service endpoint
        try {
            $albDnsName = aws elbv2 describe-load-balancers --names "$ProjectName-alb" --query 'LoadBalancers[0].DNSName' --output text
            Write-Host "🌐 Service endpoint: http://$albDnsName" -ForegroundColor Cyan
        } catch {
            Write-Host "Could not retrieve load balancer endpoint" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Deployment failed with status: $status" -ForegroundColor Red
        
        # Get failure reason
        try {
            $errorInfo = aws deploy get-deployment --deployment-id $deploymentId --query 'deploymentInfo.errorInformation' --output json | ConvertFrom-Json
            if ($errorInfo) {
                Write-Host "Error: $($errorInfo.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "Could not retrieve error details" -ForegroundColor Yellow
        }
        exit 1
    }
} else {
    Write-Host "🚀 Deployment started. Use the following command to monitor:" -ForegroundColor Green
    Write-Host "aws deploy get-deployment --deployment-id $deploymentId" -ForegroundColor Cyan
}

Write-Host "✅ Blue-Green deployment script completed!" -ForegroundColor Green