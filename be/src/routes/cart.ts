import express from 'express';
import { prisma } from '../server';
import { authenticateToken } from '../middleware/auth';
import { logAddToCart } from '../utils/analyticsLogger';

const router = express.Router();

// Get user's cart
router.get('/', authenticateToken, async (req, res) => {
  try {
    const customerId = (req as any).user.id;

    let cart = await prisma.cart.findUnique({
      where: { customerId },
      include: {
        items: {
          include: {
            product: {
              include: {
                category: true,
                sizes: true
              }
            }
          }
        }
      }
    });

    if (!cart) {
      cart = await prisma.cart.create({
        data: { customerId },
        include: {
          items: {
            include: {
              product: {
                include: {
                  category: true,
                  sizes: true
                }
              }
            }
          }
        }
      });
    }

    res.json(cart);
  } catch (error) {
    console.error('Error fetching cart:', error);
    res.status(500).json({ error: 'Failed to fetch cart' });
  }
});

// Add item to cart
router.post('/items', authenticateToken, async (req, res) => {
  try {
    const customerId = (req as any).user.id;
    const { productId, size, quantity, price } = req.body;
    
    // Get user details for analytics
    const customer = await prisma.customer.findUnique({
      where: { id: customerId },
      select: { name: true }
    });
    const userName = customer?.name || 'Unknown';

    // Ensure numeric types
    const numericProductId = parseInt(productId);
    const numericQuantity = parseInt(quantity);
    const numericPrice = parseFloat(price);

    let cart = await prisma.cart.findUnique({ where: { customerId } });

    if (!cart) {
      cart = await prisma.cart.create({ data: { customerId } });
    }

    const existingItem = await prisma.cartItem.findUnique({
      where: {
        cartId_productId_size: {
          cartId: cart.id,
          productId: numericProductId,
          size
        }
      },
      include: {
        product: {
          include: {
            category: true
          }
        }
      }
    });

    let cartItem;
    let product;
    
    if (existingItem) {
      cartItem = await prisma.cartItem.update({
        where: { id: existingItem.id },
        data: { quantity: existingItem.quantity + numericQuantity },
        include: {
          product: {
            include: {
              category: true
            }
          }
        }
      });
      product = cartItem.product;
    } else {
      cartItem = await prisma.cartItem.create({
        data: {
          cartId: cart.id,
          productId: numericProductId,
          size,
          quantity: numericQuantity,
          price: numericPrice
        },
        include: {
          product: {
            include: {
              category: true
            }
          }
        }
      });
      product = cartItem.product;
    }

    // Log add to cart for analytics
    logAddToCart({
      userId: customerId,
      userName: userName,
      sessionId: req.headers['x-session-id'] as string,
      productId: product.id,
      productName: product.name,
      category: product.category.name,
      size: size,
      quantity: numericQuantity,
      price: numericPrice
    });

    res.json(cartItem);
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.status(500).json({ error: 'Failed to add to cart' });
  }
});

// Update cart item quantity
router.put('/items/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;

    const cartItem = await prisma.cartItem.update({
      where: { id: parseInt(id) },
      data: { quantity: parseInt(quantity) }
    });

    res.json(cartItem);
  } catch (error) {
    console.error('Error updating cart item:', error);
    res.status(500).json({ error: 'Failed to update cart item' });
  }
});

// Remove item from cart
router.delete('/items/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.cartItem.delete({
      where: { id: parseInt(id) }
    });

    res.json({ message: 'Item removed from cart' });
  } catch (error) {
    console.error('Error removing cart item:', error);
    res.status(500).json({ error: 'Failed to remove cart item' });
  }
});

// Clear cart
router.delete('/', authenticateToken, async (req, res) => {
  try {
    const customerId = (req as any).user.id;

    const cart = await prisma.cart.findUnique({ where: { customerId } });

    if (cart) {
      await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
    }

    res.json({ message: 'Cart cleared' });
  } catch (error) {
    console.error('Error clearing cart:', error);
    res.status(500).json({ error: 'Failed to clear cart' });
  }
});

export default router;
