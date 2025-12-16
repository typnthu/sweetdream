import { NextRequest, NextResponse } from 'next/server';

// Microservices URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3003';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:3002';
const BACKEND_SERVICE_URL = process.env.BACKEND_API_URL || 'http://localhost:3001';

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
  
  // Cart routes go to Backend Service
  if (path.startsWith('cart')) {
    return BACKEND_SERVICE_URL;
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
  const requestId = Math.random().toString(36).substring(7);
  const startTime = Date.now();
  
  // Construct the path
  const path = pathSegments.join('/');
  
  // Get the appropriate service URL
  const serviceUrl = getServiceUrl(path);
  const url = `${serviceUrl}/api/${path}`;
  
  // Get query parameters
  const searchParams = request.nextUrl.searchParams;
  const queryString = searchParams.toString();
  const fullUrl = queryString ? `${url}?${queryString}` : url;
  
  try {

    // Get client info
    const clientIP = request.headers.get('x-forwarded-for') || 
                    request.headers.get('x-real-ip') || 
                    'unknown';
    const userAgent = request.headers.get('user-agent') || 'unknown';

    console.log(`[Proxy:${requestId}] REQUEST START ${JSON.stringify({
      method,
      originalPath: path,
      targetUrl: fullUrl,
      serviceUrl,
      clientIP,
      userAgent: userAgent.substring(0, 100),
      hasAuth: !!request.headers.get('authorization'),
      queryParams: queryString || 'none',
      timestamp: new Date().toISOString()
    })}`);

    // Prepare headers
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      'X-Forwarded-For': clientIP,
    };

    // Copy relevant headers from original request
    const authHeader = request.headers.get('authorization');
    if (authHeader) {
      headers['Authorization'] = authHeader;
      console.log(`[Proxy:${requestId}] Auth header present: ${authHeader.substring(0, 20)}...`);
    }

    // Prepare request options
    const options: RequestInit = {
      method,
      headers,
    };

    let requestBody = null;
    // Add body for POST, PUT, PATCH requests
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      try {
        requestBody = await request.json();
        options.body = JSON.stringify(requestBody);
        console.log(`[Proxy:${requestId}] Request body: ${JSON.stringify({
          bodySize: JSON.stringify(requestBody).length,
          bodyKeys: Object.keys(requestBody || {}),
          // Don't log sensitive data like passwords
          sanitizedBody: sanitizeLogData(requestBody)
        })}`);
      } catch (error) {
        console.log(`[Proxy:${requestId}] No JSON body or empty body`);
      }
    }

    // Make request to backend
    console.log(`[Proxy:${requestId}] Making request to backend...`);
    const response = await fetch(fullUrl, options);
    const responseTime = Date.now() - startTime;
    
    console.log(`[Proxy:${requestId}] RESPONSE RECEIVED ${JSON.stringify({
      status: response.status,
      statusText: response.statusText,
      responseTime: `${responseTime}ms`,
      contentType: response.headers.get('content-type'),
      contentLength: response.headers.get('content-length'),
      headers: Object.fromEntries(response.headers.entries())
    })}`);
    
    // Check if response is JSON
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      const data = await response.json();
      
      // Log summary for large responses, full data for small ones
      const dataSize = JSON.stringify(data).length;
      const logData: Record<string, unknown> = {
        status: response.status,
        responseTime: `${responseTime}ms`,
        dataSize,
        dataKeys: typeof data === 'object' && data ? Object.keys(data) : 'not-object'
      };

      // Only log full data for small responses or specific endpoints
      if (dataSize < 1000 || path.includes('auth') || path.includes('orders')) {
        logData.sanitizedData = sanitizeLogData(data);
      } else if (Array.isArray(data)) {
        logData.itemCount = data.length;
        logData.sampleItem = data.length > 0 ? sanitizeLogData(data[0]) : null;
      } else {
        logData.dataPreview = 'Large response - data truncated for logging';
      }

      console.log(`[Proxy:${requestId}] SUCCESS ${JSON.stringify(logData)}`);
      
      return NextResponse.json(data, { status: response.status });
    } else {
      // Not JSON, probably an error page
      const text = await response.text();
      console.error(`[Proxy:${requestId}] NON-JSON RESPONSE ${JSON.stringify({
        status: response.status,
        contentType,
        responseTime: `${responseTime}ms`,
        textPreview: text.substring(0, 200),
        textLength: text.length,
        url: fullUrl
      })}`);
      
      return NextResponse.json(
        { 
          error: `Service unavailable: ${serviceUrl}`,
          requestId,
          details: `Received ${response.status} ${response.statusText}`
        },
        { status: 503 }
      );
    }
  } catch (error) {
    const responseTime = Date.now() - startTime;
    
    console.error(`[Proxy:${requestId}] PROXY ERROR ${JSON.stringify({
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
      responseTime: `${responseTime}ms`,
      url: fullUrl,
      method,
      path,
      serviceUrl,
      timestamp: new Date().toISOString()
    })}`);
    
    return NextResponse.json(
      { 
        error: 'Failed to proxy request to backend', 
        requestId,
        details: error instanceof Error ? error.message : 'Unknown error',
        serviceUrl,
        path
      },
      { status: 500 }
    );
  }
}

// Helper function to sanitize sensitive data from logs
function sanitizeLogData(data: unknown): unknown {
  if (!data || typeof data !== 'object') return data;
  
  const sensitiveKeys = ['password', 'token', 'secret', 'key', 'auth', 'credential'];
  const sanitized = { ...data as Record<string, unknown> };
  
  for (const key in sanitized) {
    if (sensitiveKeys.some(sensitive => key.toLowerCase().includes(sensitive))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof sanitized[key] === 'object') {
      sanitized[key] = sanitizeLogData(sanitized[key]);
    }
  }
  
  return sanitized;
}
