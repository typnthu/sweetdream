import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Joi from 'joi';

dotenv.config();

const app = express();
const port = process.env.PORT || 3003;
const prisma = new PrismaClient();

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    service: 'user-service',
    status: 'OK',
    timestamp: new Date().toISOString()
  });
});

// Validation schemas
const registerSchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  email: Joi.string().email().required(),
  password: Joi.string().required().min(6),
  phone: Joi.string().optional().allow('').max(20),
  address: Joi.string().optional().allow('').max(500)
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

const customerSchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  email: Joi.string().email().required(),
  phone: Joi.string().optional().allow('').max(20),
  address: Joi.string().optional().allow('').max(500)
});

// Register new user
app.post('/api/auth/register', async (req, res) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { name, email, password, phone, address } = value;

    // Check if user exists
    const existingUser = await prisma.customer.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = await prisma.customer.create({
      data: {
        name,
        email,
        password: hashedPassword,
        phone: phone || null,
        address: address || null
      }
    });

    // Generate JWT token with role (lowercase for frontend compatibility)
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        role: user.role.toLowerCase() // Convert ADMIN/CUSTOMER to admin/customer
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        address: user.address,
        role: user.role.toLowerCase() // Convert ADMIN/CUSTOMER to admin/customer
      },
      token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to register user' });
  }
});

// Login user
app.post('/api/auth/login', async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { email, password } = value;

    // Find user
    const user = await prisma.customer.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    if (user.password) {
      const isValidPassword = await bcrypt.compare(password, user.password);
      if (!isValidPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
    }
    // If no password stored (legacy users), accept any password for backward compatibility

    // Generate JWT token with role (lowercase for frontend compatibility)
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        role: user.role.toLowerCase() // Convert ADMIN/CUSTOMER to admin/customer
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        address: user.address,
        role: user.role.toLowerCase() // Convert ADMIN/CUSTOMER to admin/customer
      },
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Failed to login' });
  }
});

// Verify token (for other services to call)
app.post('/api/auth/verify', async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'Token required' });
    }

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || 'your-secret-key'
    ) as any;

    const user = await prisma.customer.findUnique({
      where: { id: decoded.userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      valid: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        address: user.address,
        role: user.role // Return role from database
      }
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ valid: false, error: 'Invalid token' });
  }
});

// Get all customers (admin)
app.get('/api/customers', async (req, res) => {
  try {
    const { page = 1, limit = 10, search } = req.query;
    
    const skip = (Number(page) - 1) * Number(limit);
    
    const where = search ? {
      OR: [
        { name: { contains: search as string } },
        { email: { contains: search as string } },
        { phone: { contains: search as string } }
      ]
    } : {};
    
    const [customers, total] = await Promise.all([
      prisma.customer.findMany({
        where,
        include: {
          _count: {
            select: { orders: true }
          }
        },
        orderBy: {
          createdAt: 'desc'
        },
        skip,
        take: Number(limit)
      }),
      prisma.customer.count({ where })
    ]);

    res.json({
      customers,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching customers:', error);
    res.status(500).json({ error: 'Failed to fetch customers' });
  }
});

// Get customer by ID
app.get('/api/customers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const customer = await prisma.customer.findUnique({
      where: { id: parseInt(id) },
      include: {
        orders: {
          include: {
            items: {
              include: {
                product: true
              }
            }
          },
          orderBy: {
            createdAt: 'desc'
          }
        }
      }
    });

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    res.json(customer);
  } catch (error) {
    console.error('Error fetching customer:', error);
    res.status(500).json({ error: 'Failed to fetch customer' });
  }
});

// Get customer by email
app.get('/api/customers/email/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const customer = await prisma.customer.findUnique({
      where: { email }
    });

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    res.json(customer);
  } catch (error) {
    console.error('Error fetching customer:', error);
    res.status(500).json({ error: 'Failed to fetch customer' });
  }
});

// Create customer (for order service to call)
app.post('/api/customers', async (req, res) => {
  try {
    const { error, value } = customerSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const customer = await prisma.customer.create({
      data: value
    });

    res.status(201).json(customer);
  } catch (error: any) {
    console.error('Error creating customer:', error);
    if (error.code === 'P2002') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    res.status(500).json({ error: 'Failed to create customer' });
  }
});

// Update customer
app.put('/api/customers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = customerSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const customer = await prisma.customer.update({
      where: { id: parseInt(id) },
      data: value
    });

    res.json(customer);
  } catch (error: any) {
    console.error('Error updating customer:', error);
    if (error.code === 'P2002') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Customer not found' });
    }
    res.status(500).json({ error: 'Failed to update customer' });
  }
});

// Update customer role (admin only)
app.patch('/api/customers/:id/role', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    // Validate role
    if (!role || !['CUSTOMER', 'ADMIN'].includes(role.toUpperCase())) {
      return res.status(400).json({ 
        error: 'Invalid role. Must be CUSTOMER or ADMIN' 
      });
    }

    const customer = await prisma.customer.update({
      where: { id: parseInt(id) },
      data: { role: role.toUpperCase() as 'CUSTOMER' | 'ADMIN' }
    });

    res.json({
      message: 'Role updated successfully',
      customer: {
        id: customer.id,
        email: customer.email,
        name: customer.name,
        role: customer.role
      }
    });
  } catch (error: any) {
    console.error('Error updating role:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Customer not found' });
    }
    res.status(500).json({ error: 'Failed to update role' });
  }
});

// Update customer role by email (admin only)
app.patch('/api/customers/email/:email/role', async (req, res) => {
  try {
    const { email } = req.params;
    const { role } = req.body;

    // Validate role
    if (!role || !['CUSTOMER', 'ADMIN'].includes(role.toUpperCase())) {
      return res.status(400).json({ 
        error: 'Invalid role. Must be CUSTOMER or ADMIN' 
      });
    }

    const customer = await prisma.customer.update({
      where: { email },
      data: { role: role.toUpperCase() as 'CUSTOMER' | 'ADMIN' }
    });

    res.json({
      message: 'Role updated successfully',
      customer: {
        id: customer.id,
        email: customer.email,
        name: customer.name,
        role: customer.role
      }
    });
  } catch (error: any) {
    console.error('Error updating role:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Customer not found' });
    }
    res.status(500).json({ error: 'Failed to update role' });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

app.listen(port, () => {
  console.log(`🔐 User Service running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
});

export default app;
