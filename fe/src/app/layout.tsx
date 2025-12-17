import "./globals.css";
import Navbar from "./components/Navbar";
import Footer from "./components/Footer";
import Header from "./components/Header";
import { CategoryProvider } from "../context/CategoryContext";
import { CartProvider } from "../context/CartContext";
import { OrderProvider } from "../context/OrderContext";
import { AuthProvider } from "../context/AuthContext";

import type { Metadata } from 'next'; 

export const metadata: Metadata = {
  title: 'Demo SweetDream Bakery - Bánh Kem Tươi Ngon',
  description: 'SweetDream chuyên các loại bánh ngọt thơm ngon, được làm từ nguyên liệu tươi sạch. Bánh mousse, tiramisu, bánh kem, bánh mì ngọt.',
  icons: {
    icon: [
      { url: '/shortcut.png' },
      { url: '/shortcut.png', sizes: '32x32', type: 'image/png' },
    ],
    shortcut: '/shortcut.png',
    apple: '/shortcut.png',
  }
}
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="flex flex-col min-h-screen">
        <AuthProvider>
          <CartProvider> 
            <OrderProvider> 
              <CategoryProvider> 
                <Header />
                <Navbar />
                <main className="flex-grow">
                  {children}
                </main>
                <Footer />
              </CategoryProvider>
            </OrderProvider>
          </CartProvider>
        </AuthProvider>
      </body>
    </html>
  );
}

