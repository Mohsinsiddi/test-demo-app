#!/bin/bash

echo "🚀 BasePay Complete Setup v3"
echo "============================"

# Install MongoDB package
echo ""
echo "📦 Installing packages..."
npm install mongodb

# Create directory structure
echo ""
echo "📁 Creating directories..."
mkdir -p app/api/health
mkdir -p app/api/users
mkdir -p app/api/init
mkdir -p app/onboarding
mkdir -p components/layout
mkdir -p components/shared
mkdir -p hooks
mkdir -p lib
mkdir -p types
mkdir -p scripts

# ============================================
# FIX: next.config.js for MetaMask SDK
# ============================================
echo ""
echo "📝 Creating next.config.js (MetaMask fix)..."

# Check if next.config exists and what format
if [ -f "next.config.ts" ]; then
  echo "   Found next.config.ts, updating..."
  cat > next.config.ts << 'EOF'
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
EOF
elif [ -f "next.config.mjs" ]; then
  echo "   Found next.config.mjs, updating..."
  cat > next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    config.resolve.fallback = {
      ...config.resolve.fallback,
      "@react-native-async-storage/async-storage": false,
    };
    config.externals.push("pino-pretty", "lokijs", "encoding");
    return config;
  },
};

export default nextConfig;
EOF
else
  echo "   Creating next.config.js..."
  cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    config.resolve.fallback = {
      ...config.resolve.fallback,
      "@react-native-async-storage/async-storage": false,
    };
    config.externals.push("pino-pretty", "lokijs", "encoding");
    return config;
  },
};

module.exports = nextConfig;
EOF
fi

# ============================================
# TYPES
# ============================================
echo "📝 Creating types/index.ts..."
cat > types/index.ts << 'EOF'
// User Types
export enum UserType {
  None = 0,
  Creator = 1,
  Store = 2,
}

export enum UserTier {
  Anonymous = 0,
  Verified = 1,
  Premium = 2,
}

export interface User {
  _id?: string;
  wallet: string;
  userType: UserType;
  tier: UserTier;
  isActive: boolean;
  totalSales: string;
  hasCustomFee: boolean;
  customFee: number;
  registeredAt: Date;
  displayName?: string;
  username?: string;
  bio?: string;
  avatar?: string;
  banner?: string;
  storeName?: string;
  storeCategory?: string;
  location?: string;
  youtube?: string;
  instagram?: string;
  twitter?: string;
  kycStatus: 'pending' | 'submitted' | 'verified' | 'rejected';
  kycDeadline?: Date;
}

export interface Product {
  _id?: string;
  contractId: number;
  seller: string;
  price: string;
  paymentToken: string;
  isActive: boolean;
  metadataUri: string;
  createdAt: Date;
  title: string;
  description?: string;
  images: string[];
  category?: string;
  stock?: number;
  deliveryOptions: {
    pickup: boolean;
    shipping: boolean;
  };
}

export interface CreatorContent {
  _id?: string;
  creator: string;
  platform: 'youtube' | 'instagram' | 'twitter';
  url: string;
  title?: string;
  description?: string;
  thumbnail?: string;
  category?: string;
  suggestedTip?: string;
  createdAt: Date;
  likes: number;
  tips: string;
}

export interface Order {
  _id?: string;
  productId: string;
  buyer: string;
  seller: string;
  amount: string;
  fee: string;
  paymentToken: string;
  status: 'pending' | 'confirmed' | 'ready' | 'shipped' | 'delivered' | 'disputed' | 'cancelled';
  deliveryType: 'pickup' | 'shipping';
  shippingAddress?: string;
  trackingInfo?: string;
  txHash: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Tip {
  _id?: string;
  contentId: string;
  from: string;
  to: string;
  amount: string;
  paymentToken: string;
  txHash: string;
  createdAt: Date;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
EOF

# ============================================
# CONSTANTS
# ============================================
echo "📝 Creating lib/constants.ts..."
cat > lib/constants.ts << 'EOF'
export const ANONYMOUS_FEE = 200n;
export const VERIFIED_FEE = 100n;
export const PREMIUM_FEE = 50n;
export const BASIS_POINTS = 10000n;
export const PREMIUM_THRESHOLD = 50_000n * 10n ** 18n;

export const PAYMENT_HUB_ADDRESS = process.env.NEXT_PUBLIC_PAYMENT_HUB_ADDRESS || '0x...';
export const BASE_PAY_TOKEN_ADDRESS = process.env.NEXT_PUBLIC_BASE_PAY_TOKEN_ADDRESS || '0x...';

export const APP_NAME = 'BasePay';
export const APP_TAGLINE = 'Social Commerce on Base';
export const KYC_DEADLINE_DAYS = 90;

export const STORE_CATEGORIES = [
  { id: 'food', label: 'Food & Beverages', icon: '🍔' },
  { id: 'fashion', label: 'Fashion', icon: '👕' },
  { id: 'art', label: 'Art & Crafts', icon: '🎨' },
  { id: 'tech', label: 'Tech & Gadgets', icon: '📱' },
  { id: 'beauty', label: 'Beauty', icon: '💄' },
  { id: 'home', label: 'Home & Living', icon: '🏠' },
  { id: 'sports', label: 'Sports', icon: '⚽' },
  { id: 'other', label: 'Other', icon: '📦' },
];

export const CONTENT_CATEGORIES = [
  { id: 'entertainment', label: 'Entertainment', icon: '🎬' },
  { id: 'education', label: 'Education', icon: '📚' },
  { id: 'lifestyle', label: 'Lifestyle', icon: '✨' },
  { id: 'gaming', label: 'Gaming', icon: '🎮' },
  { id: 'music', label: 'Music', icon: '🎵' },
  { id: 'tech', label: 'Tech', icon: '💻' },
  { id: 'food', label: 'Food', icon: '🍳' },
  { id: 'travel', label: 'Travel', icon: '✈️' },
];
EOF

# ============================================
# MONGODB CONNECTION
# ============================================
echo "📝 Creating lib/mongodb.ts..."
cat > lib/mongodb.ts << 'EOF'
import { MongoClient, Db } from 'mongodb';

if (!process.env.MONGODB_URI) {
  throw new Error('Please add MONGODB_URI to your environment variables');
}

const uri = process.env.MONGODB_URI;
const options = {};

let client: MongoClient;
let clientPromise: Promise<MongoClient>;

declare global {
  var _mongoClientPromise: Promise<MongoClient> | undefined;
}

if (process.env.NODE_ENV === 'development') {
  if (!global._mongoClientPromise) {
    client = new MongoClient(uri, options);
    global._mongoClientPromise = client.connect();
  }
  clientPromise = global._mongoClientPromise;
} else {
  client = new MongoClient(uri, options);
  clientPromise = client.connect();
}

export default clientPromise;

export async function getDatabase(): Promise<Db> {
  const client = await clientPromise;
  return client.db('basepay');
}

export const COLLECTIONS = {
  USERS: 'users',
  PRODUCTS: 'products',
  CONTENT: 'content',
  ORDERS: 'orders',
  TIPS: 'tips',
} as const;
EOF

# ============================================
# CONTRACT CONFIG
# ============================================
echo "📝 Creating lib/contract-config.ts..."
cat > lib/contract-config.ts << 'EOF'
import { PAYMENT_HUB_ADDRESS, BASE_PAY_TOKEN_ADDRESS } from './constants';

export const PAYMENT_HUB_ABI = [
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUser',
    outputs: [
      {
        components: [
          { name: 'wallet', type: 'address' },
          { name: 'userType', type: 'uint8' },
          { name: 'tier', type: 'uint8' },
          { name: 'isActive', type: 'bool' },
          { name: 'totalSales', type: 'uint256' },
          { name: 'hasCustomFee', type: 'bool' },
          { name: 'customFee', type: 'uint256' },
          { name: 'registeredAt', type: 'uint256' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'productId', type: 'uint256' }],
    name: 'getProduct',
    outputs: [
      {
        components: [
          { name: 'id', type: 'uint256' },
          { name: 'seller', type: 'address' },
          { name: 'price', type: 'uint256' },
          { name: 'paymentToken', type: 'address' },
          { name: 'isActive', type: 'bool' },
          { name: 'metadataUri', type: 'string' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'userType', type: 'uint8' }],
    name: 'registerUser',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'price', type: 'uint256' },
      { name: 'paymentToken', type: 'address' },
      { name: 'metadataUri', type: 'string' },
    ],
    name: 'createProduct',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'productId', type: 'uint256' }],
    name: 'buyProduct',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'creator', type: 'address' },
      { name: 'contentId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'paymentToken', type: 'address' },
    ],
    name: 'tipCreator',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
] as const;

export const ERC20_ABI = [
  {
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    name: 'approve',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export const contractConfig = {
  paymentHub: {
    address: PAYMENT_HUB_ADDRESS as `0x${string}`,
    abi: PAYMENT_HUB_ABI,
  },
  basePay: {
    address: BASE_PAY_TOKEN_ADDRESS as `0x${string}`,
    abi: ERC20_ABI,
  },
};
EOF

# ============================================
# API: DATABASE INIT (Creates collections + indexes)
# ============================================
echo "📝 Creating app/api/init/route.ts (DB Setup)..."
cat > app/api/init/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';

export async function POST() {
  try {
    const db = await getDatabase();
    
    console.log('🔧 Initializing BasePay database...');

    // Create collections if they don't exist
    const existingCollections = await db.listCollections().toArray();
    const existingNames = existingCollections.map(c => c.name);

    // Users collection
    if (!existingNames.includes(COLLECTIONS.USERS)) {
      await db.createCollection(COLLECTIONS.USERS);
      console.log('✅ Created users collection');
    }

    // Products collection
    if (!existingNames.includes(COLLECTIONS.PRODUCTS)) {
      await db.createCollection(COLLECTIONS.PRODUCTS);
      console.log('✅ Created products collection');
    }

    // Content collection
    if (!existingNames.includes(COLLECTIONS.CONTENT)) {
      await db.createCollection(COLLECTIONS.CONTENT);
      console.log('✅ Created content collection');
    }

    // Orders collection
    if (!existingNames.includes(COLLECTIONS.ORDERS)) {
      await db.createCollection(COLLECTIONS.ORDERS);
      console.log('✅ Created orders collection');
    }

    // Tips collection
    if (!existingNames.includes(COLLECTIONS.TIPS)) {
      await db.createCollection(COLLECTIONS.TIPS);
      console.log('✅ Created tips collection');
    }

    // Create indexes for performance
    console.log('🔧 Creating indexes...');

    // Users indexes
    await db.collection(COLLECTIONS.USERS).createIndex(
      { wallet: 1 }, 
      { unique: true }
    );
    await db.collection(COLLECTIONS.USERS).createIndex({ userType: 1 });
    await db.collection(COLLECTIONS.USERS).createIndex({ isActive: 1 });
    await db.collection(COLLECTIONS.USERS).createIndex({ username: 1 }, { sparse: true });
    console.log('✅ Users indexes created');

    // Products indexes
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ seller: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ isActive: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ category: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ contractId: 1 }, { unique: true, sparse: true });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ createdAt: -1 });
    console.log('✅ Products indexes created');

    // Content indexes
    await db.collection(COLLECTIONS.CONTENT).createIndex({ creator: 1 });
    await db.collection(COLLECTIONS.CONTENT).createIndex({ category: 1 });
    await db.collection(COLLECTIONS.CONTENT).createIndex({ createdAt: -1 });
    console.log('✅ Content indexes created');

    // Orders indexes
    await db.collection(COLLECTIONS.ORDERS).createIndex({ buyer: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ seller: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ status: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ createdAt: -1 });
    console.log('✅ Orders indexes created');

    // Tips indexes
    await db.collection(COLLECTIONS.TIPS).createIndex({ from: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ to: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ createdAt: -1 });
    console.log('✅ Tips indexes created');

    // Get collection stats
    const stats = {
      users: await db.collection(COLLECTIONS.USERS).countDocuments(),
      products: await db.collection(COLLECTIONS.PRODUCTS).countDocuments(),
      content: await db.collection(COLLECTIONS.CONTENT).countDocuments(),
      orders: await db.collection(COLLECTIONS.ORDERS).countDocuments(),
      tips: await db.collection(COLLECTIONS.TIPS).countDocuments(),
    };

    console.log('✅ Database initialization complete!');
    console.log('📊 Collection counts:', stats);

    return NextResponse.json({
      success: true,
      data: {
        message: 'Database initialized successfully',
        collections: Object.keys(COLLECTIONS),
        stats,
      },
    });
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to initialize database' },
      { status: 500 }
    );
  }
}

// GET - Check database status
export async function GET() {
  try {
    const db = await getDatabase();
    
    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);
    
    const stats: Record<string, number> = {};
    for (const name of collectionNames) {
      stats[name] = await db.collection(name).countDocuments();
    }

    return NextResponse.json({
      success: true,
      data: {
        database: 'basepay',
        collections: collectionNames,
        stats,
        initialized: collectionNames.includes('users'),
      },
    });
  } catch (error) {
    console.error('❌ Error checking database:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to check database' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# API: HEALTH CHECK
# ============================================
echo "📝 Creating app/api/health/route.ts..."
cat > app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import clientPromise from '@/lib/mongodb';

export async function GET() {
  try {
    const client = await clientPromise;
    await client.db('basepay').command({ ping: 1 });
    
    return NextResponse.json({
      success: true,
      data: {
        status: 'healthy',
        database: 'connected',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Health check failed:', error);
    return NextResponse.json(
      { success: false, error: 'Database connection failed' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# API: USERS
# ============================================
echo "📝 Creating app/api/users/route.ts..."
cat > app/api/users/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { User, UserType, UserTier, ApiResponse } from '@/types';
import { KYC_DEADLINE_DAYS } from '@/lib/constants';
import { WithId, Document } from 'mongodb';

// Helper to convert MongoDB document to User type
function toUser(doc: WithId<Document>): User {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as User;
}

// GET - Fetch user by wallet
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const wallet = searchParams.get('wallet');

    if (!wallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Wallet address required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const user = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: wallet.toLowerCase() 
    });

    console.log('📡 GET /api/users - wallet:', wallet.toLowerCase(), '→', user ? 'Found' : 'Not found');

    if (!user) {
      return NextResponse.json<ApiResponse<null>>({
        success: true,
        data: null,
      });
    }

    return NextResponse.json<ApiResponse<User>>({
      success: true,
      data: toUser(user),
    });
  } catch (error) {
    console.error('❌ Error fetching user:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch user' },
      { status: 500 }
    );
  }
}

// POST - Create or update user
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { wallet, userType, displayName, username, bio, storeName, storeCategory, location } = body;

    console.log('📡 POST /api/users - Body:', JSON.stringify(body, null, 2));

    if (!wallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Wallet address required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const normalizedWallet = wallet.toLowerCase();

    // Check if user exists
    const existingUser = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: normalizedWallet 
    });

    if (existingUser) {
      console.log('📡 Updating existing user:', normalizedWallet);
      
      const updateData: Partial<User> = {};
      if (displayName !== undefined) updateData.displayName = displayName;
      if (username !== undefined) updateData.username = username;
      if (bio !== undefined) updateData.bio = bio;
      if (storeName !== undefined) updateData.storeName = storeName;
      if (storeCategory !== undefined) updateData.storeCategory = storeCategory;
      if (location !== undefined) updateData.location = location;
      if (userType !== undefined) updateData.userType = userType;

      await db.collection(COLLECTIONS.USERS).updateOne(
        { wallet: normalizedWallet },
        { $set: updateData }
      );

      const updatedUser = await db.collection(COLLECTIONS.USERS).findOne({ 
        wallet: normalizedWallet 
      });

      console.log('✅ User updated');

      return NextResponse.json<ApiResponse<User>>({
        success: true,
        data: toUser(updatedUser!),
      });
    }

    console.log('📡 Creating new user:', normalizedWallet);

    // Create new user
    const kycDeadline = new Date();
    kycDeadline.setDate(kycDeadline.getDate() + KYC_DEADLINE_DAYS);

    const newUser: Omit<User, '_id'> = {
      wallet: normalizedWallet,
      userType: userType ?? UserType.None,
      tier: UserTier.Anonymous,
      isActive: true,
      totalSales: '0',
      hasCustomFee: false,
      customFee: 0,
      registeredAt: new Date(),
      displayName: displayName || '',
      username: username || '',
      bio: bio || '',
      storeName: storeName || '',
      storeCategory: storeCategory || '',
      location: location || '',
      kycStatus: 'pending',
      kycDeadline,
    };

    const result = await db.collection(COLLECTIONS.USERS).insertOne(newUser);
    
    console.log('✅ User created with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<User>>({
      success: true,
      data: {
        ...newUser,
        _id: result.insertedId.toString(),
      } as User,
    });
  } catch (error) {
    console.error('❌ Error creating/updating user:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create/update user' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# HOOKS: USE-USER
# ============================================
echo "📝 Creating hooks/use-user.ts..."
cat > hooks/use-user.ts << 'EOF'
"use client";

import { useAccount } from "wagmi";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { User, UserType } from "@/types";

interface RegisterData {
  userType: UserType;
  displayName?: string;
  username?: string;
  bio?: string;
  storeName?: string;
  storeCategory?: string;
  location?: string;
}

export function useUser() {
  const { address, isConnected } = useAccount();
  const queryClient = useQueryClient();

  const { 
    data: user, 
    isLoading, 
    error,
    refetch 
  } = useQuery({
    queryKey: ["user", address],
    queryFn: async (): Promise<User | null> => {
      if (!address) return null;
      
      console.log("📡 Fetching user from API for:", address);
      
      const res = await fetch(`/api/users?wallet=${address}`);
      const json = await res.json();
      
      console.log("📡 API response:", json);
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: !!address && isConnected,
    staleTime: 1000 * 60 * 5,
  });

  const registerMutation = useMutation({
    mutationFn: async (data: RegisterData): Promise<User> => {
      console.log("📡 Registering user:", { wallet: address, ...data });
      
      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ wallet: address, ...data }),
      });
      const json = await res.json();
      
      console.log("📡 Registration response:", json);
      
      if (!json.success) throw new Error(json.error);
      return json.data as User;
    },
    onSuccess: (newUser) => {
      queryClient.setQueryData(["user", address], newUser);
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (data: Partial<RegisterData>): Promise<User> => {
      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ wallet: address, ...data }),
      });
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data as User;
    },
    onSuccess: (updatedUser) => {
      queryClient.setQueryData(["user", address], updatedUser);
    },
  });

  return {
    user,
    isLoading,
    error,
    refetch,
    isConnected,
    address,
    isRegistered: !!user && user.userType !== UserType.None,
    needsOnboarding: isConnected && !isLoading && (!user || user.userType === UserType.None),
    registerUser: registerMutation.mutate,
    registerUserAsync: registerMutation.mutateAsync,
    isRegistering: registerMutation.isPending,
    registerError: registerMutation.error,
    updateUser: updateMutation.mutate,
    updateUserAsync: updateMutation.mutateAsync,
    isUpdating: updateMutation.isPending,
    updateError: updateMutation.error,
  };
}
EOF

# ============================================
# COMPONENTS: BOTTOM NAV
# ============================================
echo "📝 Creating components/layout/bottom-nav.tsx..."
cat > components/layout/bottom-nav.tsx << 'EOF'
"use client";

import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { Home, Search, PlusCircle, Bell, User } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { href: '/', icon: Home, label: 'Feed' },
  { href: '/explore', icon: Search, label: 'Explore' },
  { href: '/create', icon: PlusCircle, label: 'Create' },
  { href: '/activity', icon: Bell, label: 'Activity' },
  { href: '/profile', icon: User, label: 'Profile' },
];

export function BottomNav() {
  const pathname = usePathname();

  if (pathname.startsWith('/onboarding')) {
    return null;
  }

  return (
    <nav className="bottom-nav">
      <div className="flex justify-around items-center max-w-lg mx-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn('nav-item', isActive && 'active')}
            >
              <item.icon className="w-5 h-5" />
              <span className="text-xs">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
EOF

# ============================================
# COMPONENTS: HEADER
# ============================================
echo "📝 Creating components/layout/header.tsx..."
cat > components/layout/header.tsx << 'EOF'
"use client";

import { usePathname } from 'next/navigation';
import { Wallet } from '@coinbase/onchainkit/wallet';
import { APP_NAME } from '@/lib/constants';

export function Header() {
  const pathname = usePathname();

  if (pathname.startsWith('/onboarding')) {
    return null;
  }

  return (
    <header className="sticky top-0 z-40 w-full">
      <div className="glass-card border-0 border-b border-[var(--border)] rounded-none">
        <div className="flex h-14 items-center justify-between px-4">
          <h1 className="text-xl font-bold text-gradient-brand">{APP_NAME}</h1>
          <Wallet />
        </div>
      </div>
    </header>
  );
}
EOF

# ============================================
# COMPONENTS: SPLASH SCREEN
# ============================================
echo "📝 Creating components/splash-screen.tsx..."
cat > components/splash-screen.tsx << 'EOF'
"use client";

import { useEffect, useState } from 'react';
import { APP_NAME, APP_TAGLINE } from '@/lib/constants';

interface SplashScreenProps {
  onComplete: () => void;
  duration?: number;
}

export function SplashScreen({ onComplete, duration = 2500 }: SplashScreenProps) {
  const [fadeOut, setFadeOut] = useState(false);

  useEffect(() => {
    const fadeTimer = setTimeout(() => setFadeOut(true), duration - 500);
    const completeTimer = setTimeout(onComplete, duration);
    return () => {
      clearTimeout(fadeTimer);
      clearTimeout(completeTimer);
    };
  }, [duration, onComplete]);

  return (
    <div className={`fixed inset-0 z-50 flex flex-col items-center justify-center gradient-bg transition-opacity duration-500 ${fadeOut ? 'opacity-0' : 'opacity-100'}`}>
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-[var(--pay-blue)] rounded-full blur-[150px] opacity-20 animate-pulse" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[300px] h-[300px] bg-[var(--pay-purple)] rounded-full blur-[100px] opacity-15 animate-pulse" style={{ animationDelay: '0.5s' }} />
      </div>
      <div className="relative z-10 flex flex-col items-center">
        <div className="relative mb-6">
          <div className="w-24 h-24 rounded-3xl gradient-border flex items-center justify-center animate-glow">
            <div className="w-[94px] h-[94px] rounded-[22px] bg-[var(--background)] flex items-center justify-center">
              <svg className="w-12 h-12" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="24" cy="24" r="20" stroke="url(#logoGradient)" strokeWidth="3" fill="none" />
                <path d="M24 12V36M18 18C18 15.8 20.7 14 24 14C27.3 14 30 15.8 30 18C30 20.2 27.3 22 24 22C20.7 22 18 23.8 18 26C18 28.2 20.7 30 24 30C27.3 30 30 28.2 30 26" stroke="url(#logoGradient)" strokeWidth="2.5" strokeLinecap="round" />
                <defs>
                  <linearGradient id="logoGradient" x1="4" y1="4" x2="44" y2="44" gradientUnits="userSpaceOnUse">
                    <stop stopColor="#6366f1" />
                    <stop offset="0.5" stopColor="#a855f7" />
                    <stop offset="1" stopColor="#10b981" />
                  </linearGradient>
                </defs>
              </svg>
            </div>
          </div>
        </div>
        <h1 className="text-4xl font-bold text-gradient-brand mb-2">{APP_NAME}</h1>
        <p className="text-[var(--muted-foreground)] text-sm">{APP_TAGLINE}</p>
        <div className="mt-8 flex gap-1">
          <div className="w-2 h-2 rounded-full bg-[var(--pay-blue)] animate-bounce" style={{ animationDelay: '0ms' }} />
          <div className="w-2 h-2 rounded-full bg-[var(--pay-purple)] animate-bounce" style={{ animationDelay: '150ms' }} />
          <div className="w-2 h-2 rounded-full bg-[var(--pay-green)] animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# ONBOARDING PAGE
# ============================================
echo "📝 Creating app/onboarding/page.tsx..."
cat > app/onboarding/page.tsx << 'EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useUser } from "@/hooks/use-user";
import { UserType } from "@/types";
import { APP_NAME, STORE_CATEGORIES } from "@/lib/constants";
import { toast } from "sonner";
import { ChevronLeft, Loader2, Store, Palette, ShoppingBag } from "lucide-react";

type Step = 'type' | 'profile' | 'complete';

export default function OnboardingPage() {
  const router = useRouter();
  const { address, isConnected, registerUserAsync, isRegistering } = useUser();
  
  const [step, setStep] = useState<Step>('type');
  const [userType, setUserType] = useState<UserType | null>(null);
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [bio, setBio] = useState('');
  const [storeName, setStoreName] = useState('');
  const [storeCategory, setStoreCategory] = useState('');

  if (!isConnected) {
    return (
      <div className="min-h-screen gradient-bg p-4 flex items-center justify-center">
        <div className="glass-card p-6 text-center max-w-md">
          <div className="text-4xl mb-4">🔗</div>
          <h2 className="text-xl font-bold mb-2">Connect Your Wallet</h2>
          <p className="text-[var(--muted-foreground)] text-sm">
            Please connect your wallet to continue.
          </p>
        </div>
      </div>
    );
  }

  const handleTypeSelect = (type: UserType) => {
    setUserType(type);
    setStep('profile');
  };

  const handleBack = () => {
    if (step === 'profile') setStep('type');
  };

  const handleSubmit = async () => {
    if (!userType || !address) return;

    if (!displayName.trim()) {
      toast.error('Please enter a display name');
      return;
    }

    if (userType === UserType.Store && !storeName.trim()) {
      toast.error('Please enter a store name');
      return;
    }

    try {
      await registerUserAsync({
        userType,
        displayName: displayName.trim(),
        username: username.trim() || displayName.trim().toLowerCase().replace(/\s+/g, ''),
        bio: bio.trim(),
        storeName: storeName.trim(),
        storeCategory,
      });

      setStep('complete');
      toast.success('Profile created successfully!');
      
      setTimeout(() => router.push('/'), 2000);
    } catch (error) {
      console.error('Registration error:', error);
      toast.error('Failed to create profile. Please try again.');
    }
  };

  return (
    <div className="min-h-screen gradient-bg">
      {/* Progress bar */}
      <div className="h-1 bg-[var(--border)]">
        <div 
          className="h-full bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] transition-all duration-500"
          style={{ width: step === 'type' ? '33%' : step === 'profile' ? '66%' : '100%' }}
        />
      </div>

      <div className="p-4 max-w-md mx-auto">
        {/* Header */}
        <div className="text-center py-6">
          <h1 className="text-2xl font-bold text-gradient-brand mb-2">
            {step === 'type' && 'Choose Your Role'}
            {step === 'profile' && 'Set Up Profile'}
            {step === 'complete' && 'Welcome to BasePay!'}
          </h1>
          <p className="text-[var(--muted-foreground)] text-sm">
            {step === 'type' && 'How will you use BasePay?'}
            {step === 'profile' && 'Tell us about yourself'}
            {step === 'complete' && 'Your profile is ready'}
          </p>
        </div>

        {/* Step: Type Selection */}
        {step === 'type' && (
          <div className="space-y-4">
            <button
              onClick={() => handleTypeSelect(UserType.Store)}
              className="w-full glass-card p-5 card-hover text-left flex items-start gap-4"
            >
              <div className="w-12 h-12 rounded-xl bg-[var(--pay-blue)]/20 flex items-center justify-center">
                <Store className="w-6 h-6 text-[var(--pay-blue)]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold mb-1">🏪 Store Owner</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  Sell products, manage orders, grow your business
                </p>
              </div>
            </button>

            <button
              onClick={() => handleTypeSelect(UserType.Creator)}
              className="w-full glass-card p-5 card-hover text-left flex items-start gap-4"
            >
              <div className="w-12 h-12 rounded-xl bg-[var(--pay-purple)]/20 flex items-center justify-center">
                <Palette className="w-6 h-6 text-[var(--pay-purple)]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold mb-1">🎨 Content Creator</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  Share content, receive tips, build your audience
                </p>
              </div>
            </button>

            <div className="divider my-4" />

            <button
              onClick={() => router.push('/')}
              className="w-full text-center text-sm text-[var(--muted-foreground)] py-2"
            >
              Skip for now, just browse
            </button>
          </div>
        )}

        {/* Step: Profile */}
        {step === 'profile' && (
          <div className="space-y-4">
            <button
              onClick={handleBack}
              className="flex items-center gap-1 text-sm text-[var(--muted-foreground)] mb-4"
            >
              <ChevronLeft className="w-4 h-4" /> Back
            </button>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Display Name *</label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Your name"
                className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
              />
            </div>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Username</label>
              <div className="flex items-center">
                <span className="text-[var(--muted-foreground)] text-sm mr-1">@</span>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                  placeholder="username"
                  className="flex-1 bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                />
              </div>
            </div>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Bio</label>
              <textarea
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                placeholder="Tell us about yourself..."
                rows={3}
                className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)] resize-none"
              />
            </div>

            {userType === UserType.Store && (
              <>
                <div className="glass-card p-4">
                  <label className="block text-sm font-medium mb-2">Store Name *</label>
                  <input
                    type="text"
                    value={storeName}
                    onChange={(e) => setStoreName(e.target.value)}
                    placeholder="Your store name"
                    className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                  />
                </div>

                <div className="glass-card p-4">
                  <label className="block text-sm font-medium mb-2">Category</label>
                  <select
                    value={storeCategory}
                    onChange={(e) => setStoreCategory(e.target.value)}
                    className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                  >
                    <option value="">Select category</option>
                    {STORE_CATEGORIES.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.icon} {cat.label}
                      </option>
                    ))}
                  </select>
                </div>
              </>
            )}

            <button
              onClick={handleSubmit}
              disabled={isRegistering}
              className="w-full btn-pay flex items-center justify-center gap-2"
            >
              {isRegistering ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Creating Profile...
                </>
              ) : (
                'Create Profile'
              )}
            </button>
          </div>
        )}

        {/* Step: Complete */}
        {step === 'complete' && (
          <div className="text-center py-8">
            <div className="w-20 h-20 rounded-full bg-[var(--pay-green)]/20 flex items-center justify-center mx-auto mb-6">
              <span className="text-4xl">✓</span>
            </div>
            <h2 className="text-xl font-bold mb-2">You're All Set!</h2>
            <p className="text-[var(--muted-foreground)] text-sm mb-6">
              Redirecting you to the feed...
            </p>
            <div className="shimmer h-2 w-32 mx-auto rounded-full" />
          </div>
        )}
      </div>
    </div>
  );
}
EOF

# ============================================
# UPDATE APP/LAYOUT.TSX
# ============================================
echo "📝 Updating app/layout.tsx..."
cat > app/layout.tsx << 'EOF'
import type { Metadata } from "next";
import { Inter, Source_Code_Pro } from "next/font/google";
import { SafeArea } from "@coinbase/onchainkit/minikit";
import { minikitConfig } from "@/minikit.config";
import { RootProvider } from "./rootProvider";
import { Header } from "@/components/layout/header";
import { BottomNav } from "@/components/layout/bottom-nav";
import { Toaster } from "sonner";
import "./globals.css";

export async function generateMetadata(): Promise<Metadata> {
  return {
    title: minikitConfig.miniapp.name,
    description: minikitConfig.miniapp.description,
    other: {
      "fc:miniapp": JSON.stringify({
        version: minikitConfig.miniapp.version,
        imageUrl: minikitConfig.miniapp.heroImageUrl,
        button: {
          title: `Launch ${minikitConfig.miniapp.name}`,
          action: {
            name: `Launch ${minikitConfig.miniapp.name}`,
            type: "launch_miniapp",
          },
        },
      }),
    },
  };
}

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const sourceCodePro = Source_Code_Pro({
  variable: "--font-source-code-pro",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <RootProvider>
      <html lang="en">
        <body className={`${inter.variable} ${sourceCodePro.variable}`}>
          <SafeArea>
            <div className="min-h-screen gradient-bg flex flex-col">
              <Header />
              <main className="flex-1 pb-20">
                {children}
              </main>
              <BottomNav />
            </div>
            <Toaster position="top-center" richColors />
          </SafeArea>
        </body>
      </html>
    </RootProvider>
  );
}
EOF

# ============================================
# UPDATE APP/PAGE.TSX
# ============================================
echo "📝 Updating app/page.tsx..."
cat > app/page.tsx << 'EOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import { useMiniKit } from "@coinbase/onchainkit/minikit";
import { SplashScreen } from "@/components/splash-screen";
import { useUser } from "@/hooks/use-user";
import { APP_NAME } from "@/lib/constants";
import Link from "next/link";

export default function Home() {
  const [showSplash, setShowSplash] = useState(true);
  const { setMiniAppReady, isMiniAppReady } = useMiniKit();
  const { user, isLoading, isConnected, needsOnboarding, address } = useUser();

  useEffect(() => {
    if (!isMiniAppReady) {
      setMiniAppReady();
    }
  }, [setMiniAppReady, isMiniAppReady]);

  const handleSplashComplete = useCallback(() => {
    setShowSplash(false);
  }, []);

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashComplete} />;
  }

  if (isConnected && isLoading) {
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

  return (
    <div className="p-4">
      <div className="glass-card-highlight p-6 mb-6">
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

      <div className="grid grid-cols-2 gap-4 mb-6">
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
        <div className="glass-card p-4 card-hover">
          <div className="text-2xl mb-2">💰</div>
          <h3 className="font-semibold text-sm">Earn $PAY</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Rewards & cashback</p>
        </div>
        <Link href="/create" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🏪</div>
          <h3 className="font-semibold text-sm">Start Selling</h3>
          <p className="text-xs text-[var(--muted-foreground)]">List your products</p>
        </Link>
      </div>

      <div className="mb-4">
        <h3 className="text-lg font-semibold mb-3">Trending Now 🔥</h3>
        
        <div className="glass-card overflow-hidden card-hover mb-4">
          <div className="h-40 bg-gradient-to-br from-[var(--pay-blue)]/20 to-[var(--pay-purple)]/20 flex items-center justify-center">
            <span className="text-4xl">🎧</span>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 mb-2">
              <span className="badge-verified">✓ Verified</span>
            </div>
            <h4 className="font-semibold mb-1">Premium Wireless Headphones</h4>
            <p className="text-xs text-[var(--muted-foreground)] mb-3">TechStore Official</p>
            <div className="flex items-center justify-between">
              <span className="price-gradient text-lg">₹2,999</span>
              <button className="btn-pay text-sm py-2 px-4">Buy Now</button>
            </div>
          </div>
        </div>

        <div className="glass-card overflow-hidden card-hover">
          <div className="h-32 bg-gradient-to-br from-[var(--pay-purple)]/20 to-[var(--pay-green)]/20 flex items-center justify-center relative">
            <span className="text-4xl">▶️</span>
            <span className="absolute bottom-2 right-2 badge-live">Live</span>
          </div>
          <div className="p-4">
            <h4 className="font-semibold mb-1">Building the Future of Commerce</h4>
            <p className="text-xs text-[var(--muted-foreground)] mb-3">@TechCreator • 12K views</p>
            <div className="flex items-center justify-between">
              <div className="flex gap-4 text-xs text-[var(--muted-foreground)]">
                <span>❤️ 1.2K</span>
                <span>💬 45</span>
              </div>
              <button className="tip-button text-sm py-2 px-4">💰 Tip</button>
            </div>
          </div>
        </div>
      </div>

      <div className="glass-card-success p-4">
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">1,234</div>
            <div className="text-xs text-[var(--muted-foreground)]">Products</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">567</div>
            <div className="text-xs text-[var(--muted-foreground)]">Creators</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-blue)]">89</div>
            <div className="text-xs text-[var(--muted-foreground)]">Stores</div>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# CREATE .ENV.LOCAL TEMPLATE
# ============================================
echo "📝 Creating .env.local.example..."
cat > .env.local.example << 'EOF'
# MongoDB Connection (REQUIRED)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority

# Contract Addresses (Base Sepolia)
NEXT_PUBLIC_PAYMENT_HUB_ADDRESS=0x...
NEXT_PUBLIC_BASE_PAY_TOKEN_ADDRESS=0x...

# OnchainKit
NEXT_PUBLIC_ONCHAINKIT_PROJECT_NAME=BasePay
NEXT_PUBLIC_ONCHAINKIT_API_KEY=your_api_key

# App URL
NEXT_PUBLIC_URL=http://localhost:3000
EOF

echo ""
echo "============================================"
echo "✅ Setup Complete!"
echo "============================================"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Make sure MONGODB_URI is in your .env.local"
echo ""
echo "2. Start the app:"
echo "   npm run dev"
echo ""
echo "3. Initialize the database (ONE TIME ONLY):"
echo "   Open: http://localhost:3000/api/init"
echo "   Or run: curl -X POST http://localhost:3000/api/init"
echo ""
echo "4. Check database status:"
echo "   http://localhost:3000/api/init (GET)"
echo ""
echo "5. Test health:"
echo "   http://localhost:3000/api/health"
echo ""
echo "============================================"
echo "🎯 USER FLOW:"
echo "============================================"
echo "1. User opens app → Splash screen (2.5s)"
echo "2. User connects wallet"
echo "3. API checks if user exists → null (not found)"
echo "4. User sees 'Set Up Profile' button"
echo "5. User clicks → goes to /onboarding"
echo "6. User selects role (Store/Creator)"
echo "7. User fills profile → clicks 'Create Profile'"
echo "8. API creates user in MongoDB"
echo "9. User redirected to home with their profile"
echo "============================================"
echo ""