import { Request, Response, NextFunction } from 'express';
import { cwLogger } from '../utils/cloudwatchLogger';

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();

  // Capture response
  const originalSend = res.send;
  res.send = function(data: any) {
    const responseTime = Date.now() - startTime;
    
    // Log to CloudWatch
    cwLogger.apiRequest(
      req.method,
      req.url,
      res.statusCode,
      responseTime,
      {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        userId: (req as any).user?.id
      }
    );

    // Log errors separately
    if (res.statusCode >= 400) {
      cwLogger.error('API Error', undefined, {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        responseTime
      });
    }

    return originalSend.call(this, data);
  };

  next();
};
