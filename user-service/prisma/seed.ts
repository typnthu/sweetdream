import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding admin user...');

  const adminEmail = 'admin@sweetdream.com';
  const adminPassword = 'admin123';
  const hashedPassword = await bcrypt.hash(adminPassword, 10);

  // Use upsert to create or update admin user
  const admin = await prisma.customer.upsert({
    where: { email: adminEmail },
    update: {
      password: hashedPassword,
      role: 'ADMIN',
      name: 'Admin'
    },
    create: {
      name: 'Admin',
      email: adminEmail,
      password: hashedPassword,
      role: 'ADMIN'
    }
  });

  console.log('✓ Admin user ready');
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
    console.log('✓ Seeding complete');
  })
  .catch((e) => {
    console.error('Error seeding database:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
