import express from 'express';
import { prisma } from '../server';
import { validateProduct } from '../validators/product';

const router = express.Router();

// Get all products with categories and sizes
router.get('/', async (req, res) => {
  try {
    const products = await prisma.product.findMany({
      include: {
        category: true,
        sizes: {
          orderBy: {
            price: 'asc'
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Get product by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const product = await prisma.product.findUnique({
      where: { id: parseInt(id) },
      include: {
        category: true,
        sizes: {
          orderBy: {
            price: 'asc'
          }
        }
      }
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json(product);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

// Get products by category
router.get('/category/:categoryId', async (req, res) => {
  try {
    const { categoryId } = req.params;
    
    const products = await prisma.product.findMany({
      where: { categoryId: parseInt(categoryId) },
      include: {
        category: true,
        sizes: {
          orderBy: {
            price: 'asc'
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(products);
  } catch (error) {
    console.error('Error fetching products by category:', error);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Create new product (Admin only - you can add auth middleware later)
router.post('/', async (req, res) => {
  try {
    const { error, value } = validateProduct(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { name, description, img, categoryId, sizes } = value;

    const product = await prisma.product.create({
      data: {
        name,
        description,
        img,
        categoryId,
        sizes: {
          create: sizes
        }
      },
      include: {
        category: true,
        sizes: true
      }
    });

    res.status(201).json(product);
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// Update product
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = validateProduct(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const { name, description, img, categoryId, sizes } = value;

    // Delete existing sizes and create new ones
    await prisma.productSize.deleteMany({
      where: { productId: parseInt(id) }
    });

    const product = await prisma.product.update({
      where: { id: parseInt(id) },
      data: {
        name,
        description,
        img,
        categoryId,
        sizes: {
          create: sizes
        }
      },
      include: {
        category: true,
        sizes: true
      }
    });

    res.json(product);
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// Delete product
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.product.delete({
      where: { id: parseInt(id) }
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

export default router;