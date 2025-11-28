"use client";
import { createContext, useContext, useState, useEffect } from "react";
import { useAuth } from "./AuthContext";
import * as cartApi from "@/lib/cartApi";

type Product = {
  id: number;
  name: string;
  price: number;
  img: string;
  originalProductId?: number;
};

type CartItem = Product & { 
  qty: number;
  size?: string;
  cartItemId?: number;
};

type CartContextType = {
  cart: CartItem[];
  loading: boolean;
  addToCart: (item: Product, quantity?: number) => Promise<void>;
  removeFromCart: (id: number) => Promise<void>;
  clearCart: () => Promise<void>;
  updateQuantity: (id: number, qty: number) => Promise<void>;
  syncCart: () => Promise<void>;
};

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [cart, setCart] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(false);
  const { isAuthenticated, token } = useAuth();

  // Load cart on mount and when auth changes
  useEffect(() => {
    if (isAuthenticated && token) {
      syncCart();
    } else {
      // When not logged in, cart should be empty
      setCart([]);
      if (typeof window !== 'undefined') {
        localStorage.removeItem('cart');
      }
    }
  }, [isAuthenticated, token]);



  const syncCart = async () => {
    if (!token) return;
    
    try {
      setLoading(true);
      const data = await cartApi.getCart(token);
      
      // Transform backend data to frontend format
      const items = data.items?.map((item: any) => ({
        id: item.id,
        cartItemId: item.id,
        originalProductId: item.productId,
        name: `${item.product.name} - ${item.size}`,
        size: item.size,
        price: item.price,
        qty: item.quantity,
        img: item.product.img
      })) || [];
      
      setCart(items);
    } catch (error) {
      console.error('Failed to sync cart:', error);
      setCart([]);
    } finally {
      setLoading(false);
    }
  };

  const addToCart = async (item: Product, quantity: number = 1) => {
    if (!isAuthenticated || !token) {
      // Don't allow adding to cart when not logged in
      throw new Error('Please log in to add items to cart');
    }

    try {
      // Extract size from item name (format: "Product Name - Size")
      const size = item.name.includes(' - ') ? item.name.split(' - ')[1] : 'Default';
      
      await cartApi.addToCart(token, {
        productId: item.originalProductId || item.id,
        size,
        quantity,
        price: item.price
      });
      await syncCart();
    } catch (error) {
      console.error('Failed to add to cart:', error);
      throw error;
    }
  };



  const updateQuantity = async (id: number, qty: number) => {
    if (!isAuthenticated || !token) {
      throw new Error('Please log in to update cart');
    }

    try {
      const item = cart.find(i => i.id === id);
      if (item?.cartItemId) {
        await cartApi.updateCartItem(token, item.cartItemId, qty);
        await syncCart();
      }
    } catch (error) {
      console.error('Failed to update quantity:', error);
      throw error;
    }
  };



  const removeFromCart = async (id: number) => {
    if (!isAuthenticated || !token) {
      throw new Error('Please log in to remove items from cart');
    }

    try {
      const item = cart.find(i => i.id === id);
      if (item?.cartItemId) {
        await cartApi.removeFromCart(token, item.cartItemId);
        await syncCart();
      }
    } catch (error) {
      console.error('Failed to remove from cart:', error);
      throw error;
    }
  };

  const clearCart = async () => {
    if (!isAuthenticated || !token) {
      throw new Error('Please log in to clear cart');
    }

    try {
      await cartApi.clearCart(token);
      setCart([]);
    } catch (error) {
      console.error('Failed to clear cart:', error);
      throw error;
    }
  };

  return (
    <CartContext.Provider value={{ 
      cart, 
      loading,
      addToCart, 
      removeFromCart, 
      updateQuantity,
      clearCart,
      syncCart
    }}>
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) throw new Error("useCart must be used inside CartProvider");
  return context;
};
