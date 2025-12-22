import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('[SEED] Checking admin user...');

  // Check if any admin exists
  const existingAdmin = await prisma.customer.findFirst({
    where: { role: 'ADMIN' }
  });

  if (existingAdmin) {
    console.log('[OK] Admin user already exists, skipping seed.');
    console.log('  Email:', existingAdmin.email);
    return; // Exit early
  }

  console.log('No admin found, creating default admin...');

  const adminEmail = 'admin@sweetdream.com';
  const adminPassword = 'admin123';
  const hashedPassword = await bcrypt.hash(adminPassword, 10);

  // Create admin user
  const admin = await prisma.customer.create({
    data: {
      name: 'Admin',
      email: adminEmail,
      password: hashedPassword,
      role: 'ADMIN'
    }
  });

  console.log('[OK] Admin user created');
  console.log('  ID:', admin.id);
  console.log('  Email:', admin.email);
  console.log('  Role:', admin.role);
  console.log('');
  console.log('Admin credentials:');
  console.log('  Email: admin@sweetdream.com');
  console.log('  Password: admin123');
}

main()
  .then(() => {
    console.log('[OK] Seeding complete');
  })
  .catch((e) => {
    console.error('Error seeding database:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
