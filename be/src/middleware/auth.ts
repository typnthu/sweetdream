import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  const secret = process.env.JWT_SECRET || 'your-secret-key';
  
  jwt.verify(token, secret, (err: any, decoded: any) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token', details: err.message });
    }
    // User-service uses 'userId', map it to 'id' for consistency
    (req as any).user = {
      id: decoded.userId || decoded.id,
      email: decoded.email,
      // HARDCODED: admin@sweetdream.com is always ADMIN
      role: decoded.email === 'admin@sweetdream.com' ? 'ADMIN' : (decoded.role || 'CUSTOMER')
    };
    next();
  });
};
