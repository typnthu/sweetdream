"use client";
import { useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "@/context/AuthContext";
import Link from "next/link";

function LoginForm() {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    phone: "",
    address: ""
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const { login, register } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirect') || '/success';

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setError("");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      let success = false;

      if (isLogin) {
        if (!formData.email || !formData.password) {
          setError("Vui lòng nhập đầy đủ email và mật khẩu!");
          setLoading(false);
          return;
        }
        success = await login(formData.email, formData.password);
        if (!success) {
          setError("Email hoặc mật khẩu không đúng!");
        }
      } else {
        if (!formData.name || !formData.email || !formData.password) {
          setError("Vui lòng điền đầy đủ thông tin bắt buộc!");
          setLoading(false);
          return;
        }
        success = await register(formData);
        if (!success) {
          setError("Email đã tồn tại!");
        }
      }

      if (success) {
        router.push(redirectTo);
      }
    } catch (error) {
      setError("Có lỗi xảy ra, vui lòng thử lại!");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8">
        {/* Header */}
        <div className="text-center mb-8">
          <Link href="/" className="text-3xl font-bold text-pink-600 mb-4 block">
            SweetDream🍰
          </Link>
          <h2 className="text-2xl font-bold text-gray-800">
            {isLogin ? "Đăng nhập" : "Đăng ký"}
          </h2>
          <p className="text-gray-600 mt-2">
            {isLogin ? "Chào mừng bạn trở lại!" : "Tạo tài khoản mới"}
          </p>
        </div>

        {/* Demo Account Info */}
        {isLogin && (
          <div className="mb-6 p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-700 font-medium mb-2">Tài khoản demo:</p>
            <p className="text-sm text-blue-600">Email: user@example.com</p>
            <p className="text-sm text-blue-600">Mật khẩu: 123456</p>
          </div>
        )}

        {/* Error Message */}
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-600 text-sm">{error}</p>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {!isLogin && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Họ và tên *
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="Nhập họ và tên"
                required={!isLogin}
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email *
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="Nhập email"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Mật khẩu *
            </label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="Nhập mật khẩu"
              required
            />
          </div>

          {!isLogin && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Số điện thoại
                </label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleInputChange}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  placeholder="Nhập số điện thoại"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Địa chỉ
                </label>
                <textarea
                  name="address"
                  value={formData.address}
                  onChange={handleInputChange}
                  rows={3}
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  placeholder="Nhập địa chỉ"
                />
              </div>
            </>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? "Đang xử lý..." : (isLogin ? "Đăng nhập" : "Đăng ký")}
          </button>
        </form>

        {/* Toggle Form */}
        <div className="mt-6 text-center">
          <p className="text-gray-600">
            {isLogin ? "Chưa có tài khoản?" : "Đã có tài khoản?"}
            <button
              onClick={() => {
                setIsLogin(!isLogin);
                setError("");
                setFormData({
                  name: "",
                  email: "",
                  password: "",
                  phone: "",
                  address: ""
                });
              }}
              className="ml-2 text-pink-600 hover:text-pink-700 font-medium"
            >
              {isLogin ? "Đăng ký ngay" : "Đăng nhập"}
            </button>
          </p>
        </div>

        {/* Back to Home */}
        <div className="mt-4 text-center">
          <Link
            href="/"
            className="text-gray-500 hover:text-gray-700 text-sm"
          >
            ← Quay về trang chủ
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function Login() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Đang tải...</p>
        </div>
      </div>
    }>
      <LoginForm />
    </Suspense>
  );
}
