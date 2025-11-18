const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

// Product data mapping - reads from prisma/products folder
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

async function getOrCreateCategory(categoryName) {
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
    console.log(`✅ Created category: ${categoryName}`);
  }

  return category;
}

async function seed() {
  console.log('🌱 Starting database seed...\n');

  try {
    // Clear existing data
    console.log('🗑️  Clearing existing data...');
    await prisma.orderItem.deleteMany({});
    await prisma.order.deleteMany({});
    await prisma.customer.deleteMany({});
    await prisma.productSize.deleteMany({});
    await prisma.product.deleteMany({});
    await prisma.category.deleteMany({});
    console.log('✅ Cleared existing data\n');

    let successCount = 0;
    let errorCount = 0;

    for (const { id, file } of productFiles) {
      try {
        const productPath = path.join(__dirname, file);

        if (!fs.existsSync(productPath)) {
          console.warn(`⚠️  Product file not found: ${productPath}`);
          errorCount++;
          continue;
        }

        const productData = JSON.parse(
          fs.readFileSync(productPath, 'utf-8')
        );

        console.log(`📦 Processing: ${productData.name} (ID: ${id})`);

        // Get or create category
        const category = await getOrCreateCategory(productData.category);

        // Create product with sizes
        const product = await prisma.product.create({
          data: {
            id: id,
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
          `✅ Created: ${product.name} (${product.category.name}) with ${product.sizes.length} sizes`
        );
        console.log(`   Image: ${product.img}`);
        successCount++;
      } catch (error) {
        console.error(`❌ Error processing product ${id}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 Seed Summary:');
    console.log(`✅ Success: ${successCount} products`);
    console.log(`❌ Errors: ${errorCount} products`);
    console.log('='.repeat(60));

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
    console.error('❌ Seed failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

seed()
  .then(() => {
    console.log('\n✅ Database seeded successfully!');
    console.log('📸 All products now have S3 image URLs');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Seed failed:', error);
    process.exit(1);
  });
