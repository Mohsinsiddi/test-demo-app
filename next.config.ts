import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  webpack: (config) => {
    // Fix for @metamask/sdk issue with React Native async storage
    config.resolve.fallback = {
      ...config.resolve.fallback,
      "@react-native-async-storage/async-storage": false,
    };
    
    // Handle other potential issues
    config.externals.push("pino-pretty", "lokijs", "encoding");
    
    return config;
  },
};

export default nextConfig;
