// CloudWatch-compatible structured logging utility

interface LogMetadata {
  [key: string]: any;
}

class CloudWatchLogger {
  private serviceName: string;
  private environment: string;

  constructor() {
    this.serviceName = process.env.SERVICE_NAME || 'sweetdream-backend';
    this.environment = process.env.NODE_ENV || 'development';
  }

  private log(level: string, message: string, metadata?: LogMetadata) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      service: this.serviceName,
      environment: this.environment,
      message,
      ...metadata
    };

    // CloudWatch parses JSON logs automatically
    const logMethod = level === 'ERROR' ? console.error : 
                     level === 'WARN' ? console.warn : 
                     console.log;
    
    logMethod(JSON.stringify(logEntry));
  }

  info(message: string, metadata?: LogMetadata) {
    this.log('INFO', message, metadata);
  }

  warn(message: string, metadata?: LogMetadata) {
    this.log('WARN', message, metadata);
  }

  error(message: string, error?: Error | any, metadata?: LogMetadata) {
    this.log('ERROR', message, {
      error: error?.message,
      stack: error?.stack,
      ...metadata
    });
  }

  debug(message: string, metadata?: LogMetadata) {
    if (this.environment === 'development') {
      this.log('DEBUG', message, metadata);
    }
  }

  // Specific log types
  apiRequest(method: string, url: string, statusCode: number, responseTime: number, metadata?: LogMetadata) {
    this.log('INFO', 'API Request', {
      category: 'api_request',
      method,
      url,
      statusCode,
      responseTime,
      ...metadata
    });
  }

  userAction(userId: number | undefined, action: string, metadata?: LogMetadata) {
    this.log('INFO', 'User Action', {
      category: 'user_action',
      userId,
      action,
      ...metadata
    });
  }

  performance(metric: string, value: number, metadata?: LogMetadata) {
    this.log('INFO', 'Performance Metric', {
      category: 'performance',
      metric,
      value,
      unit: 'ms',
      ...metadata
    });
  }

  security(event: string, metadata?: LogMetadata) {
    this.log('WARN', 'Security Event', {
      category: 'security',
      event,
      ...metadata
    });
  }
}

export const cwLogger = new CloudWatchLogger();
