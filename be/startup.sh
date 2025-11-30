#!/bin/sh
set -e

echo "Starting backend service..."

# Run database migrations
echo "Running database migrations..."
npx prisma db push

# Always run seed (it will upsert, not duplicate)
echo "Running database seed..."
npx ts-node prisma/seed.ts || echo "Seeding failed, continuing anyway..."

# Start the application
echo "Starting application..."
exec node dist/server.js
