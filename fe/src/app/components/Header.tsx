import Image from "next/image";
import Link from "next/link";

export default function Header() {
  return (
    <header className="bg-pink-50 py-6 px-4 text-center">
      <div className="max-w-3xl mx-auto flex flex-col items-center">

        {/* <h2 className="text-3xl font-bold text-pink-600 mb-2">
          Chào mừng đến với SweetDreams 🍰
        </h2> */}

        <p className="text-2xl font-bold text-pink-700">Ngọt ngào mỗi ngày</p>
        {/* <p className="text-gray-600 max-w-lg mb-4 text-base">
          Tiệm bánh ngọt xinh xắn với những chiếc bánh tươi ngon mỗi ngày,
          đem đến hương vị ngọt ngào cho mọi khoảnh khắc của bạn!
        </p> */}

        {/* Nút optional */}
        {/* <Link
          href="/"
          className="bg-pink-500 text-white px-5 py-2 rounded-lg shadow-md hover:bg-pink-600 transition"
        >
          Xem Menu Bánh
        </Link> */}
      </div>
    </header>
  );
}
