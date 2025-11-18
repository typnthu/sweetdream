/**
 * API Client for SweetDream Backend
 * 
 * All data is fetched from the backend API.
 * No local JSON files are used.
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

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

async function fetchAPI<T>(endpoint: string, options?: RequestInit): Promise<T> {
  try {
    const response = await fetch(`${API_URL}${endpoint}`, {
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
// PRODUCTS API
// ============================================

/**
 * Get all products with categories and sizes
 */
export async function getProducts(): Promise<Product[]> {
  return fetchAPI<Product[]>('/api/products');
}

/**
 * Get a single product by ID
 */
export async function getProduct(id: number): Promise<Product> {
  return fetchAPI<Product>(`/api/products/${id}`);
}

/**
 * Get products by category ID
 */
export async function getProductsByCategory(categoryId: number): Promise<Product[]> {
  return fetchAPI<Product[]>(`/api/products/category/${categoryId}`);
}

// ============================================
// CATEGORIES API
// ============================================

/**
 * Get all categories with product counts
 */
export async function getCategories(): Promise<Category[]> {
  return fetchAPI<Category[]>('/api/categories');
}

/**
 * Get a single category with its products
 */
export async function getCategory(id: number): Promise<Category & { products: Product[] }> {
  return fetchAPI<Category & { products: Product[] }>(`/api/categories/${id}`);
}

// ============================================
// ORDERS API
// ============================================

/**
 * Create a new order
 */
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
  return fetchAPI<Order>('/api/orders', {
    method: 'POST',
    body: JSON.stringify(orderData),
  });
}

/**
 * Get order by ID
 */
export async function getOrder(id: number): Promise<Order> {
  return fetchAPI<Order>(`/api/orders/${id}`);
}

/**
 * Get orders by customer email
 */
export async function getOrdersByEmail(email: string): Promise<Order[]> {
  return fetchAPI<Order[]>(`/api/orders/customer/${encodeURIComponent(email)}`);
}

// ============================================
// CUSTOMERS API
// ============================================

/**
 * Get or create customer by email
 */
export async function getOrCreateCustomer(customerData: {
  name: string;
  email: string;
  phone?: string;
  address?: string;
}): Promise<Customer> {
  return fetchAPI<Customer>('/api/customers', {
    method: 'POST',
    body: JSON.stringify(customerData),
  });
}

/**
 * Get customer by email
 */
export async function getCustomerByEmail(email: string): Promise<Customer> {
  return fetchAPI<Customer>(`/api/customers/email/${encodeURIComponent(email)}`);
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Format price to Vietnamese currency
 */
export function formatPrice(price: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(price);
}

/**
 * Get product image URL (handles both local and S3 URLs)
 */
export function getImageUrl(imagePath: string): string {
  // If it's already a full URL (S3), return as is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  // Otherwise, it's a local path
  return imagePath;
}

/**
 * Group products by category
 */
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

/**
 * Get cheapest price for a product
 */
export function getCheapestPrice(product: Product): number {
  if (!product.sizes || product.sizes.length === 0) return 0;
  return Math.min(...product.sizes.map(s => Number(s.price)));
}

/**
 * Get most expensive price for a product
 */
export function getMostExpensivePrice(product: Product): number {
  if (!product.sizes || product.sizes.length === 0) return 0;
  return Math.max(...product.sizes.map(s => Number(s.price)));
}
