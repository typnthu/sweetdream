import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-gray-100 py-8 mt-12 border-t text-center text-gray-600">
      <p className="font-semibold text-lg text-pink-600"> SweetDream Bakery 🍰</p>
      <p className="font-semibold text-s text-pink-400">Tình yêu & bột mì 🧁💗</p>
      <div className="flex justify-center gap-6 my-3 text-sm">
        <Link className="hover:text-pink-500" href="/">Trang chủ</Link>
        <Link className="hover:text-pink-500" href="/menu">Menu bánh</Link>
        <Link className="hover:text-pink-500" href="/about">Giới thiệu</Link>
        <Link className="hover:text-pink-500" href="/contact">Liên hệ</Link>
      </div>

      <p className="text-xs">
        © {new Date().getFullYear()} Sweet Cake. All rights reserved. 
      </p>
    </footer>
  );
} 
