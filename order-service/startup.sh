#!/bin/sh
set -e

echo "Starting order service..."

# Generate Prisma client (in case it's not up to date)
echo "Generating Prisma client..."
npx prisma generate

# Run database migrations (safe - preserves data)
echo "Running database migrations..."
npx prisma migrate deploy

# Start the application
echo "Starting application..."
exec node dist/server.js
