"use client";
import { createContext, useContext, useState } from "react";

type CategoryContextType = {
  category: string;
  setCategory: (value: string) => void;
};

const CategoryContext = createContext<CategoryContextType | undefined>(undefined);

export function CategoryProvider({ children }: { children: React.ReactNode }) {
  const [category, setCategory] = useState<string>("Tất cả");

  return (
    <CategoryContext.Provider value={{ category, setCategory }}>
      {children}
    </CategoryContext.Provider>
  );
}

export const useCategory = () => {
  const context = useContext(CategoryContext);
  if (!context) throw new Error("useCategory must be used inside CategoryProvider");
  return context;
};
