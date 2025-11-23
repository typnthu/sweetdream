export default function ContactPage() {
  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6 text-pink-600">Liên hệ</h1>
      
      <div className="grid md:grid-cols-2 gap-8">
        <div className="space-y-6">
          <section>
            <h2 className="text-xl font-semibold mb-3 text-pink-500">Thông tin liên hệ</h2>
            <div className="space-y-3 text-gray-700">
              <div>
                <p className="font-semibold">Địa chỉ:</p>
                <p>123 Đường ABC, Quận XYZ, TP. Hồ Chí Minh</p>
              </div>
              <div>
                <p className="font-semibold">Điện thoại:</p>
                <p>(028) 1234 5678</p>
              </div>
              <div>
                <p className="font-semibold">Email:</p>
                <p>contact@sweetdream.vn</p>
              </div>
              <div>
                <p className="font-semibold">Giờ mở cửa:</p>
                <p>Thứ 2 - Chủ nhật: 8:00 - 21:00</p>
              </div>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold mb-3 text-pink-500">Mạng xã hội</h2>
            <div className="space-y-2 text-gray-700">
              <p>Facebook: /sweetdream.vn</p>
              <p>Instagram: @sweetdream.vn</p>
              <p>Zalo: 0123456789</p>
            </div>
          </section>
        </div>

        <div>
          <h2 className="text-xl font-semibold mb-3 text-pink-500">Gửi tin nhắn</h2>
          <form className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Họ tên</label>
              <input
                type="text"
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Nhập họ tên của bạn"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Email</label>
              <input
                type="email"
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Nhập email của bạn"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Số điện thoại</label>
              <input
                type="tel"
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Nhập số điện thoại"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Nội dung</label>
              <textarea
                rows={4}
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Nhập nội dung tin nhắn"
              />
            </div>
            <button
              type="submit"
              className="w-full bg-pink-500 text-white py-2 rounded-lg hover:bg-pink-600 transition"
            >
              Gửi tin nhắn
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
