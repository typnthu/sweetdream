-- CreateEnum
CREATE TYPE "CustomerRole" AS ENUM ('CUSTOMER', 'ADMIN');

-- AlterTable
ALTER TABLE "customers" ADD COLUMN "role" "CustomerRole" NOT NULL DEFAULT 'CUSTOMER';

-- Insert or update admin user with password 'admin123'
-- Password hash generated with: bcrypt.hash('admin123', 10)
INSERT INTO "customers" ("name", "email", "password", "role", "createdAt", "updatedAt")
VALUES ('Admin', 'admin@sweetdream.com', '$2a$10$5jxvl6K31DwQqj.wQrA22ugDyp41haJ0yDIfaozUkpF1pbztHfGkq', 'ADMIN', NOW(), NOW())
ON CONFLICT ("email") 
DO UPDATE SET 
  "password" = '$2a$10$5jxvl6K31DwQqj.wQrA22ugDyp41haJ0yDIfaozUkpF1pbztHfGkq',
  "role" = 'ADMIN',
  "updatedAt" = NOW();
