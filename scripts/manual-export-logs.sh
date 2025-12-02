#!/bin/bash
# Manual User Action Log Export Script
# Usage: 
#   ./manual-export-logs.sh backend  # Export today's backend logs (00:00 to now)
#   ./manual-export-logs.sh order    # Export today's order logs (00:00 to now)

SERVICE=${1:-backend}

echo "=== CloudWatch Logs to S3 Export ==="
echo "Service: $SERVICE"
echo "Exporting today's logs (00:00 to now)..."
echo ""

# Lambda function names from Terraform
if [ "$SERVICE" = "backend" ]; then
    LAMBDA_FUNCTION_NAME="sweetdream-service-backend-export-logs"
elif [ "$SERVICE" = "order" ]; then
    LAMBDA_FUNCTION_NAME="sweetdream-service-order-service-export-logs"
else
    echo "Error: Invalid service. Use 'backend' or 'order'"
    exit 1
fi

# Payload (empty object, Lambda will use current time)
PAYLOAD='{}'

echo "Invoking Lambda function: $LAMBDA_FUNCTION_NAME"
echo ""

aws lambda invoke \
  --function-name "$LAMBDA_FUNCTION_NAME" \
  --payload "$PAYLOAD" \
  --cli-binary-format raw-in-base64-out \
  response.json

echo ""
echo "Response:"
cat response.json
echo ""

# Check if successful
if [ $? -eq 0 ]; then
    echo "[SUCCESS] Export completed successfully"
else
    echo "[FAILED] Export failed"
    exit 1
fi
