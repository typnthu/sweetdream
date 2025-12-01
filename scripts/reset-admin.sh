#!/bin/bash
# Quick script to reset admin password in user-service

echo "🔐 Resetting admin password in user-service..."

# Get RDS endpoint from Terraform
cd terraform
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null)
cd ..

if [ -z "$RDS_ENDPOINT" ]; then
  echo "❌ Could not get RDS endpoint from Terraform"
  exit 1
fi

echo "✅ RDS Endpoint: $RDS_ENDPOINT"

# Set DATABASE_URL for user-service
export DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/sweetdream"

# Run seed script
cd user-service
npm run seed

echo ""
echo "✅ Admin password has been reset!"
echo ""
echo "You can now login with:"
echo "  Email: admin@sweetdream.com"
echo "  Password: admin123"
