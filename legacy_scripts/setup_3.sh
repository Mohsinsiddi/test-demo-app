#!/bin/bash

echo "🚀 BasePay Hooks & Seed Data Setup"
echo "==================================="

# Create directories
mkdir -p app/api/feed_data
mkdir -p hooks

# ============================================
# API: FEED_DATA - Seed Database with Demo Data
# ============================================
echo "📝 Creating app/api/feed_data/route.ts..."
cat > app/api/feed_data/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { UserType, UserTier } from '@/types';

// Demo Stores Data
const DEMO_STORES = [
  {
    wallet: '0x1000000000000000000000000000000000000001',
    userType: UserType.Store,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '150000000000000000000',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'TechStore Official',
    username: 'techstore',
    bio: 'Your one-stop shop for premium tech gadgets and accessories',
    storeName: 'TechStore Official',
    storeCategory: 'tech',
    location: 'Mumbai, India',
    kycStatus: 'verified' as const,
    avatar: '📱',
  },
  {
    wallet: '0x1000000000000000000000000000000000000002',
    userType: UserType.Store,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '85000000000000000000',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Fashion Hub',
    username: 'fashionhub',
    bio: 'Trendy fashion for the modern you',
    storeName: 'Fashion Hub',
    storeCategory: 'fashion',
    location: 'Delhi, India',
    kycStatus: 'verified' as const,
    avatar: '👗',
  },
  {
    wallet: '0x1000000000000000000000000000000000000003',
    userType: UserType.Store,
    tier: UserTier.Anonymous,
    isActive: true,
    totalSales: '25000000000000000000',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Foodie Corner',
    username: 'foodiecorner',
    bio: 'Authentic homemade snacks and sweets',
    storeName: 'Foodie Corner',
    storeCategory: 'food',
    location: 'Bangalore, India',
    kycStatus: 'pending' as const,
    avatar: '🍔',
  },
  {
    wallet: '0x1000000000000000000000000000000000000004',
    userType: UserType.Store,
    tier: UserTier.Premium,
    isActive: true,
    totalSales: '500000000000000000000',
    hasCustomFee: true,
    customFee: 50,
    displayName: 'Artisan Crafts',
    username: 'artisancrafts',
    bio: 'Handcrafted with love - unique art pieces',
    storeName: 'Artisan Crafts',
    storeCategory: 'art',
    location: 'Jaipur, India',
    kycStatus: 'verified' as const,
    avatar: '🎨',
  },
  {
    wallet: '0x1000000000000000000000000000000000000005',
    userType: UserType.Store,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '120000000000000000000',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Beauty Bliss',
    username: 'beautybliss',
    bio: 'Premium skincare and beauty products',
    storeName: 'Beauty Bliss',
    storeCategory: 'beauty',
    location: 'Hyderabad, India',
    kycStatus: 'verified' as const,
    avatar: '💄',
  },
];

// Demo Creators Data
const DEMO_CREATORS = [
  {
    wallet: '0x2000000000000000000000000000000000000001',
    userType: UserType.Creator,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '0',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Tech Guru',
    username: 'techguru',
    bio: 'Making tech simple for everyone 🚀',
    youtube: 'https://youtube.com/@techguru',
    instagram: 'https://instagram.com/techguru',
    kycStatus: 'verified' as const,
    avatar: '👨‍💻',
  },
  {
    wallet: '0x2000000000000000000000000000000000000002',
    userType: UserType.Creator,
    tier: UserTier.Premium,
    isActive: true,
    totalSales: '0',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Foodie Adventures',
    username: 'foodieadv',
    bio: 'Exploring food one bite at a time 🍕',
    youtube: 'https://youtube.com/@foodieadv',
    instagram: 'https://instagram.com/foodieadv',
    kycStatus: 'verified' as const,
    avatar: '🍳',
  },
  {
    wallet: '0x2000000000000000000000000000000000000003',
    userType: UserType.Creator,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '0',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Fitness First',
    username: 'fitnessfirst',
    bio: 'Your daily dose of fitness motivation 💪',
    youtube: 'https://youtube.com/@fitnessfirst',
    instagram: 'https://instagram.com/fitnessfirst',
    kycStatus: 'verified' as const,
    avatar: '🏋️',
  },
  {
    wallet: '0x2000000000000000000000000000000000000004',
    userType: UserType.Creator,
    tier: UserTier.Anonymous,
    isActive: true,
    totalSales: '0',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Travel Tales',
    username: 'traveltales',
    bio: 'Wanderlust and adventures ✈️',
    youtube: 'https://youtube.com/@traveltales',
    instagram: 'https://instagram.com/traveltales',
    kycStatus: 'pending' as const,
    avatar: '✈️',
  },
  {
    wallet: '0x2000000000000000000000000000000000000005',
    userType: UserType.Creator,
    tier: UserTier.Verified,
    isActive: true,
    totalSales: '0',
    hasCustomFee: false,
    customFee: 0,
    displayName: 'Gaming Zone',
    username: 'gamingzone',
    bio: 'Pro gamer | Streamer | Content Creator 🎮',
    youtube: 'https://youtube.com/@gamingzone',
    twitter: 'https://twitter.com/gamingzone',
    kycStatus: 'verified' as const,
    avatar: '🎮',
  },
];

// Demo Products Data
const DEMO_PRODUCTS = [
  {
    seller: '0x1000000000000000000000000000000000000001',
    price: '2999000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Premium Wireless Headphones',
    description: 'High-quality wireless headphones with active noise cancellation, 30-hour battery life, and premium sound quality.',
    images: ['🎧'],
    category: 'tech',
    stock: 15,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 234,
  },
  {
    seller: '0x1000000000000000000000000000000000000001',
    price: '1499000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Smart Watch Pro',
    description: 'Track your fitness, receive notifications, and stay connected with this sleek smartwatch.',
    images: ['⌚'],
    category: 'tech',
    stock: 25,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 189,
  },
  {
    seller: '0x1000000000000000000000000000000000000001',
    price: '999000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Portable Bluetooth Speaker',
    description: 'Waterproof, 20W output, 12-hour battery. Perfect for outdoor adventures.',
    images: ['🔊'],
    category: 'tech',
    stock: 30,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 156,
  },
  {
    seller: '0x1000000000000000000000000000000000000002',
    price: '1299000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Designer Denim Jacket',
    description: 'Premium quality denim jacket with modern fit. Available in all sizes.',
    images: ['🧥'],
    category: 'fashion',
    stock: 20,
    deliveryOptions: { pickup: false, shipping: true },
    likes: 312,
  },
  {
    seller: '0x1000000000000000000000000000000000000002',
    price: '799000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Classic White Sneakers',
    description: 'Comfortable, stylish, and perfect for everyday wear.',
    images: ['👟'],
    category: 'fashion',
    stock: 45,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 278,
  },
  {
    seller: '0x1000000000000000000000000000000000000003',
    price: '299000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Assorted Indian Sweets Box',
    description: 'Handmade traditional Indian sweets - perfect for gifting. 500g box.',
    images: ['🍬'],
    category: 'food',
    stock: 50,
    deliveryOptions: { pickup: true, shipping: false },
    likes: 445,
  },
  {
    seller: '0x1000000000000000000000000000000000000003',
    price: '199000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Spicy Namkeen Mix',
    description: 'Crunchy, spicy, and addictive! Made fresh daily. 250g pack.',
    images: ['🥨'],
    category: 'food',
    stock: 100,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 523,
  },
  {
    seller: '0x1000000000000000000000000000000000000004',
    price: '4999000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Hand-Painted Canvas Art',
    description: 'Original abstract art piece, 24x36 inches. Each piece is unique.',
    images: ['🖼️'],
    category: 'art',
    stock: 5,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 167,
  },
  {
    seller: '0x1000000000000000000000000000000000000004',
    price: '1999000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Handcrafted Pottery Set',
    description: 'Set of 4 ceramic cups with saucers. Traditional blue pottery design.',
    images: ['🏺'],
    category: 'art',
    stock: 12,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 198,
  },
  {
    seller: '0x1000000000000000000000000000000000000005',
    price: '1599000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Premium Skincare Kit',
    description: 'Complete skincare routine - cleanser, toner, serum, and moisturizer.',
    images: ['🧴'],
    category: 'beauty',
    stock: 35,
    deliveryOptions: { pickup: false, shipping: true },
    likes: 389,
  },
  {
    seller: '0x1000000000000000000000000000000000000005',
    price: '699000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Natural Lip Balm Set',
    description: 'Set of 5 flavored lip balms - 100% organic ingredients.',
    images: ['💋'],
    category: 'beauty',
    stock: 60,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 267,
  },
  {
    seller: '0x1000000000000000000000000000000000000001',
    price: '3499000000000000000000',
    paymentToken: '0x0000000000000000000000000000000000000000',
    isActive: true,
    metadataUri: '',
    title: 'Mechanical Gaming Keyboard',
    description: 'RGB backlit, Cherry MX switches, premium build quality.',
    images: ['⌨️'],
    category: 'tech',
    stock: 18,
    deliveryOptions: { pickup: true, shipping: true },
    likes: 412,
  },
];

// Demo Content Data
const DEMO_CONTENT = [
  {
    creator: '0x2000000000000000000000000000000000000001',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo1',
    title: 'Building the Future of Web3 Commerce',
    description: 'In this video, I explain how blockchain is revolutionizing online shopping.',
    thumbnail: '▶️',
    category: 'tech',
    suggestedTip: '100000000000000000',
    likes: 1245,
    tips: '5000000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000001',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo2',
    title: 'Top 10 Crypto Wallets in 2024',
    description: 'Complete guide to choosing the best crypto wallet for your needs.',
    thumbnail: '💳',
    category: 'tech',
    suggestedTip: '50000000000000000',
    likes: 2356,
    tips: '8500000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000002',
    platform: 'instagram' as const,
    url: 'https://instagram.com/p/demo1',
    title: 'Street Food Tour - Mumbai Edition',
    description: 'Join me as I explore the best street food in Mumbai! 🍕',
    thumbnail: '📸',
    category: 'food',
    suggestedTip: '25000000000000000',
    likes: 5623,
    tips: '3200000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000002',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo3',
    title: 'Making Authentic Biryani at Home',
    description: 'Step-by-step recipe for the perfect Hyderabadi biryani.',
    thumbnail: '🍚',
    category: 'food',
    suggestedTip: '75000000000000000',
    likes: 8934,
    tips: '12000000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000003',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo4',
    title: '30-Day Transformation Challenge',
    description: 'Complete workout plan for beginners. No equipment needed!',
    thumbnail: '💪',
    category: 'lifestyle',
    suggestedTip: '100000000000000000',
    likes: 12456,
    tips: '25000000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000003',
    platform: 'instagram' as const,
    url: 'https://instagram.com/p/demo2',
    title: 'Morning Yoga Routine',
    description: '15-minute yoga flow to start your day right ☀️',
    thumbnail: '🧘',
    category: 'lifestyle',
    suggestedTip: '50000000000000000',
    likes: 7823,
    tips: '4500000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000004',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo5',
    title: 'Hidden Gems of Rajasthan',
    description: 'Exploring offbeat places in the land of kings.',
    thumbnail: '🏰',
    category: 'travel',
    suggestedTip: '150000000000000000',
    likes: 4567,
    tips: '6800000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000004',
    platform: 'instagram' as const,
    url: 'https://instagram.com/p/demo3',
    title: 'Sunset at Taj Mahal',
    description: 'Magical moments at one of the world wonders ✨',
    thumbnail: '🌅',
    category: 'travel',
    suggestedTip: '25000000000000000',
    likes: 15678,
    tips: '2100000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000005',
    platform: 'youtube' as const,
    url: 'https://youtube.com/watch?v=demo6',
    title: 'Pro Tips for Valorant Ranked',
    description: 'Climb from Iron to Diamond with these strategies.',
    thumbnail: '🎯',
    category: 'gaming',
    suggestedTip: '50000000000000000',
    likes: 23456,
    tips: '35000000000000000000',
  },
  {
    creator: '0x2000000000000000000000000000000000000005',
    platform: 'twitter' as const,
    url: 'https://twitter.com/gamingzone/status/demo1',
    title: 'New Game Release Reaction',
    description: 'My thoughts on the latest AAA release 🎮',
    thumbnail: '🎮',
    category: 'gaming',
    suggestedTip: '25000000000000000',
    likes: 8934,
    tips: '1500000000000000000',
  },
];

// POST - Seed database with demo data
export async function POST(request: NextRequest) {
  try {
    const db = await getDatabase();
    
    console.log('🌱 Starting database seeding...');

    // Clear existing demo data (optional - keeps user's real data)
    // We'll use specific wallet prefixes to identify demo data
    await db.collection(COLLECTIONS.USERS).deleteMany({
      wallet: { $regex: /^0x[12]00000000000000000000000000000000000000/ }
    });
    await db.collection(COLLECTIONS.PRODUCTS).deleteMany({
      seller: { $regex: /^0x100000000000000000000000000000000000000/ }
    });
    await db.collection(COLLECTIONS.CONTENT).deleteMany({
      creator: { $regex: /^0x200000000000000000000000000000000000000/ }
    });

    console.log('🧹 Cleared old demo data');

    // Insert stores
    const storesWithDates = DEMO_STORES.map(store => ({
      ...store,
      registeredAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000), // Random date in last 90 days
    }));
    await db.collection(COLLECTIONS.USERS).insertMany(storesWithDates);
    console.log(`✅ Inserted ${DEMO_STORES.length} demo stores`);

    // Insert creators
    const creatorsWithDates = DEMO_CREATORS.map(creator => ({
      ...creator,
      registeredAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
    }));
    await db.collection(COLLECTIONS.USERS).insertMany(creatorsWithDates);
    console.log(`✅ Inserted ${DEMO_CREATORS.length} demo creators`);

    // Insert products
    const productsWithDates = DEMO_PRODUCTS.map((product, index) => ({
      ...product,
      contractId: index + 1,
      createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000), // Random date in last 30 days
    }));
    await db.collection(COLLECTIONS.PRODUCTS).insertMany(productsWithDates);
    console.log(`✅ Inserted ${DEMO_PRODUCTS.length} demo products`);

    // Insert content
    const contentWithDates = DEMO_CONTENT.map(content => ({
      ...content,
      createdAt: new Date(Date.now() - Math.random() * 14 * 24 * 60 * 60 * 1000), // Random date in last 14 days
    }));
    await db.collection(COLLECTIONS.CONTENT).insertMany(contentWithDates);
    console.log(`✅ Inserted ${DEMO_CONTENT.length} demo content`);

    // Get final counts
    const stats = {
      stores: await db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Store }),
      creators: await db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Creator }),
      products: await db.collection(COLLECTIONS.PRODUCTS).countDocuments({ isActive: true }),
      content: await db.collection(COLLECTIONS.CONTENT).countDocuments({}),
    };

    console.log('🎉 Database seeding complete!', stats);

    return NextResponse.json({
      success: true,
      data: {
        message: 'Database seeded successfully!',
        inserted: {
          stores: DEMO_STORES.length,
          creators: DEMO_CREATORS.length,
          products: DEMO_PRODUCTS.length,
          content: DEMO_CONTENT.length,
        },
        totals: stats,
      },
    });
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to seed database' },
      { status: 500 }
    );
  }
}

// GET - Check seed status
export async function GET() {
  try {
    const db = await getDatabase();
    
    const stats = {
      stores: await db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Store }),
      creators: await db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Creator }),
      products: await db.collection(COLLECTIONS.PRODUCTS).countDocuments({ isActive: true }),
      content: await db.collection(COLLECTIONS.CONTENT).countDocuments({}),
    };

    const hasData = stats.products > 0 || stats.content > 0;

    return NextResponse.json({
      success: true,
      data: {
        seeded: hasData,
        stats,
        message: hasData ? 'Database has data' : 'Database is empty - call POST to seed',
      },
    });
  } catch (error) {
    console.error('❌ Error checking seed status:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to check seed status' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# HOOKS: USE-FEED
# ============================================
echo "📝 Creating hooks/use-feed.ts..."
cat > hooks/use-feed.ts << 'EOF'
"use client";

import { useQuery } from "@tanstack/react-query";

interface FeedUser {
  wallet: string;
  displayName?: string;
  storeName?: string;
  username?: string;
  avatar?: string;
  tier: number;
  userType: number;
}

interface FeedItem {
  _id: string;
  type: 'product' | 'content';
  createdAt: string;
  data: {
    title?: string;
    description?: string;
    price?: string;
    images?: string[];
    category?: string;
    stock?: number;
    platform?: string;
    url?: string;
    thumbnail?: string;
    likes?: number;
    tips?: string;
    suggestedTip?: string;
  };
  user: FeedUser | null;
}

interface FeedResponse {
  items: FeedItem[];
  total: number;
  hasMore: boolean;
  counts: {
    products: number;
    content: number;
  };
}

type FilterType = 'all' | 'products' | 'creators';

export function useFeed(filter: FilterType = 'all', category?: string) {
  return useQuery({
    queryKey: ["feed", filter, category],
    queryFn: async (): Promise<FeedResponse> => {
      const params = new URLSearchParams();
      params.set('filter', filter);
      params.set('limit', '20');
      if (category) params.set('category', category);
      
      console.log(`📡 Fetching feed: filter=${filter}, category=${category || 'all'}`);
      
      const res = await fetch(`/api/feed?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2, // 2 minutes
  });
}

export type { FeedItem, FeedUser, FeedResponse, FilterType };
EOF

# ============================================
# HOOKS: USE-PRODUCTS
# ============================================
echo "📝 Creating hooks/use-products.ts..."
cat > hooks/use-products.ts << 'EOF'
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Product } from "@/types";

interface ProductsResponse {
  products: Product[];
  total: number;
  hasMore: boolean;
}

interface CreateProductData {
  seller: string;
  title: string;
  description?: string;
  price: string;
  images?: string[];
  category?: string;
  stock?: number;
  deliveryOptions?: {
    pickup: boolean;
    shipping: boolean;
  };
}

export function useProducts(options?: {
  seller?: string;
  category?: string;
  search?: string;
  limit?: number;
}) {
  const { seller, category, search, limit = 20 } = options || {};

  return useQuery({
    queryKey: ["products", seller, category, search, limit],
    queryFn: async (): Promise<ProductsResponse> => {
      const params = new URLSearchParams();
      params.set('limit', limit.toString());
      if (seller) params.set('seller', seller);
      if (category) params.set('category', category);
      if (search) params.set('search', search);
      
      const res = await fetch(`/api/products?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2,
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: ["product", id],
    queryFn: async () => {
      const res = await fetch(`/api/products/${id}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: !!id,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateProductData): Promise<Product> => {
      const res = await fetch("/api/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
}
EOF

# ============================================
# HOOKS: USE-STATS
# ============================================
echo "📝 Creating hooks/use-stats.ts..."
cat > hooks/use-stats.ts << 'EOF'
"use client";

import { useQuery } from "@tanstack/react-query";

interface StatsResponse {
  users: number;
  stores: number;
  creators: number;
  products: number;
  content: number;
  orders: number;
  tips: number;
  orderVolume: string;
  tipsVolume: string;
}

export function useStats() {
  return useQuery({
    queryKey: ["stats"],
    queryFn: async (): Promise<StatsResponse> => {
      const res = await fetch("/api/stats");
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
}
EOF

# ============================================
# HOOKS: USE-CONTENT
# ============================================
echo "📝 Creating hooks/use-content.ts..."
cat > hooks/use-content.ts << 'EOF'
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { CreatorContent } from "@/types";

interface ContentResponse {
  content: (CreatorContent & { creatorInfo?: any })[];
  total: number;
  hasMore: boolean;
}

interface CreateContentData {
  creator: string;
  platform: 'youtube' | 'instagram' | 'twitter';
  url: string;
  title?: string;
  description?: string;
  category?: string;
  suggestedTip?: string;
}

export function useContent(options?: {
  creator?: string;
  category?: string;
  platform?: string;
  limit?: number;
}) {
  const { creator, category, platform, limit = 20 } = options || {};

  return useQuery({
    queryKey: ["content", creator, category, platform, limit],
    queryFn: async (): Promise<ContentResponse> => {
      const params = new URLSearchParams();
      params.set('limit', limit.toString());
      if (creator) params.set('creator', creator);
      if (category) params.set('category', category);
      if (platform) params.set('platform', platform);
      
      const res = await fetch(`/api/content?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2,
  });
}

export function useCreateContent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateContentData): Promise<CreatorContent> => {
      const res = await fetch("/api/content", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["content"] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
}
EOF

# ============================================
# HOOKS: USE-LIKE
# ============================================
echo "📝 Creating hooks/use-like.ts..."
cat > hooks/use-like.ts << 'EOF'
"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

interface LikeData {
  itemId: string;
  itemType: 'product' | 'content';
  userWallet: string;
}

export function useLike() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: LikeData): Promise<{ likes: number }> => {
      const res = await fetch("/api/like", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feed"] });
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["content"] });
    },
  });
}
EOF

# ============================================
# HOOKS: USE-SEED
# ============================================
echo "📝 Creating hooks/use-seed.ts..."
cat > hooks/use-seed.ts << 'EOF'
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

interface SeedStatus {
  seeded: boolean;
  stats: {
    stores: number;
    creators: number;
    products: number;
    content: number;
  };
  message: string;
}

export function useSeedStatus() {
  return useQuery({
    queryKey: ["seedStatus"],
    queryFn: async (): Promise<SeedStatus> => {
      const res = await fetch("/api/feed_data");
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });
}

export function useSeedDatabase() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/feed_data", {
        method: "POST",
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      // Invalidate all queries to refetch with new data
      queryClient.invalidateQueries({ queryKey: ["feed"] });
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["content"] });
      queryClient.invalidateQueries({ queryKey: ["stats"] });
      queryClient.invalidateQueries({ queryKey: ["seedStatus"] });
    },
  });
}
EOF

# ============================================
# HOOKS: INDEX (Export all hooks)
# ============================================
echo "📝 Creating hooks/index.ts..."
cat > hooks/index.ts << 'EOF'
export { useUser } from './use-user';
export { useFeed } from './use-feed';
export type { FeedItem, FeedUser, FeedResponse, FilterType } from './use-feed';
export { useProducts, useProduct, useCreateProduct } from './use-products';
export { useContent, useCreateContent } from './use-content';
export { useStats } from './use-stats';
export { useLike } from './use-like';
export { useSeedStatus, useSeedDatabase } from './use-seed';
EOF

# ============================================
# COMPONENTS: PRODUCT CARD
# ============================================
echo "📝 Creating components/cards/product-card.tsx..."
mkdir -p components/cards
cat > components/cards/product-card.tsx << 'EOF'
"use client";

import { Heart, ShoppingCart } from 'lucide-react';
import { FeedItem } from '@/hooks/use-feed';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';

interface ProductCardProps {
  item: FeedItem;
}

export function ProductCard({ item }: ProductCardProps) {
  const { address } = useUser();
  const likeMutation = useLike();
  const [likes, setLikes] = useState(item.data.likes || 0);
  const [isLiked, setIsLiked] = useState(false);

  const handleLike = async () => {
    if (!address || isLiked) return;
    
    try {
      const result = await likeMutation.mutateAsync({
        itemId: item._id,
        itemType: 'product',
        userWallet: address,
      });
      setLikes(result.likes);
      setIsLiked(true);
    } catch (error) {
      console.error('Failed to like:', error);
    }
  };

  // Format price (assuming 18 decimals, showing in INR-like format)
  const formatPrice = (price: string) => {
    const num = parseFloat(price) / 1e18;
    return `₹${num.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`;
  };

  const getTierBadge = (tier: number) => {
    switch (tier) {
      case 2: return { text: '★ Premium', class: 'badge-premium' };
      case 1: return { text: '✓ Verified', class: 'badge-verified' };
      default: return null;
    }
  };

  const tierBadge = item.user ? getTierBadge(item.user.tier) : null;

  return (
    <div className="glass-card overflow-hidden card-hover">
      {/* Image */}
      <div className="h-40 bg-gradient-to-br from-[var(--pay-blue)]/20 to-[var(--pay-purple)]/20 flex items-center justify-center relative">
        <span className="text-5xl">{item.data.images?.[0] || '📦'}</span>
        {item.data.stock && item.data.stock < 5 && (
          <span className="absolute top-2 right-2 badge-warning text-xs">
            Only {item.data.stock} left
          </span>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Badge */}
        {tierBadge && (
          <div className="mb-2">
            <span className={tierBadge.class}>{tierBadge.text}</span>
          </div>
        )}

        {/* Title */}
        <h4 className="font-semibold mb-1 line-clamp-1">{item.data.title}</h4>

        {/* Store name */}
        <p className="text-xs text-[var(--muted-foreground)] mb-3">
          {item.user?.avatar} {item.user?.storeName || item.user?.displayName || 'Unknown Store'}
        </p>

        {/* Price and actions */}
        <div className="flex items-center justify-between">
          <span className="price-gradient text-lg font-bold">
            {formatPrice(item.data.price || '0')}
          </span>
          
          <div className="flex items-center gap-2">
            <button 
              onClick={handleLike}
              disabled={isLiked || likeMutation.isPending}
              className={`p-2 rounded-lg transition-colors ${
                isLiked 
                  ? 'bg-red-500/20 text-red-400' 
                  : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
              }`}
            >
              <Heart className={`w-4 h-4 ${isLiked ? 'fill-current' : ''}`} />
            </button>
            <button className="btn-pay text-sm py-2 px-3 flex items-center gap-1">
              <ShoppingCart className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Likes count */}
        <div className="mt-2 text-xs text-[var(--muted-foreground)]">
          ❤️ {likes.toLocaleString()} likes
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# COMPONENTS: CONTENT CARD
# ============================================
echo "📝 Creating components/cards/content-card.tsx..."
cat > components/cards/content-card.tsx << 'EOF'
"use client";

import { Heart, MessageCircle, ExternalLink } from 'lucide-react';
import { FeedItem } from '@/hooks/use-feed';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';

interface ContentCardProps {
  item: FeedItem;
}

export function ContentCard({ item }: ContentCardProps) {
  const { address } = useUser();
  const likeMutation = useLike();
  const [likes, setLikes] = useState(item.data.likes || 0);
  const [isLiked, setIsLiked] = useState(false);

  const handleLike = async () => {
    if (!address || isLiked) return;
    
    try {
      const result = await likeMutation.mutateAsync({
        itemId: item._id,
        itemType: 'content',
        userWallet: address,
      });
      setLikes(result.likes);
      setIsLiked(true);
    } catch (error) {
      console.error('Failed to like:', error);
    }
  };

  const getPlatformIcon = (platform?: string) => {
    switch (platform) {
      case 'youtube': return '▶️';
      case 'instagram': return '📸';
      case 'twitter': return '🐦';
      default: return '🔗';
    }
  };

  const getPlatformColor = (platform?: string) => {
    switch (platform) {
      case 'youtube': return 'from-red-500/20 to-red-600/20';
      case 'instagram': return 'from-pink-500/20 to-purple-500/20';
      case 'twitter': return 'from-blue-400/20 to-blue-500/20';
      default: return 'from-[var(--pay-purple)]/20 to-[var(--pay-green)]/20';
    }
  };

  const getTierBadge = (tier: number) => {
    switch (tier) {
      case 2: return { text: '★ Premium', class: 'badge-premium' };
      case 1: return { text: '✓ Verified', class: 'badge-verified' };
      default: return null;
    }
  };

  const tierBadge = item.user ? getTierBadge(item.user.tier) : null;

  return (
    <div className="glass-card overflow-hidden card-hover">
      {/* Thumbnail */}
      <div className={`h-32 bg-gradient-to-br ${getPlatformColor(item.data.platform)} flex items-center justify-center relative`}>
        <span className="text-4xl">{item.data.thumbnail || getPlatformIcon(item.data.platform)}</span>
        <span className="absolute top-2 left-2 bg-black/50 text-white text-xs px-2 py-1 rounded-full flex items-center gap-1">
          {getPlatformIcon(item.data.platform)} {item.data.platform}
        </span>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Title */}
        <h4 className="font-semibold mb-1 line-clamp-2">{item.data.title}</h4>

        {/* Creator */}
        <div className="flex items-center gap-2 mb-3">
          <span className="text-sm">{item.user?.avatar}</span>
          <span className="text-xs text-[var(--muted-foreground)]">
            @{item.user?.username || 'creator'}
          </span>
          {tierBadge && (
            <span className={`${tierBadge.class} text-xs`}>{tierBadge.text}</span>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 text-xs text-[var(--muted-foreground)]">
            <button 
              onClick={handleLike}
              disabled={isLiked || likeMutation.isPending}
              className={`flex items-center gap-1 transition-colors ${
                isLiked ? 'text-red-400' : 'hover:text-red-400'
              }`}
            >
              <Heart className={`w-4 h-4 ${isLiked ? 'fill-current' : ''}`} />
              {likes.toLocaleString()}
            </button>
            <span className="flex items-center gap-1">
              <MessageCircle className="w-4 h-4" />
              {Math.floor(Math.random() * 100)}
            </span>
          </div>
          
          <div className="flex items-center gap-2">
            <a 
              href={item.data.url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="p-2 rounded-lg bg-[var(--muted)] hover:bg-[var(--muted)]/80 transition-colors"
            >
              <ExternalLink className="w-4 h-4" />
            </a>
            <button className="tip-button text-sm py-2 px-3">
              💰 Tip
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# COMPONENTS: FEED FILTERS
# ============================================
echo "📝 Creating components/feed/feed-filters.tsx..."
mkdir -p components/feed
cat > components/feed/feed-filters.tsx << 'EOF'
"use client";

import { FilterType } from '@/hooks/use-feed';

interface FeedFiltersProps {
  activeFilter: FilterType;
  onFilterChange: (filter: FilterType) => void;
}

const FILTERS: { value: FilterType; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'products', label: 'Products' },
  { value: 'creators', label: 'Creators' },
];

export function FeedFilters({ activeFilter, onFilterChange }: FeedFiltersProps) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      {FILTERS.map((filter) => (
        <button
          key={filter.value}
          onClick={() => onFilterChange(filter.value)}
          className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
            activeFilter === filter.value
              ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
              : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
          }`}
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
}
EOF

# ============================================
# COMPONENTS: FEED LIST
# ============================================
echo "📝 Creating components/feed/feed-list.tsx..."
cat > components/feed/feed-list.tsx << 'EOF'
"use client";

import { FeedItem } from '@/hooks/use-feed';
import { ProductCard } from '@/components/cards/product-card';
import { ContentCard } from '@/components/cards/content-card';

interface FeedListProps {
  items: FeedItem[];
  isLoading?: boolean;
}

export function FeedList({ items, isLoading }: FeedListProps) {
  if (isLoading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="glass-card overflow-hidden">
            <div className="h-40 shimmer" />
            <div className="p-4 space-y-3">
              <div className="h-4 shimmer rounded w-3/4" />
              <div className="h-3 shimmer rounded w-1/2" />
              <div className="h-8 shimmer rounded w-1/3" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="glass-card p-8 text-center">
        <div className="text-4xl mb-4">📭</div>
        <h3 className="font-semibold mb-2">No items yet</h3>
        <p className="text-sm text-[var(--muted-foreground)]">
          Check back later or be the first to post!
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {items.map((item) => (
        item.type === 'product' 
          ? <ProductCard key={item._id} item={item} />
          : <ContentCard key={item._id} item={item} />
      ))}
    </div>
  );
}
EOF

# ============================================
# COMPONENTS: STATS BANNER
# ============================================
echo "📝 Creating components/feed/stats-banner.tsx..."
cat > components/feed/stats-banner.tsx << 'EOF'
"use client";

import { useStats } from '@/hooks/use-stats';

export function StatsBanner() {
  const { data: stats, isLoading } = useStats();

  if (isLoading) {
    return (
      <div className="glass-card-success p-4">
        <div className="grid grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="text-center">
              <div className="h-6 shimmer rounded w-12 mx-auto mb-1" />
              <div className="h-3 shimmer rounded w-16 mx-auto" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="glass-card-success p-4">
      <div className="grid grid-cols-3 gap-4 text-center">
        <div>
          <div className="text-xl font-bold text-[var(--pay-green)]">
            {stats?.products?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Products</div>
        </div>
        <div>
          <div className="text-xl font-bold text-[var(--pay-purple)]">
            {stats?.creators?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Creators</div>
        </div>
        <div>
          <div className="text-xl font-bold text-[var(--pay-blue)]">
            {stats?.stores?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Stores</div>
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# UPDATED HOME PAGE
# ============================================
echo "📝 Updating app/page.tsx with real feed..."
cat > app/page.tsx << 'EOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import { useMiniKit } from "@coinbase/onchainkit/minikit";
import { SplashScreen } from "@/components/splash-screen";
import { useUser } from "@/hooks/use-user";
import { useFeed, FilterType } from "@/hooks/use-feed";
import { useSeedStatus, useSeedDatabase } from "@/hooks/use-seed";
import { FeedFilters } from "@/components/feed/feed-filters";
import { FeedList } from "@/components/feed/feed-list";
import { StatsBanner } from "@/components/feed/stats-banner";
import { APP_NAME } from "@/lib/constants";
import { Loader2, Database } from "lucide-react";
import Link from "next/link";
import { toast } from "sonner";

export default function Home() {
  const [showSplash, setShowSplash] = useState(true);
  const [filter, setFilter] = useState<FilterType>('all');
  const { setMiniAppReady, isMiniAppReady } = useMiniKit();
  const { user, isLoading: isUserLoading, isConnected, needsOnboarding, address } = useUser();
  
  // Feed data
  const { data: feedData, isLoading: isFeedLoading, error: feedError } = useFeed(filter);
  
  // Seed status
  const { data: seedStatus } = useSeedStatus();
  const seedMutation = useSeedDatabase();

  useEffect(() => {
    if (!isMiniAppReady) {
      setMiniAppReady();
    }
  }, [setMiniAppReady, isMiniAppReady]);

  const handleSplashComplete = useCallback(() => {
    setShowSplash(false);
  }, []);

  const handleSeedDatabase = async () => {
    try {
      await seedMutation.mutateAsync();
      toast.success('Database seeded with demo data!');
    } catch (error) {
      toast.error('Failed to seed database');
    }
  };

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashComplete} />;
  }

  if (isConnected && isUserLoading) {
    return (
      <div className="p-4 flex items-center justify-center min-h-[50vh]">
        <div className="text-center">
          <div className="shimmer h-12 w-12 rounded-full mx-auto mb-4" />
          <p className="text-[var(--muted-foreground)]">Loading your profile...</p>
        </div>
      </div>
    );
  }

  if (needsOnboarding) {
    return (
      <div className="p-4">
        <div className="glass-card-highlight p-6 text-center">
          <div className="text-4xl mb-4">🎉</div>
          <h2 className="text-xl font-bold mb-2">Welcome to {APP_NAME}!</h2>
          <p className="text-[var(--muted-foreground)] text-sm mb-4">
            Complete your profile to start buying, selling, or creating content.
          </p>
          <p className="text-xs text-[var(--muted-foreground)] mb-4">
            Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
          </p>
          <Link href="/onboarding" className="btn-pay inline-block">
            Set Up Profile
          </Link>
        </div>
      </div>
    );
  }

  const getTierName = (tier: number) => {
    switch (tier) {
      case 0: return 'Anonymous';
      case 1: return 'Verified';
      case 2: return 'Premium';
      default: return 'Anonymous';
    }
  };

  const getUserTypeName = (type: number) => {
    switch (type) {
      case 1: return '🎨 Creator';
      case 2: return '🏪 Store';
      default: return '👤 User';
    }
  };

  // Check if we need to show seed button
  const showSeedButton = seedStatus && !seedStatus.seeded;

  return (
    <div className="p-4 space-y-4">
      {/* Welcome Card */}
      <div className="glass-card-highlight p-5">
        <h2 className="text-xl font-bold mb-2">
          {user ? `Welcome back${user.displayName ? `, ${user.displayName}` : ''}! 👋` : `Welcome to ${APP_NAME} 👋`}
        </h2>
        <p className="text-[var(--muted-foreground)] text-sm">
          Discover local stores, tip creators, and shop with crypto.
        </p>
        {user && (
          <div className="mt-3 flex gap-2 flex-wrap">
            <span className="badge-info">{getUserTypeName(user.userType)}</span>
            <span className="badge-verified">✓ {getTierName(user.tier)}</span>
          </div>
        )}
        {!isConnected && (
          <p className="text-xs text-[var(--muted-foreground)] mt-3">
            Connect your wallet to get started
          </p>
        )}
      </div>

      {/* Seed Database Button (only if no data) */}
      {showSeedButton && (
        <div className="glass-card p-4 border-2 border-dashed border-[var(--pay-blue)]/50">
          <div className="flex items-center gap-3">
            <Database className="w-8 h-8 text-[var(--pay-blue)]" />
            <div className="flex-1">
              <h3 className="font-semibold text-sm">Database is empty</h3>
              <p className="text-xs text-[var(--muted-foreground)]">
                Add demo data to see the feed in action
              </p>
            </div>
            <button
              onClick={handleSeedDatabase}
              disabled={seedMutation.isPending}
              className="btn-pay text-sm py-2 px-4 flex items-center gap-2"
            >
              {seedMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Seeding...
                </>
              ) : (
                'Seed Data'
              )}
            </button>
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-3">
        <Link href="/explore" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🛍️</div>
          <h3 className="font-semibold text-sm">Browse Products</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Shop local stores</p>
        </Link>
        <Link href="/explore?tab=creators" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🎨</div>
          <h3 className="font-semibold text-sm">Discover Creators</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Support talent</p>
        </Link>
      </div>

      {/* Feed Section */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg font-semibold">Feed 🔥</h3>
          {feedData && (
            <span className="text-xs text-[var(--muted-foreground)]">
              {feedData.total} items
            </span>
          )}
        </div>

        {/* Filters */}
        <FeedFilters activeFilter={filter} onFilterChange={setFilter} />

        {/* Feed Error */}
        {feedError && (
          <div className="glass-card p-4 border border-red-500/30 mt-4">
            <p className="text-red-400 text-sm">Failed to load feed. Please try again.</p>
          </div>
        )}

        {/* Feed List */}
        <div className="mt-4">
          <FeedList 
            items={feedData?.items || []} 
            isLoading={isFeedLoading} 
          />
        </div>

        {/* Load More */}
        {feedData?.hasMore && (
          <div className="mt-4 text-center">
            <button className="btn-secondary text-sm py-2 px-6">
              Load More
            </button>
          </div>
        )}
      </div>

      {/* Stats Banner */}
      <StatsBanner />
    </div>
  );
}
EOF

echo ""
echo "============================================"
echo "✅ All Files Created!"
echo "============================================"
echo ""
echo "📋 CREATED FILES:"
echo ""
echo "API:"
echo "  └── app/api/feed_data/route.ts  (Seed database endpoint)"
echo ""
echo "HOOKS:"
echo "  ├── hooks/use-feed.ts      (Feed data hook)"
echo "  ├── hooks/use-products.ts  (Products CRUD hook)"
echo "  ├── hooks/use-content.ts   (Content CRUD hook)"
echo "  ├── hooks/use-stats.ts     (Platform stats hook)"
echo "  ├── hooks/use-like.ts      (Like functionality hook)"
echo "  ├── hooks/use-seed.ts      (Seed database hook)"
echo "  └── hooks/index.ts         (Export all hooks)"
echo ""
echo "COMPONENTS:"
echo "  ├── components/cards/product-card.tsx"
echo "  ├── components/cards/content-card.tsx"
echo "  ├── components/feed/feed-filters.tsx"
echo "  ├── components/feed/feed-list.tsx"
echo "  └── components/feed/stats-banner.tsx"
echo ""
echo "PAGES:"
echo "  └── app/page.tsx  (Updated home page with real feed)"
echo ""
echo "============================================"
echo "🚀 HOW TO USE:"
echo "============================================"
echo ""
echo "1. Run the script in your BasePay project:"
echo "   chmod +x basepay-hooks-seed.sh"
echo "   ./basepay-hooks-seed.sh"
echo ""
echo "2. Start your dev server:"
echo "   npm run dev"
echo ""
echo "3. Open the app and click 'Seed Data' button"
echo "   OR call the API directly:"
echo "   curl -X POST http://localhost:3000/api/feed_data"
echo ""
echo "4. The feed will now show real demo data!"
echo ""
echo "============================================"
echo "📊 DEMO DATA INCLUDES:"
echo "============================================"
echo "  • 5 Demo Stores (TechStore, Fashion Hub, etc.)"
echo "  • 5 Demo Creators (Tech Guru, Foodie Adventures, etc.)"
echo "  • 12 Demo Products (Headphones, Clothes, Food, Art, etc.)"
echo "  • 10 Demo Content (YouTube, Instagram, Twitter)"
echo ""
echo "============================================"