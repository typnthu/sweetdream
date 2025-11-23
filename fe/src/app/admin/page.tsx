"use client";

import Link from "next/link";
import { useAuth } from "@/context/AuthContext";
import { useRouter } from "next/navigation";

export default function AdminDashboard() {
  const { user, logout } = useAuth();
  const router = useRouter();

  const handleLogout = () => {
    logout();
    router.push('/');
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto p-6">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-2xl font-bold text-pink-500">Admin Dashboard</h1>
          </div>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Products Management */}
          <Link href="/admin/products" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-pink-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">🍰</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Sản phẩm</h2>
            </div>
            <p className="text-gray-600">Quản lý sản phẩm, thêm, sửa, xóa bánh</p>
          </Link>

          {/* Products List */}
          <Link href="/admin/products/list" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">📋</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Danh sách SP</h2>
            </div>
            <p className="text-gray-600">Xem và chỉnh sửa tất cả sản phẩm</p>
          </Link>

          {/* Orders Management */}
          <Link href="/admin/orders" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">📦</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Đơn hàng</h2>
            </div>
            <p className="text-gray-600">Quản lý đơn hàng và trạng thái</p>
          </Link>

          {/* Customers Management */}
          <Link href="/admin/customers" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">👥</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Khách hàng</h2>
            </div>
            <p className="text-gray-600">Xem thông tin khách hàng</p>
          </Link>

          {/* Categories Management */}
          <Link href="/admin/categories" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">📁</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Danh mục</h2>
            </div>
            <p className="text-gray-600">Quản lý danh mục sản phẩm</p>
          </Link>

          {/* Database Management */}
          <Link href="/admin/migrate" className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <span className="text-2xl">🗄️</span>
              </div>
              <h2 className="text-xl font-semibold ml-4 text-pink-500">Database</h2>
            </div>
            <p className="text-gray-600">Migration và seed database</p>
          </Link>
        </div>
      </div>
    </div>
  );
}
