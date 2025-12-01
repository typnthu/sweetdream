#!/bin/bash
# Manual User Action Log Export Script
# Usage: 
#   ./manual-export-logs.sh backend test       # Export today's backend logs
#   ./manual-export-logs.sh backend production # Export yesterday's backend logs
#   ./manual-export-logs.sh order test         # Export today's order logs
#   ./manual-export-logs.sh order production   # Export yesterday's order logs

SERVICE=${1:-backend}
MODE=${2:-test}

echo "=== CloudWatch Logs to S3 Export ==="
echo "Service: $SERVICE"
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

if [ "$MODE" = "test" ]; then
    PAYLOAD='{"test_mode": true}'
    echo "Exporting TODAY's logs (test mode)..."
else
    PAYLOAD='{"test_mode": false}'
    echo "Exporting YESTERDAY's logs (production mode)..."
fi

echo "Invoking Lambda function: $LAMBDA_FUNCTION_NAME"
echo "Payload: $PAYLOAD"
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
    echo "✓ Export completed successfully"
else
    echo "✗ Export failed"
    exit 1
fi
