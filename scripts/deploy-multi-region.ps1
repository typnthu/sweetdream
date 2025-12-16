# Multi-Region Deployment Script for SweetDream
# This script deploys to multiple regions (dev and prod)

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod", "both")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$ImageTag,
    
    [string]$ProjectName = "sweetdream",
    [bool]$WaitForCompletion = $true,
    [bool]$PromoteFromDev = $false
)

$ErrorActionPreference = "Stop"

# Environment configuration
$environments = @{
    "dev" = @{
        "region" = "us-east-1"
        "cluster" = "sweetdream-cluster"
    }
    "prod" = @{
        "region" = "us-west-2"
        "cluster" = "sweetdream-cluster"
    }
}

function Deploy-ToEnvironment {
    param(
        [string]$EnvName,
        [string]$Service,
        [string]$Tag,
        [bool]$Wait
    )
    
    $envConfig = $environments[$EnvName]
    $region = $envConfig.region
    $cluster = $envConfig.cluster
    
    Write-Host "🚀 Deploying $Service to $EnvName environment ($region)" -ForegroundColor Green
    
    # Set AWS region for this deployment
    $env:AWS_DEFAULT_REGION = $region
    
    try {
        # Call the blue-green deployment script
        & ".\scripts\deploy-blue-green.ps1" `
            -ServiceName $Service `
            -ImageTag $Tag `
            -ProjectName $ProjectName `
            -Region $region `
            -ClusterName $cluster `
            -WaitForCompletion $Wait
            
        Write-Host "✅ Successfully deployed $Service to $EnvName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to deploy $Service to $EnvName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Promote-ImageFromDev {
    param(
        [string]$Service,
        [string]$Tag
    )
    
    Write-Host "📦 Promoting image from dev to prod region..." -ForegroundColor Blue
    
    $devAccountId = (aws sts get-caller-identity --query Account --output text)
    $devImage = "$devAccountId.dkr.ecr.us-east-1.amazonaws.com/$ProjectName-$Service`:$Tag"
    $prodImage = "$devAccountId.dkr.ecr.us-west-2.amazonaws.com/$ProjectName-$Service`:$Tag"
    
    try {
        # Login to both regions
        Write-Host "🔐 Logging into ECR in both regions..."
        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$devAccountId.dkr.ecr.us-east-1.amazonaws.com"
        aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$devAccountId.dkr.ecr.us-west-2.amazonaws.com"
        
        # Pull from dev region
        Write-Host "⬇️ Pulling image from dev region..."
        docker pull $devImage
        
        # Tag for prod region
        Write-Host "🏷️ Tagging image for prod region..."
        docker tag $devImage $prodImage
        
        # Push to prod region
        Write-Host "⬆️ Pushing image to prod region..."
        docker push $prodImage
        
        Write-Host "✅ Successfully promoted image to prod region" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to promote image: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main deployment logic
Write-Host "🌍 Multi-Region Deployment Started" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Service: $ServiceName" -ForegroundColor Yellow
Write-Host "Image Tag: $ImageTag" -ForegroundColor Yellow

$deploymentResults = @{}

# Promote image from dev to prod if requested
if ($PromoteFromDev -and ($Environment -eq "prod" -or $Environment -eq "both")) {
    if (-not (Promote-ImageFromDev -Service $ServiceName -Tag $ImageTag)) {
        Write-Host "❌ Image promotion failed. Aborting deployment." -ForegroundColor Red
        exit 1
    }
}

# Deploy to environments
switch ($Environment) {
    "dev" {
        $deploymentResults["dev"] = Deploy-ToEnvironment -EnvName "dev" -Service $ServiceName -Tag $ImageTag -Wait $WaitForCompletion
    }
    "prod" {
        $deploymentResults["prod"] = Deploy-ToEnvironment -EnvName "prod" -Service $ServiceName -Tag $ImageTag -Wait $WaitForCompletion
    }
    "both" {
        # Deploy to dev first
        $deploymentResults["dev"] = Deploy-ToEnvironment -EnvName "dev" -Service $ServiceName -Tag $ImageTag -Wait $WaitForCompletion
        
        if ($deploymentResults["dev"]) {
            Write-Host "⏳ Dev deployment successful. Proceeding to prod..." -ForegroundColor Green
            Start-Sleep -Seconds 10
            $deploymentResults["prod"] = Deploy-ToEnvironment -EnvName "prod" -Service $ServiceName -Tag $ImageTag -Wait $WaitForCompletion
        } else {
            Write-Host "❌ Dev deployment failed. Skipping prod deployment." -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n📊 Deployment Summary:" -ForegroundColor Cyan
foreach ($env in $deploymentResults.Keys) {
    $status = if ($deploymentResults[$env]) { "✅ SUCCESS" } else { "❌ FAILED" }
    $color = if ($deploymentResults[$env]) { "Green" } else { "Red" }
    Write-Host "$env`: $status" -ForegroundColor $color
}

# Exit with appropriate code
$allSuccessful = ($deploymentResults.Values | Where-Object { $_ -eq $false }).Count -eq 0
if ($allSuccessful) {
    Write-Host "`n🎉 Multi-region deployment completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n💥 Some deployments failed. Check the logs above." -ForegroundColor Red
    exit 1
}