import express from 'express';
import { prisma } from '../server';
import Joi from 'joi';

const router = express.Router();

// Validation schema
const customerSchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  email: Joi.string().email().required(),
  phone: Joi.string().optional().allow('').max(20),
  address: Joi.string().optional().allow('').max(500)
});

// Get all customers
router.get('/', async (req, res) => {
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
router.get('/:id', async (req, res) => {
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
router.get('/email/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const customer = await prisma.customer.findUnique({
      where: { email },
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

// Create new customer
router.post('/', async (req, res) => {
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
  } catch (error) {
    console.error('Error creating customer:', error);
    if (error.code === 'P2002') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    res.status(500).json({ error: 'Failed to create customer' });
  }
});

// Update customer
router.put('/:id', async (req, res) => {
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
  } catch (error) {
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

// Delete customer
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Check if customer has orders
    const ordersCount = await prisma.order.count({
      where: { customerId: parseInt(id) }
    });

    if (ordersCount > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete customer with existing orders' 
      });
    }

    await prisma.customer.delete({
      where: { id: parseInt(id) }
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting customer:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Customer not found' });
    }
    res.status(500).json({ error: 'Failed to delete customer' });
  }
});

export default router;