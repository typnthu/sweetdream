"use client";

import { useState, useEffect } from "react";

interface Category {
  id: number;
  name: string;
  description?: string;
  _count?: {
    products: number;
  };
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: "", description: "" });

  useEffect(() => {
    fetchCategories();
  }, []);

  async function fetchCategories() {
    try {
      const response = await fetch("/api/proxy/categories");
      const data = await response.json();
      setCategories(data);
    } catch (error) {
      console.error("Failed to fetch categories:", error);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage("");

    try {
      const response = await fetch("/api/proxy/categories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        setMessage("✅ Đã thêm danh mục mới");
        setFormData({ name: "", description: "" });
        setShowForm(false);
        fetchCategories();
      } else {
        const error = await response.json();
        setMessage(`❌ Lỗi: ${error.error || "Không thể thêm danh mục"}`);
      }
    } catch (error) {
      setMessage(`❌ Lỗi: ${error instanceof Error ? error.message : "Unknown"}`);
    } finally {
      setLoading(false);
    }
  }

  async function deleteCategory(id: number, name: string) {
    if (!confirm(`Bạn có chắc muốn xóa danh mục "${name}"?`)) return;

    try {
      const response = await fetch(`/api/proxy/categories/${id}`, {
        method: "DELETE",
      });

      if (response.ok) {
        setMessage(`✅ Đã xóa danh mục "${name}"`);
        fetchCategories();
      } else {
        setMessage(`❌ Không thể xóa danh mục (có thể còn sản phẩm)`);
      }
    } catch (error) {
      setMessage(`❌ Lỗi: ${error instanceof Error ? error.message : "Unknown"}`);
    }
  }

  return (
    <div className="max-w-5xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Quản lý danh mục</h1>
        <div className="space-x-3">
          <button
            onClick={() => setShowForm(!showForm)}
            className="px-4 py-2 bg-pink-600 text-white rounded hover:bg-pink-700"
          >
            {showForm ? "Đóng" : "➕ Thêm danh mục"}
          </button>
        </div>
      </div>

      {message && (
        <div className={`p-4 mb-6 rounded ${message.includes("✅") ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
          {message}
        </div>
      )}

      {showForm && (
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Thêm danh mục mới</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2">Tên danh mục *</label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Ví dụ: Bánh Tart"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Mô tả</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={2}
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Mô tả về danh mục"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full py-2 bg-pink-500 text-white font-semibold rounded-lg hover:bg-pink-600 disabled:bg-gray-400"
            >
              {loading ? "Đang thêm..." : "Thêm danh mục"}
            </button>
          </form>
        </div>
      )}

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tên</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Mô tả</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Số sản phẩm</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Thao tác</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {categories.map((category) => (
              <tr key={category.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {category.id}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">{category.name}</div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {category.description || "-"}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {category._count?.products || 0}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <button
                    onClick={() => deleteCategory(category.id, category.name)}
                    className="text-red-600 hover:text-red-900"
                    disabled={category._count && category._count.products > 0}
                    title={category._count && category._count.products > 0 ? "Không thể xóa danh mục có sản phẩm" : ""}
                  >
                    Xóa
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {categories.length === 0 && (
          <div className="text-center py-10 text-gray-500">
            Chưa có danh mục nào
          </div>
        )}
      </div>

      <div className="mt-4 text-sm text-gray-600">
        Tổng số: <span className="font-semibold">{categories.length}</span> danh mục
      </div>
    </div>
  );
}
