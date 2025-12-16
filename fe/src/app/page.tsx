"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
//import { useCategory } from "@/context/CategoryContext";
import { getProducts, type Product } from "@/lib/api";

export default function Home() {
  //const { category } = useCategory();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchProducts() {
      try {
        setLoading(true);
        const data = await getProducts();
        setProducts(data);
        setError(null);
      } catch (err) {
        console.error('Failed to fetch products:', err);
        setError('Không thể tải sản phẩm. Vui lòng thử lại sau.');
      } finally {
        setLoading(false);
      }
    }

    fetchProducts();
  }, []);

  // Chọn sản phẩm hot / new dựa theo id
  const hotProducts = products.slice(-4); // 4 sản phẩm cuối
  const newProducts = products.slice(0,4);   // 4 sản phẩm đầu

  return (
    <div>
      {/* Banner - Full Width, Clickable */}
      <Link href="/about" className="block cursor-pointer group">
        <div className="relative w-full md:h-[350px] overflow-hidden shadow-[0_15px_15px_rgba(248,166,210,0.4)]">
          <Image
            src="/banner.png"
            alt="Banner SweetDream - Click để tìm hiểu thêm về sản phẩm"
            fill
            className="object-cover object-center transition-transform duration-500 group-hover:scale-105"
            priority
          />
          {/* Test deployment indicator */}
          <div className="absolute bottom-2 right-2 bg-pink-500 text-white px-2 py-1 rounded text-xs opacity-75">
            v2024.12.17
          </div>
        </div>
      </Link>

      {/* Products Section */}
      <div className="max-w-5xl mx-auto p-6">

      {/* Loading state */}
      {loading && (
        <div className="text-center py-10">
          <p className="text-gray-600">Đang tải sản phẩm...</p>
        </div>
      )}

      {/* Error state */}
      {error && (
        <div className="text-center py-10">
          <p className="text-red-600">{error}</p>
        </div>
      )}

      {/* Sản phẩm được mua nhiều */}
      {!loading && !error && (
        <section className="mb-10">
          <h2 className="text-2xl font-bold mb-4 text-pink-500">Sản phẩm được mua nhiều</h2>
          <div className="grid sm:grid-cols-4 gap-6">
            {hotProducts.map((p) => (
            <div key={p.id} className=" rounded-lg p-4 hover:shadow-[0_10px_15px_rgba(249,168,212,0.5)]">
              <Link href={`/product/${p.id}`}>
                <Image
                  src={p.img}
                  alt={p.name}
                  width={320}
                  height={240}
                  className="rounded-lg mb-3 object-cover"
                />
                <h3 className="text-center">{p.name}</h3>
                <p className="text-pink-500 text-center">
                  {p.sizes && p.sizes.length > 0 ? p.sizes[0].price.toLocaleString() : 'N/A'} VND
                </p>
              </Link>
            </div>
            ))}
          </div>
        </section>
      )}

      {/* Sản phẩm mới ra mắt */}
      {!loading && !error && (
        <section className="mb-10">
        <h2 className="text-2xl font-bold mb-4 text-pink-500">Sản phẩm mới ra mắt</h2>
        <div className="grid sm:grid-cols-4 gap-6">
          {newProducts.map((p) => (
            <div key={p.id} className=" rounded-lg p-4 hover:shadow-[0_10px_15px_rgba(249,168,212,0.5)]">
              <Link href={`/product/${p.id}`}>
                <Image
                  src={p.img}
                  alt={p.name}
                  width={320}
                  height={240}
                  className="rounded-lg mb-3 object-cover"
                />
                <h3 className="text-center">{p.name}</h3>
                <p className="text-pink-500 text-center">
                  {p.sizes && p.sizes.length > 0 ? p.sizes[0].price.toLocaleString() : 'N/A'} VND
                </p>
              </Link>
            </div>
            ))}
          </div>
        </section>
      )}
      </div>
    </div>
  );
}
