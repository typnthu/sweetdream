/**
 * Analytics Logger for Customer Behavior Tracking
 * 
 * Logs customer actions in a structured format that CloudWatch can export to S3
 * for analysis. All logs are automatically exported to S3 via scheduled Lambda exports.
 */

interface UserAction {
  userId?: number;
  userName?: string;
  sessionId?: string;
  action: string;
  metadata: Record<string, any>;
}

/**
 * Log a customer action for analytics
 */
export function logUserAction(data: UserAction): void {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level: 'info',
    category: 'user_action',
    message: data.action,
    userId: data.userId || null,
    userName: data.userName || null,
    sessionId: data.sessionId || null,
    metadata: data.metadata
  };

  // Log to stdout (CloudWatch captures this)
  console.log(JSON.stringify(logEntry));
}

/**
 * Log product view
 */
export function logProductView(params: {
  userId?: number;
  userName?: string;
  sessionId?: string;
  productId: number;
  productName: string;
  category: string;
  price: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    sessionId: params.sessionId,
    action: 'Product Viewed',
    metadata: {
      productId: params.productId,
      productName: params.productName,
      category: params.category,
      price: params.price
    }
  });
}

/**
 * Log add to cart
 */
export function logAddToCart(params: {
  userId: number;
  userName: string;
  sessionId?: string;
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
    sessionId: params.sessionId,
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
  sessionId?: string;
  query: string;
  resultsCount: number;
}): void {
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    sessionId: params.sessionId,
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
  userId: number;
  userName: string;
  sessionId?: string;
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
    sessionId: params.sessionId,
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
  userId: number;
  userName: string;
  sessionId?: string;
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
  paymentMethod?: string;
}): void {
  // Log overall order
  logUserAction({
    userId: params.userId,
    userName: params.userName,
    sessionId: params.sessionId,
    action: 'Order Completed',
    metadata: {
      orderId: params.orderId,
      itemCount: params.orderItems.length,
      totalAmount: params.totalAmount,
      paymentMethod: params.paymentMethod || 'unknown'
    }
  });

  // Log each product in the order (for product-level analytics)
  params.orderItems.forEach(item => {
    logUserAction({
      userId: params.userId,
      userName: params.userName,
      sessionId: params.sessionId,
      action: 'Order Completed',
      metadata: {
        orderId: params.orderId,
        productId: item.productId,
        productName: item.productName,
        category: item.category,
        size: item.size,
        quantity: item.quantity,
        price: item.price,
        totalAmount: item.price * item.quantity
      }
    });
  });
}

/**
 * Log cart abandonment (when user leaves without completing order)
 */
export function logCartAbandonment(params: {
  userId: number;
  userName: string;
  sessionId?: string;
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
    sessionId: params.sessionId,
    action: 'Cart Abandoned',
    metadata: {
      itemCount: params.cartItems.length,
      totalAmount: params.totalAmount,
      items: params.cartItems
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
