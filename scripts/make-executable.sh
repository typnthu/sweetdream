#!/bin/bash

# Make all shell scripts executable
# Run this on Linux/Mac systems

echo "Making shell scripts executable..."

chmod +x scripts/*.sh

echo "Shell scripts are now executable:"
ls -la scripts/*.sh

echo ""
echo "You can now run:"
echo "  ./scripts/build-and-deploy.sh"
echo "  ./scripts/deploy-images.sh"
echo "  ./scripts/deploy-dev.sh"
echo "  ./scripts/deploy-prod.sh"
echo "  ./scripts/setup-s3-backends.sh"