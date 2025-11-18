"use client";

import Image from "next/image";
import Link from "next/link";
import { useCategory } from "@/context/CategoryContext";
import products from "@/products/index";

export default function ProductsPage() {
  const { category } = useCategory();

  // Lọc sản phẩm theo category
  const filteredProducts =
    category === "Tất cả"
      ? products
      : products.filter((p) => p.category === category);

  return (
    <div className="max-w-5xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6 text-pink-600">
        {category === "Tất cả"
          ? "Tất cả sản phẩm"
          : `${category}`}
      </h1>

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
                {p.sizes[0].price.toLocaleString()} VND
              </p>
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
}
