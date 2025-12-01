#!/bin/bash

# Script to reset admin password in production database
# This connects to the user-service and resets the admin password

echo "🔐 Resetting admin password..."

# Get the user-service task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster sweetdream-cluster \
  --service-name sweetdream-service-user-service \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
  echo "❌ No running user-service task found"
  exit 1
fi

echo "✅ Found user-service task: $TASK_ARN"

# Execute the password reset command in the container
echo "🔄 Executing password reset..."

aws ecs execute-command \
  --cluster sweetdream-cluster \
  --task "$TASK_ARN" \
  --container sweetdream-user-service \
  --interactive \
  --command "npx prisma db seed"

echo "✅ Admin password reset complete!"
echo ""
echo "Admin credentials:"
echo "  Email: admin@sweetdream.com"
echo "  Password: admin123"
