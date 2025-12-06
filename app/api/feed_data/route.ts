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
