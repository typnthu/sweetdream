const API_URL = '/api/proxy';

export async function getCart(token: string) {
  const res = await fetch(`${API_URL}/cart`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  if (!res.ok) throw new Error('Failed to fetch cart');
  return res.json();
}

export async function addToCart(token: string, item: {
  productId: number;
  size: string;
  quantity: number;
  price: number;
}) {
  const res = await fetch(`${API_URL}/cart/items`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(item)
  });
  if (!res.ok) throw new Error('Failed to add to cart');
  return res.json();
}

export async function updateCartItem(token: string, itemId: number, quantity: number) {
  const res = await fetch(`${API_URL}/cart/items/${itemId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({ quantity })
  });
  if (!res.ok) throw new Error('Failed to update cart item');
  return res.json();
}

export async function removeFromCart(token: string, itemId: number) {
  const res = await fetch(`${API_URL}/cart/items/${itemId}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  if (!res.ok) throw new Error('Failed to remove from cart');
  return res.json();
}

export async function clearCart(token: string) {
  const res = await fetch(`${API_URL}/cart`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  if (!res.ok) throw new Error('Failed to clear cart');
  return res.json();
}
