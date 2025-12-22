#!/bin/sh
set -e

echo "Starting backend service..."

# Generate Prisma client (in case it's not up to date)
echo "Generating Prisma client..."
npx prisma generate

# Run database migrations (safe - preserves data)
echo "Running database migrations..."
npx prisma migrate deploy

# Always run seed (it will upsert, not duplicate)
echo "Running database seed..."
npx ts-node prisma/seed.ts || echo "Seeding failed, continuing anyway..."

# Start the application
echo "Starting application..."
exec node dist/server.js
