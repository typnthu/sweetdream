"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";

interface Product {
  id: number;
  name: string;
  description: string;
  img: string;
  category: { name: string };
  sizes: Array<{ size: string; price: string }>;
}

export default function ProductsListPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  useEffect(() => {
    fetchProducts();
  }, []);

  async function fetchProducts() {
    try {
      const response = await fetch("/api/proxy/products");
      const data = await response.json();
      setProducts(data);
    } catch (error) {
      console.error("Failed to fetch products:", error);
    } finally {
      setLoading(false);
    }
  }

  async function deleteProduct(id: number, name: string) {
    if (!confirm(`Bạn có chắc muốn xóa "${name}"?`)) return;

    try {
      const response = await fetch(`/api/proxy/products/${id}`, {
        method: "DELETE",
      });

      if (response.ok) {
        setMessage(`✅ Đã xóa "${name}"`);
        fetchProducts();
      } else {
        const error = await response.json();
        setMessage(`❌ ${error.message || error.error || 'Không thể xóa sản phẩm'}`);
      }
    } catch (error) {
      setMessage(`❌ Lỗi: ${error instanceof Error ? error.message : "Unknown"}`);
    }
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-pink-500">Danh sách sản phẩm</h1>
        <div className="space-x-3">
          <Link
            href="/admin/products"
            className="px-4 py-2 bg-pink-600 text-white rounded hover:bg-pink-700"
          >
            ➕ Thêm mới
          </Link>
        </div>
      </div>

      {message && (
        <div className={`p-4 mb-6 rounded ${message.includes("✅") ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
          {message}
        </div>
      )}

      {loading ? (
        <p className="text-center py-10">Đang tải...</p>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Hình ảnh</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tên</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Danh mục</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Giá</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Thao tác</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {products.map((product) => (
                <tr key={product.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <Image
                      src={product.img}
                      alt={product.name}
                      width={60}
                      height={60}
                      className="rounded object-cover"
                    />
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm font-medium text-gray-900">{product.name}</div>
                    <div className="text-sm text-gray-500">{product.description.substring(0, 50)}...</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="text-sm">
                      {product.category.name}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {product.sizes.length > 0 && (
                      <div>
                        {Number(product.sizes[0].price).toLocaleString()} VND
                        {product.sizes.length > 1 && <span className="text-gray-400"> (+{product.sizes.length - 1})</span>}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                    <Link
                      href={`/product/${product.id}`}
                      className="text-blue-600 hover:text-blue-900"
                      target="_blank"
                    >
                      Xem
                    </Link>
                    <button
                      onClick={() => deleteProduct(product.id, product.name)}
                      className="text-red-600 hover:text-red-900"
                    >
                      Xóa
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {products.length === 0 && (
            <div className="text-center py-10 text-gray-500">
              Chưa có sản phẩm nào
            </div>
          )}
        </div>
      )}

      <div className="mt-4 text-sm text-gray-600">
        Tổng số: <span className="font-semibold">{products.length}</span> sản phẩm
      </div>
    </div>
  );
}
