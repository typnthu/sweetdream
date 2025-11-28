import express from 'express';
import { prisma } from '../server';
import { validateOrder } from '../validators/order';

const router = express.Router();

// Get all orders
router.get('/', async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    
    const skip = (Number(page) - 1) * Number(limit);
    
    const where = status ? { status: status as any } : {};
    
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
router.get('/:id', async (req, res) => {
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

// Create new order
router.post('/', async (req, res) => {
  try {
    const { error, value } = validateOrder(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { customer, items, notes } = value;

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

    // Create or find customer
    let customerRecord = await prisma.customer.findUnique({
      where: { email: customer.email }
    });

    if (!customerRecord) {
      customerRecord = await prisma.customer.create({
        data: customer
      });
    } else {
      // Update customer info if provided
      customerRecord = await prisma.customer.update({
        where: { id: customerRecord.id },
        data: {
          name: customer.name,
          phone: customer.phone || customerRecord.phone,
          address: customer.address || customerRecord.address
        }
      });
    }

    // Create order with items
    const order = await prisma.order.create({
      data: {
        customerId: customerRecord.id,
        total,
        notes,
        items: {
          create: items.map(item => ({
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

    res.status(201).json({ order });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// Update order status
router.patch('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'DELIVERED', 'CANCELLED'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status', 
        validStatuses 
      });
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
  } catch (error) {
    console.error('Error updating order status:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

// Cancel order
router.post('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;

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

    res.json({ order });
  } catch (error) {
    console.error('Error cancelling order:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to cancel order' });
  }
});

// Delete order (Admin only)
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.order.delete({
      where: { id: parseInt(id) }
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting order:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.status(500).json({ error: 'Failed to delete order' });
  }
});

export default router;