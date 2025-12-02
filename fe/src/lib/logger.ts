// CloudWatch-compatible frontend logging utility
// Logs are sent to console and automatically captured by CloudWatch in production

type LogLevel = 'info' | 'warn' | 'error' | 'debug';
type LogCategory = 'user_action' | 'api_call' | 'error' | 'performance' | 'navigation';

interface LogData {
  level: LogLevel;
  category: LogCategory;
  message: string;
  userId?: number;
  sessionId?: string;
  url?: string;
  metadata?: Record<string, any>;
}

class Logger {
  private sessionId: string;

  constructor() {
    this.sessionId = this.getOrCreateSessionId();
    this.setupErrorHandlers();
  }

  private getOrCreateSessionId(): string {
    if (typeof window === 'undefined') return '';
    
    let sessionId = sessionStorage.getItem('log_session_id');
    if (!sessionId) {
      sessionId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      sessionStorage.setItem('log_session_id', sessionId);
    }
    return sessionId;
  }

  private getUserId(): number | undefined {
    if (typeof window === 'undefined') return undefined;
    
    try {
      const user = localStorage.getItem('sweetdream_user');
      if (user) {
        const userData = JSON.parse(user);
        return userData.id;
      }
    } catch (e) {
      // Ignore
    }
    return undefined;
  }

  private setupErrorHandlers() {
    if (typeof window === 'undefined') return;

    // Catch unhandled errors
    window.addEventListener('error', (event) => {
      this.error('Unhandled Error', {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error?.stack
      });
    });

    // Catch unhandled promise rejections
    window.addEventListener('unhandledrejection', (event) => {
      this.error('Unhandled Promise Rejection', {
        reason: event.reason,
        promise: String(event.promise)
      });
    });
  }

  private log(data: Partial<LogData>) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: data.level || 'info',
      category: data.category || 'user_action',
      message: data.message || '',
      userId: data.userId || this.getUserId(),
      sessionId: this.sessionId,
      url: data.url || (typeof window !== 'undefined' ? window.location.href : ''),
      metadata: data.metadata || {},
      service: 'sweetdream-frontend'
    };

    // Log to console in structured JSON format
    // CloudWatch will automatically capture these logs in production
    const logMethod = data.level === 'error' ? console.error : 
                     data.level === 'warn' ? console.warn : 
                     console.log;
    
    logMethod(JSON.stringify(logEntry));
  }

  // Public logging methods
  info(message: string, metadata?: Record<string, any>) {
    this.log({ level: 'info', category: 'user_action', message, metadata });
  }

  warn(message: string, metadata?: Record<string, any>) {
    this.log({ level: 'warn', category: 'user_action', message, metadata });
  }

  error(message: string, metadata?: Record<string, any>) {
    this.log({
      level: 'error',
      category: 'error',
      message,
      metadata
    });
  }

  debug(message: string, metadata?: Record<string, any>) {
    if (process.env.NODE_ENV === 'development') {
      this.log({ level: 'debug', category: 'user_action', message, metadata });
    }
  }

  // Specific event loggers
  userAction(action: string, metadata?: Record<string, any>) {
    this.log({
      level: 'info',
      category: 'user_action',
      message: action,
      metadata
    });
  }

  apiCall(method: string, url: string, statusCode: number, responseTime: number, metadata?: Record<string, any>) {
    this.log({
      level: statusCode >= 400 ? 'error' : 'info',
      category: 'api_call',
      message: `${method} ${url}`,
      metadata: {
        method,
        url,
        statusCode,
        responseTime,
        ...metadata
      }
    });
  }

  navigation(from: string, to: string) {
    this.log({
      level: 'info',
      category: 'navigation',
      message: `Navigated from ${from} to ${to}`,
      metadata: { from, to }
    });
  }

  performance(metric: string, value: number, metadata?: Record<string, any>) {
    this.log({
      level: 'info',
      category: 'performance',
      message: `${metric}: ${value}ms`,
      metadata: { metric, value, ...metadata }
    });
  }
}

// Export singleton instance
export const logger = new Logger();
