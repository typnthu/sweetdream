"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function Register() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to login page (which handles both login and register)
    router.push("/login");
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50">
      <div className="text-center">
        <p className="text-gray-600">Đang chuyển hướng...</p>
      </div>
    </div>
  );
}
