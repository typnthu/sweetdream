import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import Joi from 'joi';
import axios from 'axios';

dotenv.config();

const app = express();
const port = process.env.PORT || 3002;
const prisma = new PrismaClient();

// User service URL
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001';

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
    service: 'order-service',
    status: 'OK',
    timestamp: new Date().toISOString(),
    userServiceUrl: USER_SERVICE_URL
  });
});

// Validation schema
const orderSchema = Joi.object({
  customer: Joi.object({
    name: Joi.string().required(),
    email: Joi.string().email().required(),
    phone: Joi.string().optional().allow(''),
    address: Joi.string().optional().allow('')
  }).required(),
  items: Joi.array().items(
    Joi.object({
      productId: Joi.number().required(),
      size: Joi.string().required(),
      price: Joi.number().required(),
      quantity: Joi.number().min(1).required()
    })
  ).min(1).required(),
  notes: Joi.string().optional().allow('')
});

// Helper function to communicate with User Service
async function getOrCreateCustomer(customerData: any) {
  try {
    console.log(`🔗 Calling User Service: ${USER_SERVICE_URL}/api/customers/email/${customerData.email}`);
    
    // Try to get existing customer
    try {
      const response = await axios.get(
        `${USER_SERVICE_URL}/api/customers/email/${customerData.email}`
      );
      console.log('✅ Customer found in User Service');
      return response.data;
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Customer doesn't exist, create new one
        console.log('📝 Creating new customer in User Service');
        const createResponse = await axios.post(
          `${USER_SERVICE_URL}/api/customers`,
          customerData
        );
        console.log('✅ Customer created in User Service');
        return createResponse.data;
      }
      throw error;
    }
  } catch (error) {
    console.error('❌ Error communicating with User Service:', error);
    throw new Error('Failed to communicate with User Service');
  }
}

// Get all orders
app.get('/api/orders', async (req, res) => {
  try {
    const { status, page = 1, limit = 10, customerEmail } = req.query;
    
    const skip = (Number(page) - 1) * Number(limit);
    
    let where: any = status ? { status: status as any } : {};
    
    // Filter by customer email if provided
    if (customerEmail) {
      where.customer = {
        email: customerEmail as string
      };
    }
    
    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where,
        include: {
          customer: true,
          items: {
            include: {
              product: {
                include: {
                  sizes: true
                }
              }
            }
          }
        },
        orderBy: {
          createdAt: 'desc'
        },
        skip,
        take: Number(limit)
      }),
      prisma.order.count({ where })
    ]);

    res.json({
      orders,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Get order by ID
app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const order = await prisma.order.findUnique({
      where: { id: parseInt(id) },
      include: {
        customer: true,
        items: {
          include: {
            product: {
              include: {
                sizes: true
              }
            }
          }
        }
      }
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

// Create new order (with User Service communication)
app.post('/api/orders', async (req, res) => {
  try {
    const { error, value } = orderSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { customer: customerData, items, notes } = value;

    console.log('📦 Creating new order...');
    console.log('👤 Customer data:', customerData);

    // MICROSERVICE COMMUNICATION: Call User Service to get/create customer
    const customer = await getOrCreateCustomer(customerData);
    console.log('✅ Customer retrieved/created:', customer.id);

    // Calculate total
    let total = 0;
    for (const item of items) {
      const product = await prisma.product.findUnique({
        where: { id: item.productId },
        include: { sizes: true }
      });
      
      if (!product) {
        return res.status(400).json({ 
          error: `Product with ID ${item.productId} not found` 
        });
      }

      const size = product.sizes.find(s => s.size === item.size);
      if (!size) {
        return res.status(400).json({ 
          error: `Size ${item.size} not found for product ${product.name}` 
        });
      }

      total += Number(size.price) * item.quantity;
    }

    // Create order with items
    const order = await prisma.order.create({
      data: {
        customerId: customer.id,
        total,
        notes,
        items: {
          create: items.map((item: any) => ({
            productId: item.productId,
            size: item.size,
            price: item.price,
            quantity: item.quantity
          }))
        }
      },
      include: {
        customer: true,
        items: {
          include: {
            product: {
              include: {
                sizes: true
              }
            }
          }
        }
      }
    });

    console.log('✅ Order created successfully:', order.id);

    res.status(201).json({
      message: 'Order created successfully',
      order,
      servicesCommunication: {
        userService: 'Customer verified/created via User Service',
        orderService: 'Order created in Order Service'
      }
    });
  } catch (error: any) {
    console.error('Error creating order:', error);
    if (error.message === 'Failed to communicate with User Service') {
      return res.status(503).json({ 
        error: 'User Service unavailable. Please try again later.' 
      });
    }
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// Update order status
app.patch('/api/orders/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, isAdmin } = req.body;

    const validStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'DELIVERED', 'CANCELLED'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status', 
        validStatuses 
      });
    }

    // Get current order
    const currentOrder = await prisma.order.findUnique({
      where: { id: parseInt(id) }
    });

    if (!currentOrder) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Define status progression order
    const statusOrder: Record<string, number> = {
      'PENDING': 0,
      'CONFIRMED': 1,
      'PREPARING': 2,
      'READY': 3,
      'DELIVERED': 4,
      'CANCELLED': -1
    };

    const currentLevel = statusOrder[currentOrder.status];
    const newLevel = statusOrder[status];

    // Validation rules
    if (status === 'CANCELLED') {
      // Admin can cancel at any status
      if (!isAdmin) {
        // Regular users can only cancel if PENDING or CONFIRMED
        if (currentLevel > 1) {
          return res.status(403).json({ 
            error: 'Cannot cancel order after it has started processing',
            message: 'Đơn hàng đang được xử lý, vui lòng liên hệ: 0767218023'
          });
        }
      }
    } else if (currentOrder.status === 'CANCELLED') {
      return res.status(400).json({ 
        error: 'Cannot change status of cancelled order'
      });
    } else if (currentOrder.status === 'DELIVERED') {
      return res.status(400).json({ 
        error: 'Cannot change status of delivered order'
      });
    } else {
      // Enforce sequential progression (can only move to next status)
      if (newLevel !== currentLevel + 1) {
        return res.status(400).json({ 
          error: 'Invalid status transition',
          message: 'Phải tuân theo trình tự: Chờ xác nhận → Đã xác nhận → Đang chuẩn bị → Sẵn sàng giao → Đã giao',
          currentStatus: currentOrder.status,
          allowedNextStatus: Object.keys(statusOrder).find(key => statusOrder[key] === currentLevel + 1)
        });
      }
    }

    const order = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status },
      include: {
        customer: true,
        items: {
          include: {
            product: true
          }
        }
      }
    });

    res.json(order);
  } catch (error: any) {
    console.error('Error updating order status:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

// Cancel order (change status to CANCELLED)
app.post('/api/orders/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { isAdmin } = req.body;

    // Get current order
    const currentOrder = await prisma.order.findUnique({
      where: { id: parseInt(id) }
    });

    if (!currentOrder) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Check if order can be cancelled
    if (currentOrder.status === 'CANCELLED') {
      return res.status(400).json({ error: 'Order is already cancelled' });
    }

    if (currentOrder.status === 'DELIVERED') {
      return res.status(400).json({ error: 'Cannot cancel delivered order' });
    }

    // Regular users can only cancel PENDING or CONFIRMED orders
    if (!isAdmin && !['PENDING', 'CONFIRMED'].includes(currentOrder.status)) {
      return res.status(403).json({ 
        error: 'Cannot cancel order after it has started processing',
        message: 'Đơn hàng đang được xử lý, vui lòng liên hệ: 0767218023'
      });
    }

    // Update order status to CANCELLED
    const order = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'CANCELLED' },
      include: {
        customer: true,
        items: {
          include: {
            product: true
          }
        }
      }
    });

    res.json(order);
  } catch (error: any) {
    console.error('Error cancelling order:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to cancel order' });
  }
});

// Delete order (hard delete - admin only)
app.delete('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.order.delete({
      where: { id: parseInt(id) }
    });

    res.status(204).send();
  } catch (error: any) {
    console.error('Error deleting order:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to delete order' });
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
  console.log(`📦 Order Service running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`🔗 User Service URL: ${USER_SERVICE_URL}`);
});

export default app;
