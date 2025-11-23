export async function POST() {
  try {
    console.log('Calling backend seed endpoint...');
    const response = await fetch('http://backend.sweetdream.local:3001/api/admin/seed', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    const data = await response.json();
    console.log('Seed response:', data);
    
    return Response.json(data);
  } catch (error: any) {
    console.error('Seed error:', error);
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
