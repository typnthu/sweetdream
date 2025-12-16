import { Request, Response, NextFunction } from 'express';
import { cwLogger } from '../utils/cloudwatchLogger';

// Helper function to sanitize sensitive data
function sanitizeData(data: any): any {
  if (!data || typeof data !== 'object') return data;
  
  const sensitiveKeys = ['password', 'token', 'secret', 'key', 'auth', 'credential'];
  const sanitized = { ...data };
  
  for (const key in sanitized) {
    if (sensitiveKeys.some(sensitive => key.toLowerCase().includes(sensitive))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof sanitized[key] === 'object') {
      sanitized[key] = sanitizeData(sanitized[key]);
    }
  }
  
  return sanitized;
}

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  const requestId = req.headers['x-request-id'] || Math.random().toString(36).substring(7);
  
  // Enhanced request logging
  const requestInfo: any = {
    requestId,
    method: req.method,
    url: req.url,
    path: req.path,
    query: req.query,
    ip: req.ip || req.socket.remoteAddress,
    userAgent: req.headers['user-agent'],
    contentType: req.headers['content-type'],
    contentLength: req.headers['content-length'],
    authorization: req.headers.authorization ? 'Bearer [PRESENT]' : 'none',
    referer: req.headers.referer,
    origin: req.headers.origin,
    timestamp: new Date().toISOString(),
    headers: {
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'x-real-ip': req.headers['x-real-ip'],
      'x-request-id': req.headers['x-request-id'],
      'accept': req.headers.accept,
      'accept-language': req.headers['accept-language']
    }
  };

  // Log request body for POST/PUT/PATCH (sanitized)
  if (['POST', 'PUT', 'PATCH'].includes(req.method) && req.body) {
    requestInfo.body = sanitizeData(req.body);
    requestInfo.bodySize = JSON.stringify(req.body).length;
  }

  console.log(`[Backend:${requestId}] REQUEST START ${JSON.stringify(requestInfo)}`);

  // Capture response
  const originalSend = res.send;
  const originalJson = res.json;
  
  res.send = function(data: any) {
    logResponse(data, false);
    return originalSend.call(this, data);
  };

  res.json = function(data: any) {
    logResponse(data, true);
    return originalJson.call(this, data);
  };

  function logResponse(data: any, isJson: boolean) {
    const responseTime = Date.now() - startTime;
    
    const responseInfo: any = {
      requestId,
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      statusMessage: res.statusMessage,
      responseTime: `${responseTime}ms`,
      contentType: res.getHeader('content-type'),
      isJson,
      dataSize: data ? (typeof data === 'string' ? data.length : JSON.stringify(data).length) : 0,
      timestamp: new Date().toISOString()
    };

    // Add response data for non-sensitive endpoints (limit large responses)
    if (res.statusCode < 400 && data && !req.url.includes('auth')) {
      const dataSize = responseInfo.dataSize;
      if (dataSize < 1000) {
        responseInfo.responseData = sanitizeData(data);
      } else if (Array.isArray(data)) {
        responseInfo.itemCount = data.length;
        responseInfo.sampleItem = data.length > 0 ? sanitizeData(data[0]) : null;
      } else {
        responseInfo.dataPreview = 'Large response - data truncated for logging';
      }
    }

    // Different log levels based on status
    if (res.statusCode >= 500) {
      console.error(`[Backend:${requestId}] SERVER ERROR ${JSON.stringify(responseInfo)}`);
    } else if (res.statusCode >= 400) {
      console.warn(`[Backend:${requestId}] CLIENT ERROR ${JSON.stringify(responseInfo)}`);
    } else {
      console.log(`[Backend:${requestId}] SUCCESS ${JSON.stringify(responseInfo)}`);
    }
    
    // Log to CloudWatch
    cwLogger.apiRequest(
      req.method,
      req.url,
      res.statusCode,
      responseTime,
      {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        userId: (req as any).user?.id,
        requestId,
        contentLength: responseInfo.dataSize,
        referer: req.headers.referer
      }
    );

    // Enhanced error logging
    if (res.statusCode >= 400) {
      cwLogger.error('API Error', undefined, {
        requestId,
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        responseTime,
        errorData: data,
        requestBody: sanitizeData(req.body),
        query: req.query,
        ip: req.ip,
        userAgent: req.headers['user-agent']
      });
    }
  }

  next();
};
