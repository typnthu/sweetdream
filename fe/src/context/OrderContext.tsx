"use client";
import { createContext, useContext, useState, ReactNode } from "react";

export type OrderStatus = "PLACED" | "CONFIRMED" | "PREPARING" | "DELIVERING" | "DELIVERED" | "CANCELLED";

export type OrderItem = {
  id: number;
  name: string;
  price: number;
  quantity: number;
  img: string;
  originalProductId?: number;
};

export type Customer = {
  name: string;
  email: string;
  phone: string;
  address: string;
};

export type Order = {
  id: number;
  orderNumber: string;
  date: string;
  status: OrderStatus;
  customer: Customer;
  items: OrderItem[];
  total: number;
  shipping: number;
  notes?: string;
  estimatedDelivery?: string;
  canCancel: boolean;
};

type OrderContextType = {
  orders: Order[];
  addOrder: (orderData: Omit<Order, 'id' | 'orderNumber' | 'date' | 'canCancel'>) => Order;
  updateOrderStatus: (orderId: number, status: OrderStatus) => void;
  cancelOrder: (orderId: number) => void;
  getOrderById: (orderId: number) => Order | undefined;
};

const OrderContext = createContext<OrderContextType | undefined>(undefined);

export function OrderProvider({ children }: { children: ReactNode }) {
  const [orders, setOrders] = useState<Order[]>([
    // Sample orders for demonstration
    {
      id: 1,
      orderNumber: "ORD-2024-001",
      date: "2024-01-15",
      status: "DELIVERED",
      total: 220000,
      shipping: 30000,
      canCancel: false,
      customer: {
        name: "Nguyễn Văn A",
        email: "nguyenvana@email.com",
        phone: "0123456789",
        address: "123 Đường ABC, Quận 1, TP.HCM"
      },
      items: [
        {
          id: 1,
          name: "Mousse Dâu - 16cm",
          price: 120000,
          quantity: 1,
          img: "/cake1.jpg",
          originalProductId: 1
        },
        {
          id: 2,
          name: "Bánh Kem Vanilla - 12cm",
          price: 85000,
          quantity: 1,
          img: "/cake3.jpg",
          originalProductId: 3
        }
      ]
    },
    {
      id: 2,
      orderNumber: "ORD-2024-002",
      date: "2024-01-14",
      status: "PREPARING",
      total: 150000,
      shipping: 30000,
      canCancel: false,
      customer: {
        name: "Trần Thị B",
        email: "tranthib@email.com",
        phone: "0987654321",
        address: "456 Đường XYZ, Quận 3, TP.HCM"
      },
      items: [
        {
          id: 3,
          name: "Tiramisu Cổ Điển - 16cm",
          price: 125000,
          quantity: 1,
          img: "/cake2.jpg",
          originalProductId: 2
        },
        {
          id: 4,
          name: "Bánh Mì Chocolate - Vừa",
          price: 35000,
          quantity: 1,
          img: "/cake4.jpg",
          originalProductId: 4
        }
      ]
    }
  ]);

  const generateOrderNumber = () => {
    const year = new Date().getFullYear();
    const timestamp = Date.now().toString().slice(-6);
    return `ORD-${year}-${timestamp}`;
  };

  const calculateEstimatedDelivery = () => {
    const now = new Date();
    const deliveryTime = new Date(now.getTime() + 4 * 60 * 60 * 1000); // 4 hours from now
    return deliveryTime.toLocaleString('vi-VN');
  };

  const canCancelOrder = (status: OrderStatus) => {
    // Can only cancel if status is PLACED or CONFIRMED (before PREPARING)
    return status === "PLACED" || status === "CONFIRMED";
  };

  const addOrder = (orderData: Omit<Order, 'id' | 'orderNumber' | 'date' | 'canCancel'>) => {
    const newOrder: Order = {
      ...orderData,
      id: Date.now(),
      orderNumber: generateOrderNumber(),
      date: new Date().toLocaleDateString('vi-VN'),
      canCancel: canCancelOrder(orderData.status),
      estimatedDelivery: calculateEstimatedDelivery()
    };

    setOrders(prev => [newOrder, ...prev]);
    return newOrder;
  };

  const updateOrderStatus = (orderId: number, status: OrderStatus) => {
    setOrders(prev => prev.map(order => 
      order.id === orderId 
        ? { 
            ...order, 
            status, 
            canCancel: canCancelOrder(status),
            estimatedDelivery: status === "PLACED" ? calculateEstimatedDelivery() : order.estimatedDelivery
          }
        : order
    ));
  };

  const cancelOrder = (orderId: number) => {
    setOrders(prev => prev.map(order => 
      order.id === orderId 
        ? { ...order, status: "CANCELLED" as OrderStatus, canCancel: false }
        : order
    ));
  };

  const getOrderById = (orderId: number) => {
    return orders.find(order => order.id === orderId);
  };

  return (
    <OrderContext.Provider value={{
      orders,
      addOrder,
      updateOrderStatus,
      cancelOrder,
      getOrderById
    }}>
      {children}
    </OrderContext.Provider>
  );
}

export const useOrders = () => {
  const context = useContext(OrderContext);
  if (!context) {
    throw new Error("useOrders must be used within OrderProvider");
  }
  return context;
};