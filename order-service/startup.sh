#!/bin/sh
set -e

echo "Starting order service..."

# Generate Prisma client (in case it's not up to date)
echo "Generating Prisma client..."
npx prisma generate

# Check if migrations folder exists
if [ -d "prisma/migrations" ] && [ "$(ls -A prisma/migrations)" ]; then
  echo "Running database migrations..."
  npx prisma migrate deploy
else
  echo "No migrations found, using db push (schema sync only)..."
  npx prisma db push --skip-generate
fi

# Order service doesn't need seeding - just start
echo "Starting application..."
exec node dist/server.js
