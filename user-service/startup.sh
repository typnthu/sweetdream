#!/bin/sh
set -e

echo "Starting user service..."

# Generate Prisma client (in case it's not up to date)
echo "Generating Prisma client..."
npx prisma generate

# Run database migrations (safe - preserves data)
echo "Running database migrations..."
npx prisma migrate deploy

# Always run seed to ensure admin user exists with correct password
echo "Running database seed (creates/updates admin user)..."
npx ts-node prisma/seed.ts || echo "Seeding failed, continuing anyway..."

# Start the application
echo "Starting application..."
exec node dist/server.js
