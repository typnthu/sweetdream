"use client";

import Image from "next/image";
import { useCart } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { useRouter, useParams } from "next/navigation";
import { useState } from "react";
import products from "@/products/index";

export default function ProductDetail() {
  const params = useParams();
  const id = Number(params?.id);
  const product = products.find((p) => p.id === id);

  const { addToCart, cart, updateQuantity, removeFromCart } = useCart();
  const { isAuthenticated } = useAuth();
  const router = useRouter();

  const [selectedSize, setSelectedSize] = useState(product?.sizes?.[0] || null);
  const [qty, setQty] = useState(1);
  const [showModal, setShowModal] = useState(false);

  if (!product) return <div className="p-6 text-red-500">Không tìm thấy sản phẩm.</div>;

  const handleAddCart = () => {
    if (!isAuthenticated) {
      const currentPath = window.location.pathname;
      router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
      return;
    }

    if (!selectedSize) {
      alert("Vui lòng chọn kích thước!");
      return;
    }

    addToCart({
      id: product.id * 1000 + product.sizes.indexOf(selectedSize), // Create unique numeric ID
      name: `${product.name} - ${selectedSize.size}`,
      price: selectedSize.price,
      img: product.img,
      originalProductId: product.id, // Store original product ID
    }, qty);

    setShowModal(true);
  };

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Chi tiết sản phẩm */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <Image src={product.img} width={500} height={400} alt={product.name} className="rounded-lg shadow-lg" />
        <div>
          <h1 className="text-3xl font-bold">{product.name}</h1>

          <label className="block font-medium mt-4">Kích thước:</label>
          <div className="flex gap-3">
            {product.sizes.map((s, i) => (
              <button
                key={i}
                onClick={() => setSelectedSize(s)}
                className={`px-2.5 py-0.75 border rounded-4xl ${
                  selectedSize?.size === s.size
                    ? "bg-pink-500 text-white"
                    : "bg-white text-gray-700 hover:bg-pink-50"
                }`}
              >
                {s.size}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-3 mt-4">
            <button className="px-2 border rounded" onClick={() => qty > 1 && setQty(qty - 1)}>-</button>
            <span className="font-bold">{qty}</span>
            <button className="px-2 border rounded" onClick={() => setQty(qty + 1)}>+</button>
          </div>

          <p className="text-pink-600 font-bold text-xl mt-3">
            {selectedSize ? (selectedSize.price * qty).toLocaleString() : "0"} VND
          </p>
<p className="mt-5 text-gray-600">{product.description}</p>
         <div className="flex gap-3 mt-4">
        
  <button
    onClick={handleAddCart}
    className="bg-pink-500 text-white flex-1 py-3 rounded-lg hover:bg-pink-600"
  >
    Thêm vào giỏ 🛒
  </button>

  <button
    onClick={() => {
      if (!isAuthenticated) {
        const currentPath = window.location.pathname;
        router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
        return;
      }
      
      if (!selectedSize) {
        alert("Vui lòng chọn kích thước!");
        return;
      }
      addToCart({
        id: product.id * 1000 + product.sizes.indexOf(selectedSize),
        name: `${product.name} - ${selectedSize.size}`,
        price: selectedSize.price,
        img: product.img,
        originalProductId: product.id,
      }, qty);
      router.push("/cart");
    }}
    className="border border-pink-500 text-pink-600 flex-1 py-3 rounded-lg hover:bg-pink-50"
  >
    Mua ngay
  </button>
</div>

          
        </div>
      </div>
      <div className="justify-center mt-3">
  <h2 className="font-bold text-xl mb-2">Lưu ý quan trọng:</h2>
  <p>Điện thoại: 0767218023 | Zalo: 0767218023</p>
  <p>Bánh kem tươi – làm mới và giao ngay trong ngày!</p>
  <p>Khi đặt bánh, vui lòng ghi chú thời gian mong muốn nhận hàng ở trang giỏ hàng. Sau khi đặt đơn, giữ điện thoại thông suốt, nhân viên CSKH sẽ liên hệ nếu có vấn đề.</p>
  <p>Một chiếc bánh đẹp khi giao đến tay khách sẽ bao gồm dao cắt, nến, đĩa và nĩa. Không bao gồm phụ kiện trang trí, giấy gói (có bán riêng – chọn thêm tại giỏ hàng).</p>
  <p>Sau khi nhận đơn, tiệm sẽ bắt đầu chuẩn bị bánh ngay. Thời gian giao hàng dự kiến trong vòng 3–4 giờ. Khuyến khích đặt trước vài tiếng để tiệm chuẩn bị tốt hơn. Đối với bánh cỡ lớn hoặc đơn gấp, vui lòng đặt trước ít nhất 1 ngày.</p>
  <p><strong>Bảo quản:</strong></p>
  <ul className="list-disc list-inside text-left inline-block text-left">
    <li>Bánh cần được bảo quản lạnh từ 0°C đến 5°C</li>
    <li>Thời gian sử dụng ngon nhất trong 24 giờ</li>
    <li>Không để bánh ngoài tủ lạnh quá 3 giờ để đảm bảo độ tươi ngon</li>
    <li>Do không dùng chất bảo quản, hạn sử dụng không quá 48 giờ</li>
  </ul>
  <p>Tiệm nhận làm bánh theo mẫu! Hãy để lại lời nhắn để được báo giá và tư vấn nhanh chóng.</p>
  <p>Hệ thống tự động tính cước phí theo địa chỉ bạn đặt hàng. Độ chính xác của cước phí liên quan đến độ chính xác địa chỉ. Nếu cần bổ sung, CSKH sẽ liên hệ để xác minh.</p>
</div>


      {/* Giới thiệu cửa hàng & tất cả các sản phẩm */}
{/* Sản phẩm tương tự */}

<div className="mt-2">
  <h2 className="text-2xl font-bold mb-2">Sản phẩm tương tự</h2>
   <p className="text-gray-600 mb-6"> SweetDream chuyên các loại bánh ngọt thơm ngon, được làm từ nguyên liệu tươi sạch và công thức độc quyền. Khách hàng có thể lựa chọn từ bánh mousse, tiramisu, bánh kem, đến bánh mì ngọt. Hãy khám phá và thêm vào giỏ hàng những món bánh yêu thích! </p>
  <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
    {products
      .filter((p) => p.category === product.category && p.id !== product.id)
      .slice(0, 8) // hiển thị tối đa 8 sản phẩm tương tự
      .map((p) => (
        <div 
          key={p.id} 
          className="border rounded-lg p-3 hover:shadow-lg cursor-pointer transition-shadow"
          onClick={() => router.push(`/product/${p.id}`)}
        >
          <Image
            src={p.img}
            alt={p.name}
            width={250}
            height={180}
            className="rounded-lg mb-2 object-cover"
          />
          <h3 className="font-semibold">{p.name}</h3>
          <p className="text-pink-500 font-bold">
            {p.sizes && p.sizes.length > 0 ? p.sizes[0].price.toLocaleString() : "0"} VND
          </p>
        </div>
      ))}
  </div>
</div>

{/* Tất cả sản phẩm (tối đa 20) */}
<div className="mt-6">
  <h2 className="text-2xl font-bold mb-2">Khám phá cửa hàng</h2>
  <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
    {products.slice(0, 20).map((p) => (
      <div 
        key={p.id} 
        className="border rounded-lg p-3 hover:shadow-lg cursor-pointer transition-shadow"
        onClick={() => router.push(`/product/${p.id}`)}
      >
        <Image
          src={p.img}
          alt={p.name}
          width={250}
          height={180}
          className="rounded-lg mb-2 object-cover"
        />
        <h3 className="font-semibold">{p.name}</h3>
        <p className="text-pink-500 font-bold">
          {p.sizes && p.sizes.length > 0 ? p.sizes[0].price.toLocaleString() : "0"} VND
        </p>
      </div>
    ))}
  </div>
</div>

      {/* Add to Cart Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] shadow-lg">
            {/* Modal Header */}
            <div className="p-6 border-b bg-pink-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div>
                    <h2 className="text-xl font-bold text-gray-800">Đã thêm vào giỏ hàng!</h2>
                    <p className="text-sm text-gray-600">
                      {selectedSize && product && `${product.name} - ${selectedSize.size}`}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setShowModal(false)}
                  className="text-gray-400 hover:text-gray-600 text-2xl"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Cart Items */}
            <div className="p-6 max-h-96 overflow-y-auto">
              <h3 className="font-semibold text-gray-800 mb-4">Giỏ hàng của bạn ({cart.reduce((sum, item) => sum + item.qty, 0)} sản phẩm)</h3>
              
              {cart.map((item) => (
                <div
                  key={item.id}
                  className="border p-3 rounded-lg mb-3 flex items-center justify-between hover:shadow-sm bg-gray-50"
                >
                  {/* Product Image and Info */}
                  <div className="flex items-center gap-3">
                    <Image
                      src={item.img}
                      alt={item.name}
                      width={60}
                      height={60}
                      className="rounded-lg object-cover"
                    />
                    <div>
                      <p className="font-medium text-gray-800 text-sm">{item.name}</p>
                      <p className="text-pink-500 font-bold text-sm">
                        {item.price.toLocaleString()} VND
                      </p>
                      
                      {/* Quantity Controls */}
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

                  {/* Item Total and Remove */}
                  <div className="text-right">
                    <p className="font-bold text-pink-600 text-sm mb-1">
                      {(item.price * item.qty).toLocaleString()} VND
                    </p>
                    <button
                      onClick={() => removeFromCart(item.id)}
                      className="text-red-500 hover:text-red-700 text-sm"
                    >
                      ❌
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* Total and Actions */}
            <div className="p-6 border-t bg-gray-50">
              <div className="mb-4">
                <div className="flex justify-between items-center text-lg font-bold text-pink-600">
                  <span>Tổng cộng:</span>
                  <span>
                    {cart.reduce((sum, item) => sum + item.price * item.qty, 0).toLocaleString()} VND
                  </span>
                </div>
              </div>
              
              <div className="flex gap-3">
                <button
                  onClick={() => setShowModal(false)}
                  className="flex-1 border border-gray-300 text-gray-700 py-3 rounded-lg hover:bg-gray-100 transition font-medium"
                >
                  Tiếp tục mua sắm
                </button>
                <button
                  onClick={() => {
                    setShowModal(false);
                    router.push("/cart");
                  }}
                  className="flex-1 bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition font-semibold"
                >
                  Thanh toán ({cart.reduce((sum, item) => sum + item.qty, 0)})
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
