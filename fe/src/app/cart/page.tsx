"use client";
import Image from "next/image";
import Link from "next/link";
import { useCart } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { useState } from "react";
import { useRouter } from "next/navigation";
import AuthGuard from "@/components/AuthGuard";
import { formatPrice } from "@/lib/formatPrice";

export default function Cart() {
  const { cart, removeFromCart, clearCart, updateQuantity } = useCart();
  const { user } = useAuth();
  const router = useRouter();
  const [customerInfo, setCustomerInfo] = useState({
    name: user?.name || "",
    email: user?.email || "",
    phone: user?.phone || "",
    address: user?.address || ""
  });
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [orderData, setOrderData] = useState<any>(null);

  const total = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const shipping = 30000; // Phí vận chuyển cố định
  const finalTotal = total + shipping;

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setCustomerInfo(prev => ({ ...prev, [name]: value }));
  };

  const handleCheckout = async () => {
    if (!customerInfo.name || !customerInfo.email || !customerInfo.phone || !customerInfo.address) {
      alert("Vui lòng điền đầy đủ thông tin!");
      return;
    }

    try {
      // Create order in database via API
      const orderPayload = {
        customer: {
          name: customerInfo.name,
          email: customerInfo.email,
          phone: customerInfo.phone,
          address: customerInfo.address
        },
        items: cart.map(item => ({
          productId: item.originalProductId || item.id,
          size: item.name.split(' - ')[1] || '16cm', // Extract size from name or default
          price: item.price,
          quantity: item.qty
        })),
        notes: '' // Optional: add notes field if needed
      };

      const response = await fetch('/api/proxy/orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(orderPayload),
      });

      if (!response.ok) {
        const error = await response.json();
        console.error('Failed to create order:', error);
        alert('Không thể tạo đơn hàng. Vui lòng thử lại!');
        return;
      }

      const result = await response.json();
      const createdOrder = result.order;

      // Use the order data from database
      setOrderData({
        id: createdOrder.id,
        orderNumber: `ORD-${createdOrder.id}`,
        date: new Date(createdOrder.createdAt).toLocaleDateString('vi-VN'),
        status: createdOrder.status,
        customer: createdOrder.customer,
        items: createdOrder.items.map((item: any) => ({
          id: item.id,
          name: `${item.product.name} - ${item.size}`,
          price: Number(item.price),
          quantity: item.quantity,
          img: item.product.img,
          originalProductId: item.productId
        })),
        total: Number(createdOrder.total),
        shipping: Number(createdOrder.shipping),
        estimatedDelivery: new Date(Date.now() + 4 * 60 * 60 * 1000).toLocaleString('vi-VN')
      });
      setShowSuccessModal(true);
    } catch (error) {
      console.error('Checkout error:', error);
      alert('Có lỗi xảy ra khi đặt hàng. Vui lòng thử lại!');
    }
  };

  return (
    <AuthGuard showLoginPrompt={true}>
      <div className="p-6 max-w-5xl mx-auto">
      <h1 className="text-2xl font-bold mb-8 text-pink-500">Giỏ hàng</h1>

      {cart.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-500 text-xl mb-4">Giỏ hàng trống</p>
          <Link
            href="/"
            className="bg-white text-pink-500 px-3 py-3 rounded-lg hover:text-pink-700 transition"
          >
            Khám phá sản phẩm
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Cart Items Section */}
          <div className="lg:col-span-1">
            <h2 className="text-xl font-semibold mb-4 text-gray-800">Sản phẩm trong giỏ</h2>

            {cart.map((item) => (
              <div
                key={item.id}
                className="relative border p-1 rounded-lg mb-4 flex items-center justify-between hover:shadow-md bg-white"
              >
                {/* Nút xóa ở góc trên bên phải */}
                <button
                  onClick={() => removeFromCart(item.id)}
                  className="absolute top-1 right-2 text-red-500 hover:text-red-700 text-sm"
                >
                  x
                </button>

                {/* Hình ảnh và thông tin sản phẩm */}
                <div className="flex items-center gap-4">
                  <div
                    className="cursor-pointer hover:opacity-80 transition-opacity"
                    onClick={() => {
                      if (item.originalProductId) {
                        router.push(`/product/${item.originalProductId}`);
                      }
                    }}
                  >
                    <Image
                      src={item.img}
                      alt={item.name}
                      width={80}
                      height={80}
                      className="rounded-lg object-cover"
                    />
                  </div>

                  <div>
                    <p
                      className=" text-gray-800 cursor-pointer hover:text-pink-600 transition-colors"
                      onClick={() => {
                        if (item.originalProductId) {
                          router.push(`/product/${item.originalProductId}`);
                        }
                      }}
                    >
                      {item.name}
                    </p>
                    <p className="text-pink-500 text">
                      {formatPrice(item.price)}
                    </p>

                    {/* Điều chỉnh số lượng */}
                      <div className="flex items-center mt-1">
                        <button
                          onClick={() => updateQuantity(item.id, Math.max(item.qty - 1, 1))}
                          className="px-2 py-1 hover:bg-gray-300 bg-gray-200 rounded text-xs"
                        >
                          -
                        </button>
                        <span className="px-3 text-sm font-medium">{item.qty}</span>
                        <button
                          onClick={() => updateQuantity(item.id, item.qty + 1)}
                          className="px-2 py-1 hover:bg-gray-300 rounded bg-gray-200 text-xs"
                        >
                          +
                        </button>
                      </div>
                  </div>
                </div>

                {/* Tổng tiền */}
                <div className="text-right">
                  <p className="font-bold text-lg text-pink-600">
                    {formatPrice(item.price * item.qty)}
                  </p>
                </div>
              </div>

            ))}

            <button
              onClick={clearCart}
              className="w-full bg-gray-400 text-white py-2 rounded hover:bg-gray-500 transition mt-4"
            >
              Xóa tất cả sản phẩm
            </button>
          </div>

          {/* Checkout Section */}
          <div className="lg:col-span-1">
            <div className="bg-gray-50 p-6 rounded-lg sticky top-6">
              <h2 className="text-xl font-semibold mb-4 text-gray-800">Thông tin thanh toán</h2>

              {/* Customer Information Form */}
              <div className="space-y-4 mb-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Họ và tên *
                  </label>
                  <input
                    type="text"
                    name="name"
                    value={customerInfo.name}
                    onChange={handleInputChange}
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                    placeholder="Nhập họ và tên"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email *
                  </label>
                  <input
                    type="email"
                    name="email"
                    value={customerInfo.email}
                    onChange={handleInputChange}
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                    placeholder="Nhập email"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Số điện thoại *
                  </label>
                  <input
                    type="tel"
                    name="phone"
                    value={customerInfo.phone}
                    onChange={handleInputChange}
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                    placeholder="Nhập số điện thoại"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Địa chỉ giao hàng *
                  </label>
                  <textarea
                    name="address"
                    value={customerInfo.address}
                    onChange={handleInputChange}
                    rows={3}
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                    placeholder="Nhập địa chỉ giao hàng"
                  />
                </div>
              </div>

              {/* Order Summary */}
              <div className="border-t pt-4 space-y-2">
                <div className="flex justify-between text-gray-600">
                  <span>Tạm tính:</span>
                  <span>{formatPrice(total)}</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Phí vận chuyển:</span>
                  <span>{formatPrice(shipping)}</span>
                </div>
                <div className="flex justify-between text-lg font-bold text-pink-600 border-t pt-2">
                  <span>Tổng cộng:</span>
                  <span>{formatPrice(finalTotal)}</span>
                </div>
              </div>

              {/* Checkout Button */}
              <button
                onClick={handleCheckout}
                className="w-full bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition font-semibold mt-6"
              >
                Đặt hàng ngay
              </button>

              <p className="text-xs text-gray-500 mt-3 text-center">
                Bằng việc đặt hàng, bạn đồng ý với điều khoản sử dụng của chúng tôi
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Checkout Success Modal */}
      {showSuccessModal && orderData && (
        <div className="fixed inset-0 bg-gray-900/40 bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="p-6 border-b bg-green-50">
              <div className="text-center">               
                <h2 className="text-2xl font-bold text-green-600 mb-2">Đặt hàng thành công!</h2>
                <p className="text-gray-600">
                  Đơn hàng #{orderData.orderNumber} đã được tạo thành công
                </p>
              </div>
            </div>

            {/* Modal Content */}
            <div className="p-6 max-h-96 overflow-y-auto">
              {/* Customer Info */}
              <div className="mb-6">
                <h3 className="font-semibold text-gray-800 mb-3">Thông tin khách hàng</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p><strong>Tên:</strong> {orderData.customer.name}</p>
                  <p><strong>Email:</strong> {orderData.customer.email}</p>
                  <p><strong>Điện thoại:</strong> {orderData.customer.phone}</p>
                  <p><strong>Địa chỉ:</strong> {orderData.customer.address}</p>
                </div>
              </div>

              {/* Order Items */}
              <div className="mb-6">
                <h3 className="font-semibold text-gray-800 mb-3">Sản phẩm đã đặt</h3>
                {orderData.items.map((item: any) => (
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
                        {formatPrice(item.price * item.quantity)}
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
                    <span>{formatPrice(orderData.total)}</span>
                  </div>
                  <div className="flex justify-between text-gray-600">
                    <span>Phí vận chuyển:</span>
                    <span>{formatPrice(orderData.shipping)}</span>
                  </div>
                  <div className="flex justify-between text-lg font-bold text-pink-600 border-t pt-2">
                    <span>Tổng cộng:</span>
                    <span>{formatPrice(orderData.total + orderData.shipping)}</span>
                  </div>
                </div>
              </div>

              {/* Order Process & Important Notes */}
              <div className="mt-6 space-y-4">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-blue-800 mb-2">Quy trình đơn hàng:</h4>
                  <div className="text-sm text-blue-700 space-y-1">
                    <p>1. <strong>Đặt hàng</strong> - Đơn hàng đã được tạo</p>
                    <p>2. <strong>Xác nhận</strong> - Cửa hàng sẽ xác nhận trong 4 giờ</p>
                    <p>3. <strong>Chuẩn bị</strong> - Bắt đầu làm bánh</p>
                    <p>4. <strong>Giao hàng</strong> - Shipper đang giao</p>
                    <p>5. <strong>Hoàn thành</strong> - Đã giao thành công</p>
                  </div>
                </div>
                
                <div className="bg-yellow-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-yellow-800 mb-2">Lưu ý quan trọng:</h4>
                  <ul className="text-sm text-yellow-700 space-y-1">
                    <li>• Thời gian giao hàng dự kiến: {orderData?.estimatedDelivery}</li>
                    <li>• Chúng tôi sẽ liên hệ xác nhận qua số điện thoại đã cung cấp</li>
                    <li>• Bạn có thể hủy đơn hàng khi đang chờ xác nhận</li>
                    <li>• Sau khi xác nhận, vui lòng liên hệ trực tiếp: 0767218023</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-6 border-t bg-gray-50">
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowSuccessModal(false);
                    clearCart();
                    router.push('/');
                  }}
                  className="flex-1 border border-gray-300 text-gray-700 py-3 rounded-lg hover:bg-gray-100 transition font-medium"
                >
                  Về trang chủ
                </button>
                <button
                  onClick={() => {
                    setShowSuccessModal(false);
                    clearCart();
                    router.push(`/success?orderId=${orderData.id}&fromCheckout=true`);
                  }}
                  className="flex-1 bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition font-semibold"
                >
                  Xem chi tiết đơn hàng
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      </div>
    </AuthGuard>
  );
}
