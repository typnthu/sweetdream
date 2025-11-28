"use client";
import { useState, useEffect, Suspense } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "@/context/AuthContext";
import AuthGuard from "@/components/AuthGuard";

const getStatusColor = (status: string) => {
  const statusUpper = status.toUpperCase();
  switch (statusUpper) {
    case "PENDING": return "bg-yellow-100 text-yellow-800";
    case "CONFIRMED": return "bg-green-100 text-green-800";
    case "PREPARING": return "bg-orange-100 text-orange-800";
    case "READY": return "bg-purple-100 text-purple-800";
    case "DELIVERED": return "bg-emerald-100 text-emerald-800";
    case "CANCELLED": return "bg-red-100 text-red-800";
    default: return "bg-gray-100 text-gray-800";
  }
};

const getStatusText = (status: string) => {
  const statusUpper = status.toUpperCase();
  switch (statusUpper) {
    case "PENDING": return "Chờ xác nhận";
    case "CONFIRMED": return "Đã xác nhận";
    case "PREPARING": return "Đang chuẩn bị";
    case "READY": return "Sẵn sàng giao";
    case "DELIVERED": return "Đã giao thành công";
    case "CANCELLED": return "Đã hủy";
    default: return status;
  }
};

const canCancelOrder = (status: string) => {
  const statusUpper = status.toUpperCase();
  return statusUpper === "PENDING" || statusUpper === "CONFIRMED";
};

interface BackendOrder {
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
      img: string;
    };
  }>;
}

function SuccessContent() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<BackendOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<BackendOrder | null>(null);
  const [showOrderDetail, setShowOrderDetail] = useState(false);
  const searchParams = useSearchParams();
  const router = useRouter();

  // Check if coming from checkout success
  const orderId = searchParams.get('orderId');
  const isFromCheckout = searchParams.get('fromCheckout') === 'true';

  // Fetch orders from backend
  useEffect(() => {
    if (user?.email) {
      fetchOrders();
    } else if (user === null) {
      // User is not logged in, stop loading
      setLoading(false);
    }
  }, [user]);

  async function fetchOrders() {
    try {
      setLoading(true);
      const response = await fetch(`/api/proxy/orders?customerEmail=${user?.email}&limit=100`);
      const data = await response.json();
      setOrders(data.orders || []);
    } catch (error) {
      console.error('Failed to fetch orders:', error);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (orderId && isFromCheckout && orders.length > 0) {
      const order = orders.find(o => o.id === parseInt(orderId));
      if (order) {
        setSelectedOrder(order);
        setShowOrderDetail(true);
      }
    }
  }, [orderId, isFromCheckout, orders]);

  const handleViewOrderDetail = (order: BackendOrder) => {
    setSelectedOrder(order);
    setShowOrderDetail(true);
  };

  const handleCancelOrder = async (orderId: number) => {
    if (confirm("Bạn có chắc chắn muốn hủy đơn hàng này?")) {
      try {
        const response = await fetch(`/api/proxy/orders/${orderId}/cancel`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ isAdmin: false })
        });

        if (response.ok) {
          alert("✅ Đã hủy đơn hàng thành công");
          fetchOrders(); // Refresh orders
          if (selectedOrder && selectedOrder.id === orderId) {
            setSelectedOrder({ ...selectedOrder, status: "CANCELLED" });
          }
        } else {
          const error = await response.json();
          alert(`❌ ${error.message || error.error || 'Không thể hủy đơn hàng'}`);
        }
      } catch (error) {
        console.error('Cancel error:', error);
        alert("❌ Không thể hủy đơn hàng");
      }
    }
  };

  const closeOrderDetail = () => {
    setShowOrderDetail(false);
    setSelectedOrder(null);
    // Remove query parameters
    router.replace('/success');
  };

  return (
    <AuthGuard>
      <div className="p-6 max-w-5xl mx-auto">
      {isFromCheckout && selectedOrder ? (
        // Success message when coming from checkout
        <div className="text-center mb-8 bg-green-50 p-6 rounded-lg">
          <div className="text-green-500 text-6xl mb-4">✅</div>
          <h1 className="text-3xl font-bold text-green-600 mb-2">
            Đặt hàng thành công!
          </h1>
          <p className="text-gray-600 mb-4">
            Cảm ơn bạn đã mua hàng. Đơn hàng #{selectedOrder.id} đã được tạo thành công.
          </p>
        </div>
      ) : (
        <div className="mb-8">
          <p className="text-2xl font-bold mb-8 text-pink-500"> Đơn hàng của bạn</p>
        </div>
      )}

      {/* Orders List */}
      {loading ? (
        <div className="text-center py-12">
          <p className="text-gray-500">Đang tải đơn hàng...</p>
        </div>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="bg-white border rounded-lg p-6 hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-semibold text-gray-800">
                    Đơn hàng #{order.id}
                  </h3>
                  <p className="text-sm text-gray-500">Ngày đặt: {new Date(order.createdAt).toLocaleDateString('vi-VN')}</p>
                </div>
                <div className="text-right">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(order.status)}`}>
                    {getStatusText(order.status)}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div>
                  <h4 className="font-medium text-gray-700 mb-2">Thông tin khách hàng:</h4>
                  <p className="text-sm text-gray-600">{order.customer.name}</p>
                  <p className="text-sm text-gray-600">{order.customer.email}</p>
                  <p className="text-sm text-gray-600">{order.customer.phone}</p>
                </div>
                <div>
                  <h4 className="font-medium text-gray-700 mb-2">Địa chỉ giao hàng:</h4>
                  <p className="text-sm text-gray-600">{order.customer.address}</p>
                </div>
              </div>

              <div className="flex justify-between items-center">
                <div>
                  <p className="text-sm text-gray-600">
                    {order.items.length} sản phẩm • Tổng: <span className="font-semibold text-pink-600">
                      {(Number(order.total) + Number(order.shipping)).toLocaleString()} VND
                    </span>
                  </p>
                </div>
                <div className="flex gap-2">
                  {canCancelOrder(order.status) && (
                    <button
                      onClick={() => handleCancelOrder(order.id)}
                      className="bg-red-500 text-white px-3 py-2 rounded-lg hover:bg-red-600 transition text-sm"
                    >
                      Hủy đơn
                    </button>
                  )}
                  <button
                    onClick={() => handleViewOrderDetail(order)}
                    className="bg-pink-600 text-white px-4 py-2 rounded-lg hover:bg-pink-700 transition"
                  >
                    Xem chi tiết
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {orders.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 text-xl mb-4">Chưa có đơn hàng nào</p>
          <Link
            href="/"
            className="bg-white text-pink-500 px-3 py-3 rounded-lg hover:text-pink-700 transition"
          >
            Bắt đầu mua sắm
          </Link>
        </div>
      )}

      {/* Order Detail Modal */}
      {showOrderDetail && selectedOrder && (
        <div className="fixed inset-0 bg-gray-900/40 bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="p-6 border-b bg-pink-50">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-gray-800">
                    Chi tiết đơn hàng #{selectedOrder.id}
                  </h2>
                  <p className="text-sm text-gray-600">Ngày đặt: {new Date(selectedOrder.createdAt).toLocaleDateString('vi-VN')}</p>
                </div>
                <button
                  onClick={closeOrderDetail}
                  className="text-gray-400 hover:text-gray-600 text-2xl"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Modal Content */}
            <div className="p-6 max-h-96 overflow-y-auto">
              {/* Status & Actions */}
              <div className="mb-6 flex justify-between items-center">
                <div>
                  <span className={`px-4 py-2 rounded-full text-sm font-medium ${getStatusColor(selectedOrder.status)}`}>
                    {getStatusText(selectedOrder.status)}
                  </span>
                </div>
                {canCancelOrder(selectedOrder.status) && (
                  <button
                    onClick={() => handleCancelOrder(selectedOrder.id)}
                    className="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition text-sm"
                  >
                    Hủy đơn hàng
                  </button>
                )}
              </div>

              {/* Order Process */}
              <div className="mb-6">
                <h3 className="font-semibold text-gray-800 mb-3">Quy trình đơn hàng</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="space-y-2 text-sm">
                    <div className={`flex items-center ${selectedOrder.status.toUpperCase() === "PENDING" ? "text-blue-600 font-medium" : selectedOrder.status.toUpperCase() !== "CANCELLED" ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      1. Chờ xác nhận - {selectedOrder.status.toUpperCase() === "PENDING" ? "Đang chờ xác nhận" : "Hoàn thành"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status.toUpperCase() === "CONFIRMED" ? "text-blue-600 font-medium" : ["PREPARING", "READY", "DELIVERED"].includes(selectedOrder.status.toUpperCase()) ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      2. Đã xác nhận - {selectedOrder.status.toUpperCase() === "CONFIRMED" ? "Đã xác nhận, chuẩn bị làm bánh" : ["PREPARING", "READY", "DELIVERED"].includes(selectedOrder.status.toUpperCase()) ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status.toUpperCase() === "PREPARING" ? "text-blue-600 font-medium" : ["READY", "DELIVERED"].includes(selectedOrder.status.toUpperCase()) ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      3. Đang chuẩn bị - {selectedOrder.status.toUpperCase() === "PREPARING" ? "Đang làm bánh" : ["READY", "DELIVERED"].includes(selectedOrder.status.toUpperCase()) ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status.toUpperCase() === "READY" ? "text-blue-600 font-medium" : selectedOrder.status.toUpperCase() === "DELIVERED" ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      4. Sẵn sàng giao - {selectedOrder.status.toUpperCase() === "READY" ? "Shipper đang giao" : selectedOrder.status.toUpperCase() === "DELIVERED" ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status.toUpperCase() === "DELIVERED" ? "text-green-600 font-medium" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      5. Đã giao - {selectedOrder.status.toUpperCase() === "DELIVERED" ? "Đã giao thành công" : "Chờ xử lý"}
                    </div>
                  </div>
                  
                  {canCancelOrder(selectedOrder.status) && (
                    <div className="mt-3 p-3 bg-yellow-50 rounded border-l-4 border-yellow-400">
                      <p className="text-sm text-yellow-700">
                        <strong>Lưu ý:</strong> Bạn có thể hủy đơn hàng khi đang chờ xác nhận hoặc đã xác nhận. 
                        Sau khi bắt đầu chuẩn bị, vui lòng liên hệ trực tiếp: <strong>0767218023</strong>
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Customer Info */}
              <div className="mb-6">
                <h3 className="font-semibold text-gray-800 mb-3">Thông tin khách hàng</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p><strong>Tên:</strong> {selectedOrder.customer.name}</p>
                  <p><strong>Email:</strong> {selectedOrder.customer.email}</p>
                  <p><strong>Điện thoại:</strong> {selectedOrder.customer.phone}</p>
                  <p><strong>Địa chỉ:</strong> {selectedOrder.customer.address}</p>
                </div>
              </div>

              {/* Order Items */}
              <div className="mb-6">
                <h3 className="font-semibold text-gray-800 mb-3">Sản phẩm đã đặt</h3>
                {selectedOrder.items.map((item) => (
                  <div key={item.id} className="flex items-center gap-4 p-3 border rounded-lg mb-3">
                    <Image
                      src={item.product.img}
                      alt={item.product.name}
                      width={60}
                      height={60}
                      className="rounded-lg object-cover"
                    />
                    <div className="flex-1">
                      <p className="font-medium text-gray-800">{item.product.name} ({item.size})</p>
                      <p className="text-sm text-gray-600">Số lượng: {item.quantity}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-pink-600">
                        {(Number(item.price) * item.quantity).toLocaleString()} VND
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Order Summary */}
              <div className="border-t pt-4">
                <div className="space-y-2">
                  <div className="flex justify-between text-gray-600">
                    <span>Tạm tính:</span>
                    <span>{Number(selectedOrder.total).toLocaleString()} VND</span>
                  </div>
                  <div className="flex justify-between text-gray-600">
                    <span>Phí vận chuyển:</span>
                    <span>{Number(selectedOrder.shipping).toLocaleString()} VND</span>
                  </div>
                  <div className="flex justify-between text-lg font-bold text-pink-600 border-t pt-2">
                    <span>Tổng cộng:</span>
                    <span>{(Number(selectedOrder.total) + Number(selectedOrder.shipping)).toLocaleString()} VND</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-6 border-t bg-gray-50">
              {!canCancelOrder(selectedOrder.status) && selectedOrder.status.toUpperCase() !== "CANCELLED" && (
                <div className="mb-4 p-3 bg-blue-50 rounded-lg">
                  <p className="text-sm text-blue-700 text-center">
                    <strong>Cần hỗ trợ?</strong> Liên hệ: 0767218023 | Zalo: 0767218023
                  </p>
                </div>
              )}
              
              <div className="flex gap-3">
                <button
                  onClick={closeOrderDetail}
                  className="flex-1 border border-gray-300 text-gray-700 py-3 rounded-lg hover:bg-gray-100 transition"
                >
                  Đóng
                </button>
                <Link
                  href="/"
                  className="flex-1 bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition text-center"
                >
                  Tiếp tục mua sắm
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
      </div>
    </AuthGuard>
  );
}

export default function Success() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Đang tải...</p>
        </div>
      </div>
    }>
      <SuccessContent />
    </Suspense>
  );
}
