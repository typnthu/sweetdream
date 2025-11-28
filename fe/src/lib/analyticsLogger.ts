/**
 * Frontend Analytics Logger
 * 
 * Logs customer actions from the browser. These logs are sent to the backend
 * and then exported to S3 via CloudWatch for analysis.
 */

interface UserAction {
  userId?: number;
  userName?: string;
  sessionId?: string;
  action: string;
  metadata: Record<string, any>;
}

/**
 * Get or create session ID
 */
function getSessionId(): string {
  if (typeof window === 'undefined') return '';
  
  let sessionId = sessionStorage.getItem('analytics_session_id');
  if (!sessionId) {
    sessionId = `session_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    sessionStorage.setItem('analytics_session_id', sessionId);
  }
  return sessionId;
}

/**
 * Log a customer action
 */
function logUserAction(data: UserAction): void {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level: 'info',
    category: 'user_action',
    message: data.action,
    userId: data.userId || null,
    userName: data.userName || null,
    sessionId: data.sessionId || getSessionId(),
    metadata: data.metadata
  };

  // Log to console (CloudWatch captures this from container logs)
  console.log(JSON.stringify(logEntry));

  // Optional: Send to backend API for server-side logging
  // This ensures logs are captured even if browser console is not monitored
  if (typeof window !== 'undefined' && process.env.NODE_ENV === 'production') {
    fetch('/api/analytics/log', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(logEntry)
    }).catch(() => {
      // Silently fail - analytics shouldn't break the app
    });
  }
}

/**
 * Log product view
 */
export function logProductView(params: {
  userId?: number;
  userName?: string;
  productId: number;
  productName: string;
  category: string;
  price: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Product Viewed',
    metadata: {
      productId: params.productId,
      productName: params.productName,
      category: params.category,
      price: params.price,
      url: typeof window !== 'undefined' ? window.location.href : ''
    }
  });
}

/**
 * Log add to cart
 */
export function logAddToCart(params: {
  userId?: number;
  userName?: string;
  productId: number;
  productName: string;
  category: string;
  size: string;
  quantity: number;
  price: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Add to Cart',
    metadata: {
      productId: params.productId,
      productName: params.productName,
      category: params.category,
      size: params.size,
      quantity: params.quantity,
      price: params.price,
      totalPrice: params.price * params.quantity
    }
  });
}

/**
 * Log product search
 */
export function logProductSearch(params: {
  userId?: number;
  userName?: string;
  query: string;
  resultsCount: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Product Search',
    metadata: {
      query: params.query,
      resultsCount: params.resultsCount
    }
  });
}

/**
 * Log checkout started
 */
export function logCheckoutStarted(params: {
  userId?: number;
  userName?: string;
  cartItems: Array<{
    productId: number;
    productName: string;
    category: string;
    size: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Checkout Started',
    metadata: {
      itemCount: params.cartItems.length,
      totalAmount: params.totalAmount,
      items: params.cartItems
    }
  });
}

/**
 * Log order completed
 */
export function logOrderCompleted(params: {
  userId?: number;
  userName?: string;
  orderId: number;
  orderItems: Array<{
    productId: number;
    productName: string;
    category: string;
    size: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Order Completed',
    metadata: {
      orderId: params.orderId,
      itemCount: params.orderItems.length,
      totalAmount: params.totalAmount
    }
  });
}

/**
 * Log page view
 */
export function logPageView(params: {
  userId?: number;
  userName?: string;
  pageName: string;
  pageUrl?: string;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Page Viewed',
    metadata: {
      pageName: params.pageName,
      pageUrl: params.pageUrl || (typeof window !== 'undefined' ? window.location.href : ''),
      referrer: typeof document !== 'undefined' ? document.referrer : ''
    }
  });
}

/**
 * Log user registration
 */
export function logUserRegistration(params: {
  userId: number;
  userName: string;
  email: string;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'User Registered',
    metadata: {
      email: params.email,
      registrationDate: new Date().toISOString()
    }
  });
}

/**
 * Log user login
 */
export function logUserLogin(params: {
  userId: number;
  userName: string;
  email: string;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'User Login',
    metadata: {
      email: params.email,
      loginTime: new Date().toISOString()
    }
  });
}

/**
 * Log cart abandonment
 */
export function logCartAbandonment(params: {
  userId?: number;
  userName?: string;
  cartItems: Array<{
    productId: number;
    productName: string;
    size: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    action: 'Cart Abandoned',
    metadata: {
      itemCount: params.cartItems.length,
      totalAmount: params.totalAmount,
      items: params.cartItems
    }
  });
}
