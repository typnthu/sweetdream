import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Protect all /admin routes
  if (request.nextUrl.pathname.startsWith('/admin')) {
    // Get user from localStorage (stored by AuthContext)
    // Note: We can't access localStorage in middleware, so we check cookie
    const userCookie = request.cookies.get('sweetdream_user')?.value;
    
    if (!userCookie) {
      // Not logged in - redirect to login
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('redirect', request.nextUrl.pathname);
      return NextResponse.redirect(loginUrl);
    }
    
    try {
      const user = JSON.parse(userCookie);
      
      // Check if user is admin
      if (user.role !== 'admin') {
        // Not an admin - redirect to home with error
        return NextResponse.redirect(new URL('/?error=unauthorized', request.url));
      }
    } catch (error) {
      // Invalid cookie - redirect to login
      const loginUrl = new URL('/login', request.url);
      return NextResponse.redirect(loginUrl);
    }
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: '/admin/:path*',
};
