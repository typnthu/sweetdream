import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactCompiler: true,
  output: 'standalone',
  
  // Environment variables for API connection
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
  },
  
  // Allow images from S3 bucket and external sources
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'sweetdream-products-data.s3.us-east-1.amazonaws.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: '*.s3.us-east-1.amazonaws.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'file.hstatic.net',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: '*.hstatic.net',
        pathname: '/**',
      },
    ],
  },
};

export default nextConfig;
