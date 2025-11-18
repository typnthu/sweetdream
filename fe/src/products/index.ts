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

// Empty array - pages should be refactored to fetch from API
const products: Product[] = [];

export default products;
