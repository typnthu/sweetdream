"use client";

import { useState, useEffect } from "react";

interface Category {
  id: number;
  name: string;
}

export default function AdminProductsPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    img: "",
    categoryId: "",
    sizes: [{ size: "", price: "" }],
  });

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

  function addSize() {
    setFormData({
      ...formData,
      sizes: [...formData.sizes, { size: "", price: "" }],
    });
  }

  function removeSize(index: number) {
    const newSizes = formData.sizes.filter((_, i) => i !== index);
    setFormData({ ...formData, sizes: newSizes });
  }

  function updateSize(index: number, field: "size" | "price", value: string) {
    const newSizes = [...formData.sizes];
    newSizes[index][field] = value;
    setFormData({ ...formData, sizes: newSizes });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage("");

    try {
      const response = await fetch("/api/proxy/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: formData.name,
          description: formData.description,
          img: formData.img,
          categoryId: parseInt(formData.categoryId),
          sizes: formData.sizes.map((s) => ({
            size: s.size,
            price: parseFloat(s.price),
          })),
        }),
      });

      if (response.ok) {
        setMessage("✅ Sản phẩm đã được thêm thành công!");
        setFormData({
          name: "",
          description: "",
          img: "",
          categoryId: "",
          sizes: [{ size: "", price: "" }],
        });
      } else {
        const error = await response.json();
        setMessage(`❌ Lỗi: ${error.error || "Không thể thêm sản phẩm"}`);
      }
    } catch (error) {
      setMessage(`❌ Lỗi: ${error instanceof Error ? error.message : "Unknown error"}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-4xl mx-auto p-6">

      <form onSubmit={handleSubmit} className="space-y-6 bg-white p-6 rounded-lg shadow">
        <div>
          <label className="block text-sm font-medium mb-2">Tên sản phẩm *</label>
          <input
            type="text"
            required
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
            placeholder="Ví dụ: Bánh Mousse Dâu"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">Mô tả *</label>
          <textarea
            required
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            rows={3}
            className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
            placeholder="Mô tả chi tiết về sản phẩm"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">URL hình ảnh *</label>
          <input
            type="url"
            required
            value={formData.img}
            onChange={(e) => setFormData({ ...formData, img: e.target.value })}
            className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
            placeholder="https://sweetdream-products-data.s3.us-east-1.amazonaws.com/cake1.jpg"
          />
          <p className="text-sm text-gray-500 mt-1">
            Upload ảnh lên S3 bucket: sweetdream-products-data
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">Danh mục *</label>
          <select
            required
            value={formData.categoryId}
            onChange={(e) => setFormData({ ...formData, categoryId: e.target.value })}
            className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
          >
            <option value="">-- Chọn danh mục --</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <div className="flex justify-between items-center mb-2">
            <label className="block text-sm font-medium">Kích thước & Giá *</label>
            <button
              type="button"
              onClick={addSize}
              className="px-3 py-1 bg-pink-500 text-white text-sm rounded hover:bg-pink-600"
            >
              + Thêm kích thước
            </button>
          </div>
          
          <div className="space-y-3">
            {formData.sizes.map((size, index) => (
              <div key={index} className="flex gap-3">
                <input
                  type="text"
                  required
                  value={size.size}
                  onChange={(e) => updateSize(index, "size", e.target.value)}
                  className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  placeholder="Ví dụ: 12cm, Nhỏ, M"
                />
                <input
                  type="number"
                  required
                  value={size.price}
                  onChange={(e) => updateSize(index, "price", e.target.value)}
                  className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  placeholder="Giá (VND)"
                />
                {formData.sizes.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeSize(index)}
                    className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
                  >
                    Xóa
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full py-3 bg-pink-500 text-white font-semibold rounded-lg hover:bg-pink-600 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          {loading ? "Đang thêm..." : "Thêm sản phẩm"}
        </button>
      </form>
    </div>
  );
}
