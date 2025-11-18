"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { useCategory } from "@/context/CategoryContext";
import { getProducts, type Product } from "@/lib/api";

export default function ProductsPage() {
  const { category } = useCategory();
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

  // Lọc sản phẩm theo category
  const filteredProducts =
    category === "Tất cả"
      ? products
      : products.filter((p) => p.category.name === category);

  return (
    <div className="max-w-5xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6 text-pink-600">
        {category === "Tất cả"
          ? "Tất cả sản phẩm"
          : `${category}`}
      </h1>

      {loading && (
        <div className="text-center py-10">
          <p className="text-gray-600">Đang tải sản phẩm...</p>
        </div>
      )}

      {error && (
        <div className="text-center py-10">
          <p className="text-red-600">{error}</p>
        </div>
      )}

      {!loading && !error && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
          {filteredProducts.map((p) => (
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
                {p.sizes && p.sizes.length > 0 ? p.sizes[0].price.toLocaleString() : 'N/A'} VND
              </p>
            </Link>
          </div>
          ))}
        </div>
      )}
    </div>
  );
}
