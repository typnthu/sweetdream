import { NextRequest, NextResponse } from 'next/server';

// Microservices URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:3002';
const BACKEND_SERVICE_URL = process.env.BACKEND_API_URL || 'http://localhost:3003';

// Route requests to appropriate microservice
function getServiceUrl(path: string): string {
  // User/Customer routes go to User Service
  if (path.startsWith('customers') || path.startsWith('auth')) {
    return USER_SERVICE_URL;
  }
  
  // Order routes go to Order Service
  if (path.startsWith('orders')) {
    return ORDER_SERVICE_URL;
  }
  
  // Products and Categories go to Backend Service
  if (path.startsWith('products') || path.startsWith('categories')) {
    return BACKEND_SERVICE_URL;
  }
  
  // Default to Backend Service
  return BACKEND_SERVICE_URL;
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const resolvedParams = await params;
  return proxyRequest(request, resolvedParams.path, 'GET');
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const resolvedParams = await params;
  return proxyRequest(request, resolvedParams.path, 'POST');
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const resolvedParams = await params;
  return proxyRequest(request, resolvedParams.path, 'PUT');
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const resolvedParams = await params;
  return proxyRequest(request, resolvedParams.path, 'DELETE');
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const resolvedParams = await params;
  return proxyRequest(request, resolvedParams.path, 'PATCH');
}

async function proxyRequest(
  request: NextRequest,
  pathSegments: string[],
  method: string
) {
  try {
    // Construct the path
    const path = pathSegments.join('/');
    
    // Get the appropriate service URL
    const serviceUrl = getServiceUrl(path);
    const url = `${serviceUrl}/api/${path}`;
    
    console.log(`[Proxy] ${method} ${path} -> ${url}`);
    
    // Get query parameters
    const searchParams = request.nextUrl.searchParams;
    const queryString = searchParams.toString();
    const fullUrl = queryString ? `${url}?${queryString}` : url;

    // Prepare headers
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    // Copy relevant headers from original request
    const authHeader = request.headers.get('authorization');
    if (authHeader) {
      headers['Authorization'] = authHeader;
    }

    // Prepare request options
    const options: RequestInit = {
      method,
      headers,
    };

    // Add body for POST, PUT, PATCH requests
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      try {
        const body = await request.json();
        options.body = JSON.stringify(body);
      } catch (error) {
        // Body might be empty or not JSON
      }
    }

    // Make request to backend
    const response = await fetch(fullUrl, options);
    
    // Check if response is JSON
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      const data = await response.json();
      return NextResponse.json(data, { status: response.status });
    } else {
      // Not JSON, probably an error page
      const text = await response.text();
      console.error(`[Proxy] Non-JSON response from ${url}:`, text.substring(0, 200));
      return NextResponse.json(
        { error: `Service unavailable: ${serviceUrl}` },
        { status: 503 }
      );
    }
  } catch (error) {
    console.error('Proxy error:', error);
    return NextResponse.json(
      { error: 'Failed to proxy request to backend', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
