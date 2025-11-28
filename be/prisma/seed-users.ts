import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding users...');

  // Create mock users
  const users = [
    {
      name: "Nguyễn Văn A",
      email: "user@example.com",
      phone: "0123456789",
      address: "123 Đường ABC, Quận 1, TP.HCM",
      role: "CUSTOMER" as const
    },
    {
      name: "Admin",
      email: "admin@sweetdream.com",
      phone: "0987654321",
      address: "Cửa hàng SweetDream",
      role: "ADMIN" as const
    }
  ];

  for (const userData of users) {
    const existing = await prisma.customer.findUnique({
      where: { email: userData.email }
    });

    if (!existing) {
      const user = await prisma.customer.create({
        data: userData
      });
      console.log(`✅ Created user: ${user.name} (${user.email})`);
    } else {
      console.log(`⏭️  User already exists: ${userData.email}`);
    }
  }

  console.log('✅ Users seeded successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding users:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
