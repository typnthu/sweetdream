"use client";
import { useState, useEffect, Suspense } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useOrders, type Order, type OrderStatus } from "@/context/OrderContext";
import { useAuth } from "@/context/AuthContext";
import AuthGuard from "@/components/AuthGuard";

const getStatusColor = (status: OrderStatus) => {
  switch (status) {
    case "PLACED": return "bg-blue-100 text-blue-800";
    case "CONFIRMED": return "bg-green-100 text-green-800";
    case "PREPARING": return "bg-orange-100 text-orange-800";
    case "DELIVERING": return "bg-purple-100 text-purple-800";
    case "DELIVERED": return "bg-emerald-100 text-emerald-800";
    case "CANCELLED": return "bg-red-100 text-red-800";
    default: return "bg-gray-100 text-gray-800";
  }
};

const getStatusText = (status: OrderStatus) => {
  switch (status) {
    case "PLACED": return "Đã đặt hàng";
    case "CONFIRMED": return "Đã xác nhận";
    case "PREPARING": return "Đang chuẩn bị";
    case "DELIVERING": return "Đang giao hàng";
    case "DELIVERED": return "Đã giao thành công";
    case "CANCELLED": return "Đã hủy";
    default: return status;
  }
};

function SuccessContent() {
  const { orders, cancelOrder } = useOrders();
  const { user } = useAuth();
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [showOrderDetail, setShowOrderDetail] = useState(false);
  const searchParams = useSearchParams();
  const router = useRouter();

  // Check if coming from checkout success
  const orderId = searchParams.get('orderId');
  const isFromCheckout = searchParams.get('fromCheckout') === 'true';

  useEffect(() => {
    if (orderId && isFromCheckout) {
      const order = orders.find(o => o.id === parseInt(orderId));
      if (order) {
        setSelectedOrder(order);
        setShowOrderDetail(true);
      }
    }
  }, [orderId, isFromCheckout, orders]);

  const handleViewOrderDetail = (order: Order) => {
    setSelectedOrder(order);
    setShowOrderDetail(true);
  };

  const handleCancelOrder = (orderId: number) => {
    if (confirm("Bạn có chắc chắn muốn hủy đơn hàng này?")) {
      cancelOrder(orderId);
      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder({ ...selectedOrder, status: "CANCELLED", canCancel: false });
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
      <div className="p-6 max-w-6xl mx-auto">
      {isFromCheckout && selectedOrder ? (
        // Success message when coming from checkout
        <div className="text-center mb-8 bg-green-50 p-6 rounded-lg">
          <div className="text-green-500 text-6xl mb-4">✅</div>
          <h1 className="text-3xl font-bold text-green-600 mb-2">
            Đặt hàng thành công!
          </h1>
          <p className="text-gray-600 mb-4">
            Cảm ơn bạn đã mua hàng. Đơn hàng #{selectedOrder.orderNumber} đã được tạo thành công.
          </p>
        </div>
      ) : (
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">
            Xin chào, {user?.name}! 👋
          </h1>
          <p className="text-gray-600">Theo dõi và quản lý các đơn hàng của bạn</p>
        </div>
      )}

      {/* Orders List */}
      <div className="space-y-4">
        {orders.map((order) => (
          <div key={order.id} className="bg-white border rounded-lg p-6 hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">
                  Đơn hàng #{order.orderNumber}
                </h3>
                <p className="text-sm text-gray-500">Ngày đặt: {order.date}</p>
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
                    {(order.total + order.shipping).toLocaleString()} VND
                  </span>
                </p>
                {order.estimatedDelivery && order.status === "PLACED" && (
                  <p className="text-xs text-blue-600 mt-1">
                    Dự kiến giao: {order.estimatedDelivery}
                  </p>
                )}
              </div>
              <div className="flex gap-2">
                {order.canCancel && (
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

      {orders.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 text-xl mb-4">Chưa có đơn hàng nào</p>
          <Link
            href="/"
            className="bg-pink-600 text-white px-6 py-3 rounded-lg hover:bg-pink-700 transition"
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
                    Chi tiết đơn hàng #{selectedOrder.orderNumber}
                  </h2>
                  <p className="text-sm text-gray-600">Ngày đặt: {selectedOrder.date}</p>
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
                  {selectedOrder.estimatedDelivery && selectedOrder.status === "PLACED" && (
                    <p className="text-sm text-blue-600 mt-2">
                      Dự kiến giao: {selectedOrder.estimatedDelivery}
                    </p>
                  )}
                </div>
                {selectedOrder.canCancel && (
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
                    <div className={`flex items-center ${selectedOrder.status === "PLACED" ? "text-blue-600 font-medium" : selectedOrder.status !== "CANCELLED" ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      1. Đặt hàng - {selectedOrder.status === "PLACED" ? "Đang chờ xác nhận" : "Hoàn thành"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status === "CONFIRMED" ? "text-blue-600 font-medium" : ["PREPARING", "DELIVERING", "DELIVERED"].includes(selectedOrder.status) ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      2. Xác nhận - {selectedOrder.status === "CONFIRMED" ? "Đã xác nhận, chuẩn bị làm bánh" : ["PREPARING", "DELIVERING", "DELIVERED"].includes(selectedOrder.status) ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status === "PREPARING" ? "text-blue-600 font-medium" : ["DELIVERING", "DELIVERED"].includes(selectedOrder.status) ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      3. Chuẩn bị - {selectedOrder.status === "PREPARING" ? "Đang làm bánh" : ["DELIVERING", "DELIVERED"].includes(selectedOrder.status) ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status === "DELIVERING" ? "text-blue-600 font-medium" : selectedOrder.status === "DELIVERED" ? "text-green-600" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      4. Giao hàng - {selectedOrder.status === "DELIVERING" ? "Shipper đang giao" : selectedOrder.status === "DELIVERED" ? "Hoàn thành" : "Chờ xử lý"}
                    </div>
                    <div className={`flex items-center ${selectedOrder.status === "DELIVERED" ? "text-green-600 font-medium" : "text-gray-400"}`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-3"></span>
                      5. Hoàn thành - {selectedOrder.status === "DELIVERED" ? "Đã giao thành công" : "Chờ xử lý"}
                    </div>
                  </div>
                  
                  {selectedOrder.status === "PLACED" && (
                    <div className="mt-3 p-3 bg-yellow-50 rounded border-l-4 border-yellow-400">
                      <p className="text-sm text-yellow-700">
                        <strong>Lưu ý:</strong> Bạn có thể hủy đơn hàng khi đang chờ xác nhận. 
                        Sau khi được xác nhận, vui lòng liên hệ trực tiếp: <strong>0767218023</strong>
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
                {selectedOrder.items.map((item: any) => (
                  <div key={item.id} className="flex items-center gap-4 p-3 border rounded-lg mb-3">
                    <Image
                      src={item.img}
                      alt={item.name}
                      width={60}
                      height={60}
                      className="rounded-lg object-cover"
                    />
                    <div className="flex-1">
                      <p className="font-medium text-gray-800">{item.name}</p>
                      <p className="text-sm text-gray-600">Số lượng: {item.quantity}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-pink-600">
                        {(item.price * item.quantity).toLocaleString()} VND
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
                    <span>{selectedOrder.total.toLocaleString()} VND</span>
                  </div>
                  <div className="flex justify-between text-gray-600">
                    <span>Phí vận chuyển:</span>
                    <span>{selectedOrder.shipping.toLocaleString()} VND</span>
                  </div>
                  <div className="flex justify-between text-lg font-bold text-pink-600 border-t pt-2">
                    <span>Tổng cộng:</span>
                    <span>{(selectedOrder.total + selectedOrder.shipping).toLocaleString()} VND</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-6 border-t bg-gray-50">
              {selectedOrder.status !== "PLACED" && selectedOrder.status !== "CANCELLED" && (
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
