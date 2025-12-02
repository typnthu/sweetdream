import { NextResponse } from 'next/server';

export async function POST() {
  try {
    const backendUrl = process.env.BACKEND_API_URL || 'http://localhost:3001';
    
    const response = await fetch(`${backendUrl}/api/admin/seed`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json(
        { success: false, error: `Backend error: ${error}` },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Seed error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error',
        details: 'Failed to connect to backend service'
      },
      { status: 500 }
    );
  }
}
