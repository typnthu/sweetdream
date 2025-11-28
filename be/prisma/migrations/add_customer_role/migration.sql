-- CreateEnum
CREATE TYPE "CustomerRole" AS ENUM ('CUSTOMER', 'ADMIN');

-- AlterTable
ALTER TABLE "customers" ADD COLUMN "role" "CustomerRole" NOT NULL DEFAULT 'CUSTOMER';

-- Update existing admin user
UPDATE "customers" SET "role" = 'ADMIN' WHERE "email" = 'admin@sweetdream.com';
