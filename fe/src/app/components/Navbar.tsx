"use client";

import Link from "next/link";

import { useCategory } from "@/context/CategoryContext";
import { useCart } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { useRouter } from "next/navigation";
import { FaShoppingCart, FaUser, FaSignOutAlt } from "react-icons/fa";
import { useState } from "react";

export default function Navbar() {
  const { setCategory } = useCategory();
  const { cart } = useCart();
  const { user, isAuthenticated, logout } = useAuth();
  const router = useRouter();
  const [showUserMenu, setShowUserMenu] = useState(false);

  const categories = [
    "Tất cả",
    "Bánh Mousse",
    "Tiramisu",
    "Bánh Kem",
    "Bánh Nướng",
  ];

  const totalQty = cart.reduce((sum, item) => sum + item.qty, 0);
  
  const handleSelectCategory = (c: string) => {
    setCategory(c); 
    router.push("/products");  
  };

  const handleUserIconClick = () => {
    if (isAuthenticated) {
      router.push("/success");
    } else {
      router.push("/login");
    }
  };

  const handleLogout = () => {
    logout();
    setShowUserMenu(false);
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
              {categories.map((c) => (
                <button
                  key={c}
                  onClick={() => handleSelectCategory(c)}
                  className="block w-full text-left px-4 py-2 hover:text-pink-500 font-medium"
                >
                  {c}
                </button>
              ))}
            </div>
          </div>
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
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="flex items-center space-x-1 hover:text-pink-600"
                >
                  <FaUser />
                  <span className="text-sm font-medium hidden md:block">{user?.name}</span>
                </button>
                
                {showUserMenu && (
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border z-20">
                    <div className="p-3 border-b">
                      <p className="font-medium text-gray-800">{user?.name}</p>
                      <p className="text-sm text-gray-600">{user?.email}</p>
                    </div>
                    <div className="py-1">
                      <button
                        onClick={() => {
                          setShowUserMenu(false);
                          router.push("/success");
                        }}
                        className="w-full text-left px-4 py-2 text-sm hover:bg-gray-100"
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
                )}
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
