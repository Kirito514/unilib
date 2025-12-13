import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  output: 'standalone', // Required for Docker deployment
  reactCompiler: true,

  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60,
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
      },
    ],
  },

  // Performance optimizations
  compress: true,
  poweredByHeader: false,

  // Experimental features for better performance
  experimental: {
    optimizePackageImports: ['lucide-react', '@supabase/supabase-js'],
  },
};

export default nextConfig;
