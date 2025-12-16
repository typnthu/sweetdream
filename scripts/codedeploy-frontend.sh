#!/bin/bash

# Deploy Frontend using CodeDeploy Blue-Green
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="409964509537"
APPLICATION_NAME="sweetdream-dev-service-frontend-codedeploy"
DEPLOYMENT_GROUP="sweetdream-dev-service-frontend-deployment-group"
TASK_DEFINITION_FAMILY="sweetdream-dev-task-frontend"
CONTAINER_NAME="sweetdream-frontend"
IMAGE_TAG=${1:-dev}

echo -e "${GREEN}🚀 Starting CodeDeploy Blue-Green deployment for Frontend...${NC}"

# Get current task definition
echo -e "${YELLOW}📋 Getting current task definition...${NC}"
TASK_DEF=$(aws ecs describe-task-definition \
    --region ${AWS_REGION} \
    --task-definition ${TASK_DEFINITION_FAMILY} \
    --query 'taskDefinition')

# Update image in task definition
echo -e "${YELLOW}🔄 Creating new task definition with updated image...${NC}"
NEW_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/sweetdream-frontend:${IMAGE_TAG}"

# Create new task definition JSON
NEW_TASK_DEF=$(echo $TASK_DEF | jq --arg IMAGE "$NEW_IMAGE" \
    '.containerDefinitions[0].image = $IMAGE | 
     del(.taskDefinitionArn) | 
     del(.revision) | 
     del(.status) | 
     del(.requiresAttributes) | 
     del(.placementConstraints) | 
     del(.compatibilities) | 
     del(.registeredAt) | 
     del(.registeredBy)')

# Register new task definition
echo -e "${YELLOW}📝 Registering new task definition...${NC}"
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | aws ecs register-task-definition \
    --region ${AWS_REGION} \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✅ New task definition registered: ${NEW_TASK_DEF_ARN}${NC}"

# Create CodeDeploy deployment
echo -e "${YELLOW}🚀 Creating CodeDeploy deployment...${NC}"

# Create appspec content
APPSPEC_CONTENT=$(cat <<EOF
{
  "version": "0.0",
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "${NEW_TASK_DEF_ARN}",
          "LoadBalancerInfo": {
            "ContainerName": "${CONTAINER_NAME}",
            "ContainerPort": 3000
          }
        }
      }
    }
  ]
}
EOF
)

# Create deployment
DEPLOYMENT_ID=$(aws deploy create-deployment \
    --region ${AWS_REGION} \
    --application-name ${APPLICATION_NAME} \
    --deployment-group-name ${DEPLOYMENT_GROUP} \
    --revision "{\"revisionType\":\"AppSpecContent\",\"appSpecContent\":{\"content\":\"$(echo $APPSPEC_CONTENT | base64 -w 0)\"}}" \
    --query 'deploymentId' \
    --output text)

echo -e "${GREEN}✅ CodeDeploy deployment created: ${DEPLOYMENT_ID}${NC}"
echo -e "${YELLOW}⏳ Monitoring deployment progress...${NC}"

# Monitor deployment
while true; do
    STATUS=$(aws deploy get-deployment \
        --region ${AWS_REGION} \
        --deployment-id ${DEPLOYMENT_ID} \
        --query 'deploymentInfo.status' \
        --output text)
    
    case $STATUS in
        "Succeeded")
            echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
            break
            ;;
        "Failed"|"Stopped")
            echo -e "${RED}❌ Deployment failed with status: ${STATUS}${NC}"
            exit 1
            ;;
        *)
            echo -e "${YELLOW}⏳ Deployment status: ${STATUS}${NC}"
            sleep 30
            ;;
    esac
done

echo -e "${GREEN}🌐 Frontend deployed successfully!${NC}"
echo -e "${GREEN}🔗 Application URL: http://sweetdream-alb-916164689.us-east-1.elb.amazonaws.com${NC}"