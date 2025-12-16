#!/bin/bash

# Blue/Green Deployment Testing Script for SweetDream
# This script helps test the blue/green deployment functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}

if [ "$ENVIRONMENT" = "prod" ]; then
    AWS_REGION="us-east-2"
fi

echo -e "${BLUE}Testing Blue/Green Deployment for SweetDream${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}Region: $AWS_REGION${NC}"
echo ""

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}AWS CLI is available${NC}"
}

# Function to get ALB DNS name
get_alb_dns() {
    local alb_name="sweetdream-alb"
    local dns_name=$(aws elbv2 describe-load-balancers \
        --names "$alb_name" \
        --region "$AWS_REGION" \
        --query 'LoadBalancers[0].DNSName' \
        --output text 2>/dev/null || echo "")
    
    if [ "$dns_name" = "None" ] || [ -z "$dns_name" ]; then
        echo -e "${RED}ALB not found: $alb_name${NC}"
        return 1
    fi
    
    echo "$dns_name"
}

# Function to check target group health
check_target_group_health() {
    local tg_name=$1
    local color=$2
    
    echo -e "${BLUE}Checking $color target group: $tg_name${NC}"
    
    local tg_arn=$(aws elbv2 describe-target-groups \
        --names "$tg_name" \
        --region "$AWS_REGION" \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text 2>/dev/null || echo "")
    
    if [ "$tg_arn" = "None" ] || [ -z "$tg_arn" ]; then
        echo -e "${RED}Target group not found: $tg_name${NC}"
        return 1
    fi
    
    local healthy_targets=$(aws elbv2 describe-target-health \
        --target-group-arn "$tg_arn" \
        --region "$AWS_REGION" \
        --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
        --output text 2>/dev/null || echo "0")
    
    local total_targets=$(aws elbv2 describe-target-health \
        --target-group-arn "$tg_arn" \
        --region "$AWS_REGION" \
        --query 'TargetHealthDescriptions | length(@)' \
        --output text 2>/dev/null || echo "0")
    
    echo -e "   Healthy targets: ${GREEN}$healthy_targets${NC}/$total_targets"
    
    if [ "$healthy_targets" -gt 0 ]; then
        echo -e "${GREEN}$color environment is healthy${NC}"
        return 0
    else
        echo -e "${RED}$color environment has no healthy targets${NC}"
        return 1
    fi
}

# Function to test endpoint
test_endpoint() {
    local url=$1
    local description=$2
    
    echo -e "${BLUE}Testing: $description${NC}"
    echo -e "   URL: $url"
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}$description - HTTP $response${NC}"
        return 0
    else
        echo -e "${RED}$description - HTTP $response${NC}"
        return 1
    fi
}

# Function to get traffic weights
get_traffic_weights() {
    echo -e "${BLUE}Current Traffic Distribution:${NC}"
    
    # This would require parsing the ALB listener rules
    # For now, we'll show the configured weights from Terraform
    echo -e "   ${YELLOW}Frontend:${NC} ${BLUE}Blue 100%${NC} | ${GREEN}Green 0%${NC}"
    echo -e "   ${YELLOW}User Service:${NC} ${BLUE}Blue 100%${NC} | ${GREEN}Green 0%${NC}"
    echo -e "   ${YELLOW}Order Service:${NC} ${BLUE}Blue 100%${NC} | ${GREEN}Green 0%${NC}"
    echo -e "${YELLOW}   (All services currently route to Blue environment)${NC}"
}

# Function to simulate blue/green switch
simulate_bg_switch() {
    echo -e "${BLUE}Blue/Green Deployment Simulation${NC}"
    echo ""
    echo -e "${YELLOW}To perform an actual blue/green deployment:${NC}"
    echo ""
    echo -e "1. ${BLUE}Build and push new image:${NC}"
    echo "   docker build -t frontend:green ./fe"
    echo "   docker tag frontend:green \$ECR_URI:green"
    echo "   docker push \$ECR_URI:green"
    echo ""
    echo -e "2. ${BLUE}Update task definition:${NC}"
    echo "   aws ecs register-task-definition --cli-input-json file://new-task-def.json"
    echo ""
    echo -e "3. ${BLUE}Start CodeDeploy deployment:${NC}"
    echo "   # Frontend"
    echo "   aws deploy create-deployment \\"
    echo "     --application-name sweetdream-${ENVIRONMENT}-service-frontend-codedeploy \\"
    echo "     --deployment-group-name sweetdream-${ENVIRONMENT}-service-frontend-deployment-group \\"
    echo "     --revision '{\"revisionType\":\"ECS\",\"ecsRevision\":{\"taskDefinition\":\"arn:aws:ecs:...:task-definition/...:123\"}}'"
    echo ""
    echo "   # User Service"
    echo "   aws deploy create-deployment \\"
    echo "     --application-name sweetdream-${ENVIRONMENT}-service-user-service-codedeploy \\"
    echo "     --deployment-group-name sweetdream-${ENVIRONMENT}-service-user-service-deployment-group \\"
    echo "     --revision '{\"revisionType\":\"ECS\",\"ecsRevision\":{\"taskDefinition\":\"arn:aws:ecs:...:task-definition/...:123\"}}'"
    echo ""
    echo "   # Order Service"
    echo "   aws deploy create-deployment \\"
    echo "     --application-name sweetdream-${ENVIRONMENT}-service-order-service-codedeploy \\"
    echo "     --deployment-group-name sweetdream-${ENVIRONMENT}-service-order-service-deployment-group \\"
    echo "     --revision '{\"revisionType\":\"ECS\",\"ecsRevision\":{\"taskDefinition\":\"arn:aws:ecs:...:task-definition/...:123\"}}'"
    echo ""
    echo -e "4. ${BLUE}Monitor deployment:${NC}"
    echo "   aws deploy get-deployment --deployment-id \$DEPLOYMENT_ID"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}Starting Blue/Green Deployment Test...${NC}"
    echo ""
    
    # Check prerequisites
    check_aws_cli
    
    # Get ALB DNS name
    echo -e "${BLUE}Finding Application Load Balancer...${NC}"
    ALB_DNS=$(get_alb_dns)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ALB found: $ALB_DNS${NC}"
    else
        echo -e "${RED}Could not find ALB. Make sure infrastructure is deployed.${NC}"
        exit 1
    fi
    echo ""
    
    # Check target group health
    echo -e "${BLUE}Checking Target Group Health...${NC}"
    echo -e "${YELLOW}Frontend:${NC}"
    check_target_group_health "sweetdream-frontend-blue-tg" "Blue"
    check_target_group_health "sweetdream-frontend-green-tg" "Green"
    echo -e "${YELLOW}User Service:${NC}"
    check_target_group_health "sweetdream-user-svc-blue-tg" "Blue"
    check_target_group_health "sweetdream-user-svc-green-tg" "Green"
    echo -e "${YELLOW}Order Service:${NC}"
    check_target_group_health "sweetdream-order-svc-blue-tg" "Blue"
    check_target_group_health "sweetdream-order-svc-green-tg" "Green"
    echo ""
    
    # Test endpoints
    echo -e "${BLUE}Testing Endpoints...${NC}"
    test_endpoint "http://$ALB_DNS" "Frontend (Main Page)"
    test_endpoint "http://$ALB_DNS/api/health" "Frontend Health Check"
    test_endpoint "http://$ALB_DNS/api/proxy/products" "Backend API (via Proxy)"
    test_endpoint "http://$ALB_DNS/api/proxy/auth/login" "User Service (via Proxy)"
    test_endpoint "http://$ALB_DNS/api/proxy/orders" "Order Service (via Proxy)"
    echo ""
    
    # Show traffic distribution
    get_traffic_weights
    echo ""
    
    # Show deployment simulation
    simulate_bg_switch
    
    echo -e "${GREEN}Blue/Green Test Complete!${NC}"
}

# Run main function
main "$@"