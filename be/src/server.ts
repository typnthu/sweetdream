import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

// Import routes
import productRoutes from './routes/products';
import categoryRoutes from './routes/categories';
import cartRoutes from './routes/cart';

// Import logging
import { cwLogger } from './utils/cloudwatchLogger';
import { requestLogger } from './middleware/requestLogger';

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3001;

// Initialize Prisma Client
export const prisma = new PrismaClient();

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use(requestLogger);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Admin endpoints for database operations (temporary - remove in production!)
app.post('/api/admin/migrate', async (req, res) => {
  try {
    console.log('Checking database connection...');
    
    // Test database connection
    await prisma.$connect();
    
    // Check if tables exist by trying to count products
    try {
      await prisma.product.count();
      res.json({ 
        success: true, 
        message: 'Database is already set up and accessible',
        note: 'Tables already exist. If you need to reset, use docker-compose down -v'
      });
    } catch (error) {
      // Tables don't exist, need to run migrations manually
      res.json({ 
        success: false, 
        message: 'Database tables not found',
        instructions: 'Run: docker-compose exec backend npx prisma db push --accept-data-loss'
      });
    }
  } catch (error: any) {
    console.error('Database check error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message,
      instructions: 'Check database connection and run migrations manually'
    });
  }
});

app.post('/api/admin/seed', async (req, res) => {
  try {
    console.log('Seeding database...');
    
    // Check if already seeded
    const productCount = await prisma.product.count();
    if (productCount > 0) {
      return res.json({ 
        success: true, 
        message: `Database already has ${productCount} products`,
        note: 'Skipping seed to avoid duplicates'
      });
    }

    // Run seed using ts-node
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    const { stdout, stderr } = await execPromise('npx ts-node prisma/seed.ts');
    
    console.log('Seed output:', stdout);
    if (stderr) console.error('Seed stderr:', stderr);
    
    const newCount = await prisma.product.count();
    res.json({ 
      success: true, 
      message: 'Database seeded successfully',
      productsCreated: newCount,
      output: stdout
    });
  } catch (error: any) {
    console.error('Seed error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message,
      stderr: error.stderr,
      instructions: 'Run: npm run seed'
    });
  }
});

// API Routes
// Note: Auth is handled by user-service (port 3003)
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', cartRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

// Error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

app.listen(port, () => {
  cwLogger.info('Server started', {
    port,
    environment: process.env.NODE_ENV || 'development',
    service: 'sweetdream-backend'
  });
  
  console.log(`🚀 Server running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;