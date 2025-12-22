import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

// Product data mapping - reads from prisma/products folder
// JSON files now contain S3 URLs directly in the img field
const productFiles = [
  { id: 1, file: './products/mousse/1.json' },
  { id: 2, file: './products/tiramisu/2.json' },
  { id: 3, file: './products/kem/3.json' },
  { id: 4, file: './products/bread/4.json' },
  { id: 5, file: './products/bread/5.json' },
  { id: 6, file: './products/bread/6.json' },
  { id: 7, file: './products/bread/7.json' },
  { id: 8, file: './products/mousse/8.json' },
  { id: 9, file: './products/mousse/9.json' },
  { id: 10, file: './products/mousse/10.json' },
  { id: 11, file: './products/kem/11.json' },
  { id: 12, file: './products/kem/12.json' },
  { id: 13, file: './products/kem/13.json' },
  { id: 14, file: './products/tiramisu/14.json' },
  { id: 15, file: './products/tiramisu/15.json' },
  { id: 16, file: './products/tiramisu/16.json' },
];

interface ProductData {
  id: number;
  name: string;
  img: string; // Full S3 URL from JSON
  category: string;
  description: string;
  sizes: Array<{ size: string; price: number }>;
}

async function getOrCreateCategory(categoryName: string) {
  let category = await prisma.category.findUnique({
    where: { name: categoryName },
  });

  if (!category) {
    category = await prisma.category.create({
      data: {
        name: categoryName,
        description: `Danh mục ${categoryName}`,
      },
    });
    console.log(`Created category: ${categoryName}`);
  }

  return category;
}

async function seed() {
  console.log('Starting database seed...\n');

  try {
    // Check if database already has products
    const existingProductCount = await prisma.product.count();
    
    if (existingProductCount > 0) {
      console.log(`[SEED] Database already has ${existingProductCount} products, skipping seed.`);
      console.log('  (Use npm run db:reset to clear and reseed)\n');
      return; // Exit early - don't seed
    }

    console.log('Database is empty, seeding products...\n');

    let successCount = 0;
    let errorCount = 0;

    for (const { id, file } of productFiles) {
      try {
        const productPath = path.join(__dirname, file);

        if (!fs.existsSync(productPath)) {
          console.warn(`Product file not found: ${productPath}`);
          errorCount++;
          continue;
        }

        const productData: ProductData = JSON.parse(
          fs.readFileSync(productPath, 'utf-8')
        );

        console.log(`[SEED] Processing: ${productData.name}`);

        // Get or create category
        const category = await getOrCreateCategory(productData.category);

        // Create product with sizes
        const product = await prisma.product.create({
          data: {
            name: productData.name,
            description: productData.description,
            img: productData.img,
            categoryId: category.id,
            sizes: {
              create: productData.sizes.map((size) => ({
                size: size.size,
                price: size.price,
              })),
            },
          },
          include: {
            sizes: true,
            category: true,
          },
        });

        console.log(
          `   [OK] Created: ${product.name} (${product.category.name}) with ${product.sizes.length} sizes`
        );
        successCount++;
      } catch (error: any) {
        console.error(`   [ERROR] Error processing product:`, error.message);
        errorCount++;
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('Seed Summary:');
    console.log(`[OK] Created: ${successCount} products`);
    console.log(`[ERROR] Errors: ${errorCount} products`);
    console.log('='.repeat(60));

    // Create default admin user (always upsert to ensure it exists)
    console.log('\n[SEED] Ensuring admin user exists...');
    const bcrypt = require('bcryptjs');
    const adminPassword = await bcrypt.hash('admin123', 10);
    
    const admin = await prisma.customer.upsert({
      where: { email: 'admin@sweetdream.com' },
      update: { 
        password: adminPassword,
        role: 'ADMIN',
        name: 'Admin'
      },
      create: {
        email: 'admin@sweetdream.com',
        password: adminPassword,
        name: 'Admin',
        role: 'ADMIN'
      }
    });
    console.log(`[OK] Admin user ready: ${admin.email}`);

    // Display categories
    const categories = await prisma.category.findMany({
      include: {
        _count: {
          select: { products: true },
        },
      },
    });

    console.log('\n📂 Categories:');
    categories.forEach((cat) => {
      console.log(`  - ${cat.name}: ${cat._count.products} products`);
    });

  } catch (error) {
    console.error('Seed failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

seed()
  .then(() => {
    console.log('\nDatabase seeded successfully!');
    console.log('All products now have S3 image URLs');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\nSeed failed:', error);
    process.exit(1);
  });
