"use client";

import Image from "next/image";
import Link from "next/link";
import { useCategory } from "@/context/CategoryContext";
import products from "@/products/index";

export default function Home() {
  const { category } = useCategory();

  // Tạm: chọn sản phẩm hot / new dựa theo id (sau này backend sẽ cung cấp)
  const hotProducts = products.slice(0, 4); // ví dụ 4 sản phẩm đầu
  const newProducts = products.slice(-4);   // 4 sản phẩm cuối

  return (
    <div className="max-w-5xl mx-auto p-6">

      {/* Banner */}
      <div className="mb-10 relative w-full h-60 rounded-lg overflow-hidden shadow-lg">
        <Image
          src="/banner.webp" // bạn thêm ảnh banner vào public/
          alt="Banner SweetDream"
          fill
          className="object-cover"
        />
        <div className="absolute inset-0 bg-black/30 flex items-center justify-center">
          <h1 className="text-3xl md:text-5xl text-white font-bold">
            Chào mừng đến với SweetDream 🍰
          </h1>
        </div>
      </div>

      {/* Sản phẩm được mua nhiều */}
      <section className="mb-10">
        <h2 className="text-2xl font-bold mb-4 text-pink-600">Sản phẩm được mua nhiều</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
          {hotProducts.map((p) => (
            <div key={p.id} className="border rounded-xl p-4 hover:shadow-lg">
              <Link href={`/product/${p.id}`}>
                <Image
                  src={p.img}
                  alt={p.name}
                  width={320}
                  height={240}
                  className="rounded-lg mb-3 object-cover"
                />
                <h3 className="font-semibold">{p.name}</h3>
                <p className="text-pink-500 font-bold">
                  {p.sizes[0].price.toLocaleString()} VND
                </p>
              </Link>
            </div>
          ))}
        </div>
      </section>

      {/* Sản phẩm mới ra mắt */}
      <section className="mb-10">
        <h2 className="text-2xl font-bold mb-4 text-pink-600">Sản phẩm mới ra mắt</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
          {newProducts.map((p) => (
            <div key={p.id} className="border rounded-xl p-4 hover:shadow-lg">
              <Link href={`/product/${p.id}`}>
                <Image
                  src={p.img}
                  alt={p.name}
                  width={320}
                  height={240}
                  className="rounded-lg mb-3 object-cover"
                />
                <h3 className="font-semibold">{p.name}</h3>
                <p className="text-pink-500 font-bold">
                  {p.sizes[0].price.toLocaleString()} VND
                </p>
              </Link>
            </div>
          ))}
        </div>
      </section>

    </div>
  );
}
