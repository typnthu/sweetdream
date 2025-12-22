#!/bin/sh

echo "Starting backend service..."

# Generate Prisma client (in case it's not up to date)
echo "Generating Prisma client..."
npx prisma generate

# Always use db push for existing databases (safe, preserves data)
echo "Syncing database schema..."
npx prisma db push --skip-generate

# Seed will check internally if data exists
echo "Running database seed (will skip if data exists)..."
npx ts-node prisma/seed.ts || echo "Seeding failed, continuing anyway..."

# Start the application
echo "Starting application..."
exec node dist/server.js
