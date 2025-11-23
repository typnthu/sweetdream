import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

// Import routes
import productRoutes from './routes/products';
import categoryRoutes from './routes/categories';
import orderRoutes from './routes/orders';
import customerRoutes from './routes/customers';

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
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    console.log('Running database schema push...');
    // Use db push to create tables directly from schema
    const { stdout, stderr } = await execPromise('npx prisma db push --accept-data-loss');
    
    console.log('Schema push output:', stdout);
    if (stderr) console.error('Schema push stderr:', stderr);
    
    res.json({ 
      success: true, 
      message: 'Database schema created successfully',
      output: stdout 
    });
  } catch (error: any) {
    console.error('Schema push error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message,
      stderr: error.stderr 
    });
  }
});

app.post('/api/admin/seed', async (req, res) => {
  try {
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    console.log('Seeding database...');
    // Use the JavaScript version of seed file
    const { stdout, stderr } = await execPromise('node prisma/seed.js');
    
    console.log('Seed output:', stdout);
    if (stderr) console.error('Seed stderr:', stderr);
    
    res.json({ 
      success: true, 
      message: 'Database seeded successfully',
      output: stdout 
    });
  } catch (error: any) {
    console.error('Seed error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message,
      stderr: error.stderr 
    });
  }
});

// API Routes
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/customers', customerRoutes);

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
  console.log(`🚀 Server running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;