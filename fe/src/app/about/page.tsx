export default function AboutPage() {
  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6 text-pink-600">Giới thiệu về SweetDream</h1>
      
      <div className="space-y-6 text-gray-700">
        <section>
          <h2 className="text-2xl font-semibold mb-3 text-pink-500">Câu chuyện của chúng tôi</h2>
          <p className="leading-relaxed">
            SweetDream được thành lập với niềm đam mê tạo ra những chiếc bánh ngon và đẹp mắt. 
            Chúng tôi tin rằng mỗi chiếc bánh không chỉ là món ăn, mà còn là một tác phẩm nghệ thuật 
            mang đến niềm vui và hạnh phúc cho mọi người.
          </p>
        </section>

        <section>
          <h2 className="text-2xl font-semibold mb-3 text-pink-500">Sứ mệnh</h2>
          <p className="leading-relaxed">
            Sứ mệnh của chúng tôi là mang đến những sản phẩm bánh chất lượng cao, được làm từ 
            nguyên liệu tươi ngon và an toàn. Mỗi chiếc bánh đều được chế biến tỉ mỉ bởi đội ngũ 
            thợ bánh giàu kinh nghiệm với tình yêu và sự tận tâm.
          </p>
        </section>

        <section>
          <h2 className="text-2xl font-semibold mb-3 text-pink-500">Giá trị cốt lõi</h2>
          <ul className="list-disc list-inside space-y-2 leading-relaxed">
            <li>Chất lượng là ưu tiên hàng đầu</li>
            <li>Nguyên liệu tươi ngon, an toàn</li>
            <li>Dịch vụ khách hàng tận tâm</li>
            <li>Sáng tạo và đổi mới không ngừng</li>
            <li>Giá cả hợp lý, minh bạch</li>
          </ul>
        </section>

        <section>
          <h2 className="text-2xl font-semibold mb-3 text-pink-500">Liên hệ</h2>
          <p className="leading-relaxed">
            Hãy ghé thăm cửa hàng của chúng tôi hoặc liên hệ để đặt bánh. 
            Chúng tôi luôn sẵn sàng phục vụ bạn!
          </p>
        </section>
      </div>
    </div>
  );
}
