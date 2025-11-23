/**
 * API Client for SweetDream Microservices
 * 
 * Routes requests to the appropriate microservice:
 * - User Service (3001): Authentication, Customer management
 * - Order Service (3002): Order processing
 * - Backend Service (3003): Products, Categories
 */

// Service URLs
const USER_SERVICE_URL = process.env.NEXT_PUBLIC_USER_SERVICE_URL || 'http://localhost:3001';
const ORDER_SERVICE_URL = process.env.NEXT_PUBLIC_ORDER_SERVICE_URL || 'http://localhost:3002';
const BACKEND_SERVICE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3003';

// Types
export interface ProductSize {
  id: number;
  size: string;
  price: number;
}

export interface Category {
  id: number;
  name: string;
  description?: string;
  _count?: {
    products: number;
  };
}

export interface Product {
  id: number;
  name: string;
  description: string;
  img: string;
  categoryId: number;
  category: Category;
  sizes: ProductSize[];
  createdAt: string;
  updatedAt: string;
}

export interface Customer {
  id: number;
  name: string;
  email: string;
  phone?: string;
  address?: string;
}

export interface OrderItem {
  id: number;
  productId: number;
  size: string;
  price: number;
  quantity: number;
  product: Product;
}

export interface Order {
  id: number;
  customerId: number;
  status: string;
  total: number;
  shipping: number;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  customer: Customer;
  items: OrderItem[];
}

// Error handling
class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}

async function fetchAPI<T>(serviceUrl: string, endpoint: string, options?: RequestInit): Promise<T> {
  try {
    const response = await fetch(`${serviceUrl}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new APIError(response.status, error.error || `HTTP ${response.status}`);
    }

    return response.json();
  } catch (error) {
    if (error instanceof APIError) {
      throw error;
    }
    const message = error instanceof Error ? error.message : 'Unknown error';
    throw new Error(`Failed to fetch ${endpoint}: ${message}`);
  }
}

// ============================================
// PRODUCTS API (Backend Service - Port 3003)
// ============================================

export async function getProducts(): Promise<Product[]> {
  return fetchAPI<Product[]>(BACKEND_SERVICE_URL, '/api/products');
}

export async function getProduct(id: number): Promise<Product> {
  return fetchAPI<Product>(BACKEND_SERVICE_URL, `/api/products/${id}`);
}

export async function getProductsByCategory(categoryId: number): Promise<Product[]> {
  return fetchAPI<Product[]>(BACKEND_SERVICE_URL, `/api/products/category/${categoryId}`);
}

// ============================================
// CATEGORIES API (Backend Service - Port 3003)
// ============================================

export async function getCategories(): Promise<Category[]> {
  return fetchAPI<Category[]>(BACKEND_SERVICE_URL, '/api/categories');
}

export async function getCategory(id: number): Promise<Category & { products: Product[] }> {
  return fetchAPI<Category & { products: Product[] }>(BACKEND_SERVICE_URL, `/api/categories/${id}`);
}

// ============================================
// ORDERS API (Order Service - Port 3002)
// ============================================

export async function createOrder(orderData: {
  customer: {
    name: string;
    email: string;
    phone: string;
    address: string;
  };
  items: Array<{
    productId: number;
    size: string;
    price: number;
    quantity: number;
  }>;
  notes?: string;
}): Promise<Order> {
  console.log('🔗 Creating order via Order Service:', ORDER_SERVICE_URL);
  return fetchAPI<Order>(ORDER_SERVICE_URL, '/api/orders', {
    method: 'POST',
    body: JSON.stringify(orderData),
  });
}

export async function getOrder(id: number): Promise<Order> {
  return fetchAPI<Order>(ORDER_SERVICE_URL, `/api/orders/${id}`);
}

export async function getOrders(params?: { status?: string; page?: number; limit?: number }): Promise<{
  orders: Order[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}> {
  const queryParams = new URLSearchParams();
  if (params?.status) queryParams.append('status', params.status);
  if (params?.page) queryParams.append('page', params.page.toString());
  if (params?.limit) queryParams.append('limit', params.limit.toString());
  
  const query = queryParams.toString();
  return fetchAPI<any>(ORDER_SERVICE_URL, `/api/orders${query ? '?' + query : ''}`);
}

// ============================================
// CUSTOMERS API (User Service - Port 3001)
// ============================================

export async function registerUser(userData: {
  name: string;
  email: string;
  password: string;
  phone?: string;
  address?: string;
}): Promise<{ user: Customer; token: string }> {
  console.log('🔗 Registering user via User Service:', USER_SERVICE_URL);
  return fetchAPI<any>(USER_SERVICE_URL, '/api/auth/register', {
    method: 'POST',
    body: JSON.stringify(userData),
  });
}

export async function loginUser(credentials: {
  email: string;
  password: string;
}): Promise<{ user: Customer; token: string }> {
  console.log('🔗 Logging in via User Service:', USER_SERVICE_URL);
  return fetchAPI<any>(USER_SERVICE_URL, '/api/auth/login', {
    method: 'POST',
    body: JSON.stringify(credentials),
  });
}

export async function getCustomerByEmail(email: string): Promise<Customer> {
  return fetchAPI<Customer>(USER_SERVICE_URL, `/api/customers/email/${encodeURIComponent(email)}`);
}

export async function getCustomers(params?: { page?: number; limit?: number; search?: string }): Promise<{
  customers: Customer[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}> {
  const queryParams = new URLSearchParams();
  if (params?.page) queryParams.append('page', params.page.toString());
  if (params?.limit) queryParams.append('limit', params.limit.toString());
  if (params?.search) queryParams.append('search', params.search);
  
  const query = queryParams.toString();
  return fetchAPI<any>(USER_SERVICE_URL, `/api/customers${query ? '?' + query : ''}`);
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

export function formatPrice(price: number): string {
  return price.toLocaleString('vi-VN') + 'đ';
}

export function getImageUrl(imagePath: string): string {
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  return imagePath;
}

export function groupProductsByCategory(products: Product[]): Record<string, Product[]> {
  return products.reduce((acc, product) => {
    const categoryName = product.category.name;
    if (!acc[categoryName]) {
      acc[categoryName] = [];
    }
    acc[categoryName].push(product);
    return acc;
  }, {} as Record<string, Product[]>);
}

export function getCheapestPrice(product: Product): number {
  if (!product.sizes || product.sizes.length === 0) return 0;
  return Math.min(...product.sizes.map(s => Number(s.price)));
}

export function getMostExpensivePrice(product: Product): number {
  if (!product.sizes || product.sizes.length === 0) return 0;
  return Math.max(...product.sizes.map(s => Number(s.price)));
}

// ============================================
// SERVICE HEALTH CHECKS
// ============================================

export async function checkServicesHealth(): Promise<{
  userService: boolean;
  orderService: boolean;
  backendService: boolean;
}> {
  const results = {
    userService: false,
    orderService: false,
    backendService: false,
  };

  try {
    await fetch(`${USER_SERVICE_URL}/health`);
    results.userService = true;
  } catch (e) {
    console.error('User Service unavailable');
  }

  try {
    await fetch(`${ORDER_SERVICE_URL}/health`);
    results.orderService = true;
  } catch (e) {
    console.error('Order Service unavailable');
  }

  try {
    await fetch(`${BACKEND_SERVICE_URL}/health`);
    results.backendService = true;
  } catch (e) {
    console.error('Backend Service unavailable');
  }

  return results;
}
