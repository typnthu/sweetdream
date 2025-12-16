"use client";

import { useState, useEffect } from "react";

interface Order {
  id: number;
  status: string;
  total: number;
  shipping: number;
  notes?: string;
  createdAt: string;
  customer: {
    name: string;
    email: string;
    phone?: string;
    address?: string;
  };
  items: Array<{
    id: number;
    size: string;
    price: number;
    quantity: number;
    product: {
      name: string;
    };
  }>;
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    fetchOrders();
    
    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      fetchOrders();
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  async function fetchOrders() {
    try {
      setLoading(true);
      const response = await fetch("/api/proxy/orders?limit=100");
      const data = await response.json();
      // Handle both paginated and non-paginated responses
      setOrders(data.orders || data);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Failed to fetch orders:", error);
    } finally {
      setLoading(false);
    }
  }

  async function updateOrderStatus(orderId: number, newStatus: string) {
    try {
      // Convert lowercase status to UPPERCASE for backend
      const statusMap: Record<string, string> = {
        'pending': 'PENDING',
        'confirmed': 'CONFIRMED',
        'processing': 'PREPARING',
        'preparing': 'PREPARING',
        'shipping': 'READY',
        'ready': 'READY',
        'completed': 'DELIVERED',
        'delivered': 'DELIVERED',
        'cancelled': 'CANCELLED'
      };

      const backendStatus = statusMap[newStatus] || newStatus.toUpperCase();

      const response = await fetch(`/api/proxy/orders/${orderId}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: backendStatus, isAdmin: true }),
      });

      if (response.ok) {
        fetchOrders();
        alert("✅ Đã cập nhật trạng thái đơn hàng");
      } else {
        const error = await response.json();
        alert(`❌ Lỗi: ${error.message || error.error || 'Không thể cập nhật'}`);
      }
    } catch (error) {
      console.error('Update error:', error);
      alert("❌ Không thể cập nhật trạng thái");
    }
  }

  const getStatusColor = (status: string) => {
    const statusLower = status.toLowerCase();
    switch (statusLower) {
      case "pending": return "bg-yellow-100 text-yellow-800";
      case "confirmed": return "bg-blue-100 text-blue-800";
      case "preparing":
      case "processing": return "bg-purple-100 text-purple-800";
      case "ready":
      case "shipping": return "bg-indigo-100 text-indigo-800";
      case "delivered":
      case "completed": return "bg-green-100 text-green-800";
      case "cancelled": return "bg-red-100 text-red-800";
      default: return "bg-gray-100 text-gray-800";
    }
  };

  const getStatusText = (status: string) => {
    const statusLower = status.toLowerCase();
    const statusMap: Record<string, string> = {
      pending: "Chờ xác nhận",
      confirmed: "Đã xác nhận",
      preparing: "Đang chuẩn bị",
      processing: "Đang xử lý",
      ready: "Sẵn sàng giao",
      shipping: "Đang giao",
      delivered: "Đã giao",
      completed: "Hoàn thành",
      cancelled: "Đã hủy",
    };
    return statusMap[statusLower] || status;
  };

  // Get available status options based on current status
  const getAvailableStatuses = (currentStatus: string) => {
    const statusLower = currentStatus.toLowerCase();
    
    // Map database status to display status
    const statusMap: Record<string, number> = {
      'pending': 0,
      'confirmed': 1,
      'preparing': 2,
      'processing': 2,
      'ready': 3,
      'shipping': 3,
      'delivered': 4,
      'completed': 4,
      'cancelled': -1
    };

    const currentLevel = statusMap[statusLower] ?? 0;

    // Define available options
    const allStatuses = [
      { value: 'pending', label: 'Chờ xác nhận', level: 0 },
      { value: 'confirmed', label: 'Đã xác nhận', level: 1 },
      { value: 'preparing', label: 'Đang chuẩn bị', level: 2 },
      { value: 'ready', label: 'Sẵn sàng giao', level: 3 },
      { value: 'delivered', label: 'Đã giao', level: 4 },
      { value: 'cancelled', label: 'Đã hủy', level: -1 }
    ];

    // Filter available statuses - Admin can see all valid transitions
    return allStatuses.filter(status => {
      // Current status is always shown
      if (status.level === currentLevel) return true;
      
      // Admin can cancel at any status (except already cancelled/delivered)
      if (status.value === 'cancelled') {
        return currentLevel !== -1 && currentLevel !== 4;
      }
      
      // Can only move to next sequential status
      return status.level === currentLevel + 1;
    });
  };

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Quản lý đơn hàng</h1>
          <p className="text-sm text-gray-500 mt-1">
            Cập nhật lần cuối: {lastUpdated.toLocaleTimeString("vi-VN")} • Tự động làm mới mỗi 30s
          </p>
        </div>
        <div className="space-x-3">
          <button
            onClick={fetchOrders}
            disabled={loading}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
          >
            {loading ? "Đang tải..." : "🔄 Làm mới"}
          </button>
        </div>
      </div>

      {loading ? (
        <p className="text-center py-10">Đang tải...</p>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="bg-white rounded-lg shadow p-6">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-semibold">Đơn hàng #{order.id}</h3>
                  <p className="text-sm text-gray-500">
                    {new Date(order.createdAt).toLocaleString("vi-VN")}
                  </p>
                </div>
                <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(order.status)}`}>
                  {getStatusText(order.status)}
                </span>
              </div>

              <div className="grid md:grid-cols-2 gap-4 mb-4">
                <div>
                  <h4 className="font-semibold mb-2">Thông tin khách hàng</h4>
                  <p className="text-sm"><strong>Tên:</strong> {order.customer.name}</p>
                  <p className="text-sm"><strong>Email:</strong> {order.customer.email}</p>
                  {order.customer.phone && <p className="text-sm"><strong>SĐT:</strong> {order.customer.phone}</p>}
                  {order.customer.address && <p className="text-sm"><strong>Địa chỉ:</strong> {order.customer.address}</p>}
                </div>

                <div>
                  <h4 className="font-semibold mb-2">Chi tiết đơn hàng</h4>
                  {order.items.map((item) => (
                    <p key={item.id} className="text-sm">
                      {item.product.name} ({item.size}) x{item.quantity} - {Number(item.price).toLocaleString()} VND
                    </p>
                  ))}
                  <div className="mt-2 pt-2 border-t">
                    <p className="text-sm"><strong>Tạm tính:</strong> {Number(order.total).toLocaleString()} VND</p>
                    <p className="text-sm"><strong>Phí ship:</strong> {Number(order.shipping).toLocaleString()} VND</p>
                    <p className="text-sm font-bold"><strong>Tổng:</strong> {(Number(order.total) + Number(order.shipping)).toLocaleString()} VND</p>
                  </div>
                </div>
              </div>

              {order.notes && (
                <div className="mb-4">
                  <h4 className="font-semibold mb-1">Ghi chú:</h4>
                  <p className="text-sm text-gray-600">{order.notes}</p>
                </div>
              )}

              <div className="flex gap-2">
                {/* Disable dropdown if order is completed or cancelled */}
                {order.status.toLowerCase() === 'completed' || 
                 order.status.toLowerCase() === 'cancelled' || 
                 order.status.toLowerCase() === 'delivered' ? (
                  <div className="px-3 py-1 border rounded text-sm bg-gray-100 text-gray-600">
                    {getStatusText(order.status)} (Đã hoàn tất)
                  </div>
                ) : (
                  <>
                    <select
                      value={order.status.toLowerCase()}
                      onChange={(e) => updateOrderStatus(order.id, e.target.value)}
                      className="px-3 py-1 border rounded text-sm"
                    >
                      {getAvailableStatuses(order.status).map(status => (
                        <option key={status.value} value={status.value}>
                          {status.label}
                        </option>
                      ))}
                    </select>
                    {/* Admin can cancel at any status except cancelled/delivered */}
                    {order.status.toLowerCase() !== 'cancelled' && 
                     order.status.toLowerCase() !== 'delivered' && (
                      <button
                        onClick={() => {
                          if (confirm('Bạn có chắc chắn muốn hủy đơn hàng này?')) {
                            updateOrderStatus(order.id, 'cancelled');
                          }
                        }}
                        className="px-3 py-1 bg-red-500 text-white rounded text-sm hover:bg-red-600"
                      >
                        Hủy đơn
                      </button>
                    )}
                  </>
                )}
                <button
                  onClick={() => setSelectedOrder(order)}
                  className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                >
                  Chi tiết
                </button>
              </div>
            </div>
          ))}

          {orders.length === 0 && (
            <div className="text-center py-10 text-gray-500 bg-white rounded-lg">
              Chưa có đơn hàng nào
            </div>
          )}
        </div>
      )}

      <div className="mt-4 text-sm text-gray-600">
        Tổng số: <span className="font-semibold">{orders.length}</span> đơn hàng
      </div>
    </div>
  );
}
