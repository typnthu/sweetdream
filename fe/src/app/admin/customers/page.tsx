"use client";

import { useState, useEffect } from "react";
import Link from "next/link";

interface Customer {
  id: number;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  createdAt: string;
  _count?: {
    orders: number;
  };
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    fetchCustomers();
    
    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      fetchCustomers();
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  async function fetchCustomers() {
    try {
      setLoading(true);
      const response = await fetch("/api/proxy/customers?limit=100");
      const data = await response.json();
      // Handle both paginated and non-paginated responses
      setCustomers(data.customers || data);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Failed to fetch customers:", error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Danh sách khách hàng</h1>
          <p className="text-sm text-gray-500 mt-1">
            Cập nhật lần cuối: {lastUpdated.toLocaleTimeString("vi-VN")}
          </p>
        </div>
        <div className="space-x-3">
          <button
            onClick={fetchCustomers}
            disabled={loading}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
          >
            {loading ? "Đang tải..." : "🔄 Làm mới"}
          </button>
        </div>
      </div>

      {loading ? (
        <p className="text-center py-10">Đang tải...</p>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tên</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Số điện thoại</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Địa chỉ</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Đơn hàng</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ngày tạo</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {customers.map((customer) => (
                <tr key={customer.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {customer.id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{customer.name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {customer.email}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {customer.phone || "-"}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {customer.address ? (
                      <div className="max-w-xs truncate" title={customer.address}>
                        {customer.address}
                      </div>
                    ) : "-"}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {customer._count?.orders || 0}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(customer.createdAt).toLocaleDateString("vi-VN")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {customers.length === 0 && (
            <div className="text-center py-10 text-gray-500">
              Chưa có khách hàng nào
            </div>
          )}
        </div>
      )}

      <div className="mt-4 text-sm text-gray-600">
        Tổng số: <span className="font-semibold">{customers.length}</span> khách hàng
      </div>
    </div>
  );
}
