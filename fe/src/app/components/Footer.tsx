import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-pink-50 py-8 text-center text-pink-600 mt-auto ">
      <p className="font-semibold text-lg text-pink-600"> SweetDream Bakery</p>
      <p className="font-semibold text-s text-pink-400">Tình yêu 💗 bột mì</p>
      <div className="flex justify-center gap-6 my-3 text-sm">
        <Link className="hover:text-pink-500" href="/">Trang chủ</Link>
        <Link className="hover:text-pink-500" href="/menu">Menu bánh</Link>
        <Link className="hover:text-pink-500" href="/about">Giới thiệu</Link>
        <Link className="hover:text-pink-500" href="/contact">Liên hệ</Link>
      </div>

      <p className="text-xs text-gray-500">
        © {new Date().getFullYear()} SweetDream Bakery. All rights reserved. 
      </p>
    </footer>
  );
} 
