/**
 * Test seed script - validates JSON files without database connection
 * Usage: npx ts-node prisma/test-seed.ts
 */

import * as fs from 'fs';
import * as path from 'path';

// Product data mapping
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
  img: string;
  category: string;
  description: string;
  sizes: Array<{ size: string; price: number }>;
}

async function testSeed() {
  console.log('🧪 Testing seed data (no database connection)...\n');

  let successCount = 0;
  let errorCount = 0;
  const categories = new Set<string>();

  for (const { id, file } of productFiles) {
    try {
      const productPath = path.join(__dirname, file);

      if (!fs.existsSync(productPath)) {
        console.error(`❌ File not found: ${productPath}`);
        errorCount++;
        continue;
      }

      const productData: ProductData = JSON.parse(
        fs.readFileSync(productPath, 'utf-8')
      );

      // Validate required fields
      if (!productData.id) {
        throw new Error('Missing id');
      }
      if (!productData.name) {
        throw new Error('Missing name');
      }
      if (!productData.img) {
        throw new Error('Missing img');
      }
      if (!productData.category) {
        throw new Error('Missing category');
      }
      if (!productData.sizes || productData.sizes.length === 0) {
        throw new Error('Missing or empty sizes');
      }

      // Validate S3 URL
      if (!productData.img.startsWith('https://sweetdream-products-data.s3')) {
        console.warn(`⚠️  Product ${id}: Image URL doesn't look like S3 URL`);
        console.warn(`   Current: ${productData.img}`);
      }

      // Validate sizes
      for (const size of productData.sizes) {
        if (!size.size || !size.price) {
          throw new Error('Invalid size data');
        }
      }

      categories.add(productData.category);

      console.log(`✅ Product ${id}: ${productData.name}`);
      console.log(`   Category: ${productData.category}`);
      console.log(`   Image: ${productData.img}`);
      console.log(`   Sizes: ${productData.sizes.length}`);
      
      successCount++;
    } catch (error: any) {
      console.error(`❌ Product ${id}: ${error.message}`);
      errorCount++;
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('📊 Validation Summary:');
  console.log(`✅ Valid: ${successCount} products`);
  console.log(`❌ Invalid: ${errorCount} products`);
  console.log('='.repeat(60));

  console.log('\n📂 Categories found:');
  categories.forEach((cat) => {
    const count = productFiles.filter((p) => {
      try {
        const data = JSON.parse(
          fs.readFileSync(path.join(__dirname, p.file), 'utf-8')
        );
        return data.category === cat;
      } catch {
        return false;
      }
    }).length;
    console.log(`  - ${cat}: ${count} products`);
  });

  if (errorCount > 0) {
    console.log('\n❌ Validation failed! Fix errors before deploying.');
    process.exit(1);
  } else {
    console.log('\n✅ All product data is valid!');
    console.log('📦 Ready to deploy and run seed in ECS.');
    process.exit(0);
  }
}

testSeed();
