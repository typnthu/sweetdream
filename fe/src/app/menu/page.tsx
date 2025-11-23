"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { getProducts, type Product } from "@/lib/api";

export default function MenuPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchProducts() {
      try {
        const data = await getProducts();
        setProducts(data);
      } catch (err) {
        console.error('Failed to fetch products:', err);
      } finally {
        setLoading(false);
      }
    }
    fetchProducts();
  }, []);

  // Group products by category
  const productsByCategory = products.reduce((acc, product) => {
    const categoryName = product.category.name;
    if (!acc[categoryName]) {
      acc[categoryName] = [];
    }
    acc[categoryName].push(product);
    return acc;
  }, {} as Record<string, Product[]>);

  return (
    <div className="max-w-5xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6 text-pink-600">Menu Bánh</h1>
      
      {loading ? (
        <p className="text-center py-10">Đang tải...</p>
      ) : (
        <div className="space-y-10">
          {Object.entries(productsByCategory).map(([categoryName, categoryProducts]) => (
            <div key={categoryName}>
              <h2 className="text-2xl font-bold mb-4 text-pink-500">{categoryName}</h2>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
                {categoryProducts.map((product) => (
                  <div key={product.id} className="border rounded-xl p-4 hover:shadow-lg">
                    <Link href={`/product/${product.id}`}>
                      <Image
                        src={product.img}
                        alt={product.name}
                        width={320}
                        height={240}
                        className="rounded-lg mb-3 object-cover"
                      />
                      <h3 className="font-semibold">{product.name}</h3>
                      <p className="text-pink-500 font-bold">
                        {product.sizes && product.sizes.length > 0 
                          ? `${Number(product.sizes[0].price).toLocaleString()} VND`
                          : 'N/A'}
                      </p>
                    </Link>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
