/**
 * Format price to Vietnamese format: 15.000đ
 * @param price - Price in VND
 * @returns Formatted price string
 */
export function formatPrice(price: number | string): string {
  const numPrice = typeof price === 'string' ? parseFloat(price) : price;
  return numPrice.toLocaleString('vi-VN') + 'đ';
}
