"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { useCategory } from "@/context/CategoryContext";
import { useCart } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { useRouter } from "next/navigation";
import { FaShoppingCart, FaUser, FaSignOutAlt } from "react-icons/fa";

interface Category {
  id: number;
  name: string;
}

export default function Navbar() {
  const { setCategory } = useCategory();
  const { cart } = useCart();
  const { user, isAuthenticated, logout } = useAuth();
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);

  // Fetch categories from API
  useEffect(() => {
    async function fetchCategories() {
      try {
        const response = await fetch("/api/proxy/categories");
        const data = await response.json();
        setCategories(data);
      } catch (error) {
        console.error("Failed to fetch categories:", error);
        // Fallback to default categories if API fails
        setCategories([
          { id: 0, name: "Tất cả" },
          { id: 1, name: "Bánh Mousse" },
          { id: 2, name: "Tiramisu" },
          { id: 3, name: "Bánh Kem" },
          { id: 4, name: "Bánh Nướng" },
        ]);
      }
    }
    fetchCategories();
  }, []);

  const totalQty = cart.reduce((sum, item) => sum + item.qty, 0);
  
  const handleSelectCategory = (categoryName: string) => {
    setCategory(categoryName); 
    router.push("/products");  
  };

  const handleUserIconClick = () => {
    if (isAuthenticated) {
      // If admin, go to admin panel; if customer, go to orders
      if (user?.role === 'admin') {
        router.push("/admin");
      } else {
        router.push("/success");
      }
    } else {
      router.push("/login");
    }
  };

  const handleLogout = () => {
    logout();
    router.push("/");
  };

  return (
    <nav className="w-full bg-white shadow-md sticky top-0 z-50">
      <div className="max-w-5xl mx-auto flex justify-between items-center py-4 px-6">

        {/* Logo + Menu left */}
        <div className="flex items-center space-x-6">
          <Link 
            href="/" 
            onClick={() => setCategory("Tất cả")} 
            className="text-2xl font-bold text-pink-600"
          >
            SweetDream🍰
          </Link>

          <Link 
            href="/" 
            onClick={() => setCategory("Tất cả")} 
            className="hover:text-pink-600 font-medium"
          >
            Trang Chủ
          </Link>

          {/* Dropdown */}
          <div className="group relative inline-block">
            <span className="hover:text-pink-600 cursor-pointer font-medium">Menu Bánh</span>
            
            <div className="absolute hidden group-hover:block bg-white shadow-lg w-44 z-20">
              {/* "Tất cả" option */}
              <button
                onClick={() => handleSelectCategory("Tất cả")}
                className="block w-full text-left px-4 py-2 hover:text-pink-500 font-medium"
              >
                Tất cả
              </button>
              
              {/* Dynamic categories from database */}
              {categories.map((category) => (
                <button
                  key={category.id}
                  onClick={() => handleSelectCategory(category.name)}
                  className="block w-full text-left px-4 py-2 hover:text-pink-500 font-medium"
                >
                  {category.name}
                </button>
              ))}
            </div>
          </div>

          {/* Admin Link - Only visible for admin users */}
          {isAuthenticated && user?.role === 'admin' && (
            <Link 
              href="/admin" 
              className="hover:text-pink-600 cursor-pointer font-medium"
            >
              Admin
            </Link>
          )}
        </div>

        {/* Icons right */}
        <div className="flex space-x-4 text-xl relative">
          <Link href="/cart" className="relative">
            <FaShoppingCart className="hover:text-pink-600" />
            {totalQty > 0 && (
              <span className="absolute -top-1 -right-2 bg-pink-500 text-white text-xs font-bold rounded-full w-4 h-4 flex items-center justify-center">
                {totalQty}
              </span>
            )}
          </Link>
          
          {/* User Menu */}
          <div className="relative">
            {isAuthenticated ? (
              <div className="group">
                <div className="flex items-center space-x-1 hover:text-pink-600 cursor-pointer">
                  <FaUser />
                  <span className="text-sm font-medium hidden md:block">{user?.name}</span>
                </div>
                
                <div className="absolute left-0  w-48 bg-white shadow-lg z-20 hidden group-hover:block">
                  <div className="p-3 bg-pink-50 border-pink-100">
                    <p className="font-medium text-sm text-gray-800">{user?.name}</p>
                    <p className="text-xs text-gray-600">{user?.email}</p>
                  </div>
                  <div className="py-1">
                    {/* Show Admin Panel button only for admin users */}
                    {user?.role === 'admin' && (
                      <button
                        onClick={() => router.push("/admin")}
                        className="w-full text-left px-4 py-2 text-sm hover:text-pink-500"
                      >
                        Admin Panel
                      </button>
                    )}
                    <button
                      onClick={() => router.push("/success")}
                      className="w-full text-left px-4 py-2 text-sm hover:text-pink-500"
                    >
                      Đơn hàng của tôi
                    </button>
                    <button
                      onClick={handleLogout}
                      className="w-full text-left px-4 py-2 text-sm hover:bg-gray-100 text-red-600 flex items-center"
                    >
                      <FaSignOutAlt className="mr-2" />
                      Đăng xuất
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <button onClick={handleUserIconClick}>
                <FaUser className="hover:text-pink-600" />
              </button>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
