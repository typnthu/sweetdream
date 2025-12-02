"use client";
import { useAuth } from "@/context/AuthContext";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

interface AuthGuardProps {
  children: React.ReactNode;
  redirectTo?: string;
  showLoginPrompt?: boolean;
}

export default function AuthGuard({ 
  children, 
  redirectTo = "/login",
  showLoginPrompt = false 
}: AuthGuardProps) {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated && !showLoginPrompt) {
      const currentPath = window.location.pathname;
      router.push(`${redirectTo}?redirect=${encodeURIComponent(currentPath)}`);
    }
  }, [isAuthenticated, isLoading, redirectTo, router, showLoginPrompt]);

  // Show loading state while checking authentication
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Đang tải...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated && showLoginPrompt) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
        <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8 text-center">
          <div className="text-6xl mb-4">🔒</div>
          <h2 className="text-2xl font-bold text-gray-800 mb-4">
            Yêu cầu đăng nhập
          </h2>
          <p className="text-gray-600 mb-6">
            Bạn cần đăng nhập để sử dụng tính năng này
          </p>
          <div className="space-y-3">
            <button
              onClick={() => {
                const currentPath = window.location.pathname;
                router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
              }}
              className="w-full bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 transition font-semibold"
            >
              Đăng nhập ngay
            </button>
            <button
              onClick={() => router.push("/")}
              className="w-full border border-gray-300 text-gray-700 py-3 rounded-lg hover:bg-gray-50 transition"
            >
              Quay về trang chủ
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // Will redirect
  }

  return <>{children}</>;
}