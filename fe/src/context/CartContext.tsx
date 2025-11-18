"use client";
import { createContext, useContext, useState } from "react";

type Product = {
  id: number;
  name: string;
  price: number;
  img: string;
  originalProductId?: number; // Store original product ID for navigation
};

type CartItem = Product & { qty: number };

type CartContextType = {
  cart: CartItem[];
  addToCart: (item: Product, quantity?: number) => void;
  removeFromCart: (id: number) => void;
  clearCart: () => void;
 updateQuantity: (id: number, qty: number) => void;
};

const CartContext = createContext<CartContextType | undefined>(undefined);


export function CartProvider({ children }: { children: React.ReactNode }) {
  const [cart, setCart] = useState<CartItem[]>([]);

  const addToCart = (item: Product, quantity: number = 1) => {
    setCart((prev) => {
      const exist = prev.find((p) => p.id === item.id);

      if (exist) {
        return prev.map((p) =>
          p.id === item.id ? { ...p, qty: p.qty + quantity } : p
        );
      }

      return [...prev, { ...item, qty: quantity }];
    });
  };

  const removeFromCart = (id: number) => {
    setCart((prev) => prev.filter((item) => item.id !== id));
  };

  const clearCart = () => setCart([]);
  const updateQuantity = (id: number, qty: number) => {
  setCart((prev) =>
    prev.map((item) => (item.id === id ? { ...item, qty } : item))
  );
};

  return (
    <CartContext.Provider value={{ cart, addToCart, removeFromCart, clearCart, updateQuantity }}>
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) throw new Error("useCart must be used inside CartProvider");
  return context;
};
