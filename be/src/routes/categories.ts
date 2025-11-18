import express from 'express';
import { prisma } from '../server';
import Joi from 'joi';

const router = express.Router();

// Validation schema
const categorySchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  description: Joi.string().optional().allow('').max(500)
});

// Get all categories
router.get('/', async (req, res) => {
  try {
    const categories = await prisma.category.findMany({
      include: {
        _count: {
          select: { products: true }
        }
      },
      orderBy: {
        name: 'asc'
      }
    });

    res.json(categories);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Get category by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const category = await prisma.category.findUnique({
      where: { id: parseInt(id) },
      include: {
        products: {
          include: {
            sizes: {
              orderBy: {
                price: 'asc'
              }
            }
          }
        }
      }
    });

    if (!category) {
      return res.status(404).json({ error: 'Category not found' });
    }

    res.json(category);
  } catch (error) {
    console.error('Error fetching category:', error);
    res.status(500).json({ error: 'Failed to fetch category' });
  }
});

// Create new category
router.post('/', async (req, res) => {
  try {
    const { error, value } = categorySchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const category = await prisma.category.create({
      data: value
    });

    res.status(201).json(category);
  } catch (error) {
    console.error('Error creating category:', error);
    if (error.code === 'P2002') {
      return res.status(409).json({ error: 'Category name already exists' });
    }
    res.status(500).json({ error: 'Failed to create category' });
  }
});

// Update category
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = categorySchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: error.details.map(d => d.message) 
      });
    }

    const category = await prisma.category.update({
      where: { id: parseInt(id) },
      data: value
    });

    res.json(category);
  } catch (error) {
    console.error('Error updating category:', error);
    if (error.code === 'P2002') {
      return res.status(409).json({ error: 'Category name already exists' });
    }
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Category not found' });
    }
    res.status(500).json({ error: 'Failed to update category' });
  }
});

// Delete category
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Check if category has products
    const productsCount = await prisma.product.count({
      where: { categoryId: parseInt(id) }
    });

    if (productsCount > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete category with existing products' 
      });
    }

    await prisma.category.delete({
      where: { id: parseInt(id) }
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting category:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Category not found' });
    }
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

export default router;