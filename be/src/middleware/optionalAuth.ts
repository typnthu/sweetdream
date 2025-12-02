import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import { prisma } from '../server';

/**
 * Optional authentication middleware
 * Extracts user info if token is present, but doesn't require it
 */
export const optionalAuth = async (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    // No token, continue without user info
    next();
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || 'your-secret-key';
    const decoded: any = jwt.verify(token, secret);
    
    // Get user details from database
    const userId = decoded.userId || decoded.id;
    if (userId) {
      const customer = await prisma.customer.findUnique({
        where: { id: userId },
        select: { id: true, name: true, email: true }
      });
      
      if (customer) {
        (req as any).user = customer;
      }
    }
  } catch (err) {
    // Invalid token, continue without user info
  }
  
  next();
};
