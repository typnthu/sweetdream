// Temporary mock data for build
// TODO: Refactor pages to use API calls from @/lib/api instead

interface ProductSize {
  size: string;
  price: number;
}

interface Product {
  id: number;
  name: string;
  img: string;
  category: string;
  description: string;
  sizes: ProductSize[];
}

// Sample data for development
// TODO: Refactor pages to use API calls from @/lib/api instead
const products: Product[] = [
  {
    id: 1,
    name: "Bánh Mousse Dâu",
    img: "/placeholder.jpg",
    category: "Mousse",
    description: "Bánh mousse dâu tươi ngon",
    sizes: [
      { size: "Nhỏ", price: 150000 },
      { size: "Vừa", price: 250000 },
      { size: "Lớn", price: 350000 }
    ]
  },
  {
    id: 2,
    name: "Bánh Tiramisu",
    img: "/placeholder.jpg",
    category: "Tiramisu",
    description: "Bánh tiramisu Ý truyền thống",
    sizes: [
      { size: "Nhỏ", price: 180000 },
      { size: "Vừa", price: 280000 },
      { size: "Lớn", price: 380000 }
    ]
  },
  {
    id: 3,
    name: "Bánh Kem Socola",
    img: "/placeholder.jpg",
    category: "Kem",
    description: "Bánh kem socola đậm đà",
    sizes: [
      { size: "Nhỏ", price: 200000 },
      { size: "Vừa", price: 300000 },
      { size: "Lớn", price: 400000 }
    ]
  },
  {
    id: 4,
    name: "Bánh Mì Ngọt",
    img: "/placeholder.jpg",
    category: "Bread",
    description: "Bánh mì ngọt mềm mại",
    sizes: [
      { size: "Nhỏ", price: 50000 },
      { size: "Vừa", price: 80000 },
      { size: "Lớn", price: 120000 }
    ]
  },
  {
    id: 5,
    name: "Bánh Mousse Xoài",
    img: "/placeholder.jpg",
    category: "Mousse",
    description: "Bánh mousse xoài tươi mát",
    sizes: [
      { size: "Nhỏ", price: 160000 },
      { size: "Vừa", price: 260000 },
      { size: "Lớn", price: 360000 }
    ]
  },
  {
    id: 6,
    name: "Bánh Kem Dâu",
    img: "/placeholder.jpg",
    category: "Kem",
    description: "Bánh kem dâu tươi ngon",
    sizes: [
      { size: "Nhỏ", price: 190000 },
      { size: "Vừa", price: 290000 },
      { size: "Lớn", price: 390000 }
    ]
  },
  {
    id: 7,
    name: "Bánh Tiramisu Matcha",
    img: "/placeholder.jpg",
    category: "Tiramisu",
    description: "Bánh tiramisu matcha Nhật Bản",
    sizes: [
      { size: "Nhỏ", price: 200000 },
      { size: "Vừa", price: 300000 },
      { size: "Lớn", price: 400000 }
    ]
  },
  {
    id: 8,
    name: "Bánh Mousse Chanh Dây",
    img: "/placeholder.jpg",
    category: "Mousse",
    description: "Bánh mousse chanh dây chua ngọt",
    sizes: [
      { size: "Nhỏ", price: 170000 },
      { size: "Vừa", price: 270000 },
      { size: "Lớn", price: 370000 }
    ]
  }
];

export default products;
