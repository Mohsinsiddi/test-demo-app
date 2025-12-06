import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { UserType, ApiResponse } from '@/types';
import { WithId, Document } from 'mongodb';

interface SearchResult {
  type: 'product' | 'store' | 'creator' | 'content';
  _id: string;
  title: string;
  subtitle?: string;
  image?: string;
  price?: string;
  tier?: number;
  category?: string;
  wallet?: string;
}

// GET - Unified search across products, stores, creators, content
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const query = searchParams.get('q') || '';
    const type = searchParams.get('type'); // 'all' | 'products' | 'stores' | 'creators' | 'content'
    const category = searchParams.get('category');
    const limit = parseInt(searchParams.get('limit') || '20');

    const db = await getDatabase();
    const results: SearchResult[] = [];

    const searchRegex = query ? { $regex: query, $options: 'i' } : null;

    // Search Products
    if (!type || type === 'all' || type === 'products') {
      const productQuery: Record<string, any> = { isActive: true };
      if (searchRegex) {
        productQuery.$or = [
          { title: searchRegex },
          { description: searchRegex },
        ];
      }
      if (category) {
        productQuery.category = category;
      }

      const products = await db
        .collection(COLLECTIONS.PRODUCTS)
        .find(productQuery)
        .sort({ createdAt: -1 })
        .limit(type === 'products' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get seller info
      const sellerWallets = [...new Set(products.map(p => p.seller))];
      const sellers = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: sellerWallets } })
        .toArray();
      const sellerMap = new Map(sellers.map(s => [s.wallet, s]));

      products.forEach(p => {
        const seller = sellerMap.get(p.seller);
        results.push({
          type: 'product',
          _id: p._id.toString(),
          title: p.title,
          subtitle: seller?.storeName || seller?.displayName || 'Unknown Store',
          image: p.images?.[0] || '📦',
          price: p.price,
          tier: seller?.tier,
          category: p.category,
        });
      });
    }

    // Search Stores
    if (!type || type === 'all' || type === 'stores') {
      const storeQuery: Record<string, any> = { 
        userType: UserType.Store, 
        isActive: true 
      };
      if (searchRegex) {
        storeQuery.$or = [
          { storeName: searchRegex },
          { displayName: searchRegex },
          { username: searchRegex },
        ];
      }
      if (category) {
        storeQuery.storeCategory = category;
      }

      const stores = await db
        .collection(COLLECTIONS.USERS)
        .find(storeQuery)
        .sort({ totalSales: -1 })
        .limit(type === 'stores' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get product counts
      const storeWallets = stores.map(s => s.wallet);
      const productCounts = await db
        .collection(COLLECTIONS.PRODUCTS)
        .aggregate([
          { $match: { seller: { $in: storeWallets }, isActive: true } },
          { $group: { _id: '$seller', count: { $sum: 1 } } },
        ])
        .toArray();
      const countMap = new Map(productCounts.map(p => [p._id, p.count]));

      stores.forEach(s => {
        results.push({
          type: 'store',
          _id: s._id.toString(),
          title: s.storeName || s.displayName,
          subtitle: `${countMap.get(s.wallet) || 0} products`,
          image: s.avatar || '🏪',
          tier: s.tier,
          category: s.storeCategory,
          wallet: s.wallet,
        });
      });
    }

    // Search Creators
    if (!type || type === 'all' || type === 'creators') {
      const creatorQuery: Record<string, any> = { 
        userType: UserType.Creator, 
        isActive: true 
      };
      if (searchRegex) {
        creatorQuery.$or = [
          { displayName: searchRegex },
          { username: searchRegex },
          { bio: searchRegex },
        ];
      }

      const creators = await db
        .collection(COLLECTIONS.USERS)
        .find(creatorQuery)
        .sort({ registeredAt: -1 })
        .limit(type === 'creators' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get content counts
      const creatorWallets = creators.map(c => c.wallet);
      const contentCounts = await db
        .collection(COLLECTIONS.CONTENT)
        .aggregate([
          { $match: { creator: { $in: creatorWallets } } },
          { $group: { _id: '$creator', count: { $sum: 1 } } },
        ])
        .toArray();
      const contentMap = new Map(contentCounts.map(c => [c._id, c.count]));

      creators.forEach(c => {
        results.push({
          type: 'creator',
          _id: c._id.toString(),
          title: c.displayName || c.username,
          subtitle: `@${c.username} • ${contentMap.get(c.wallet) || 0} posts`,
          image: c.avatar || '🎨',
          tier: c.tier,
          wallet: c.wallet,
        });
      });
    }

    // Search Content
    if (!type || type === 'all' || type === 'content') {
      const contentQuery: Record<string, any> = {};
      if (searchRegex) {
        contentQuery.$or = [
          { title: searchRegex },
          { description: searchRegex },
        ];
      }
      if (category) {
        contentQuery.category = category;
      }

      const content = await db
        .collection(COLLECTIONS.CONTENT)
        .find(contentQuery)
        .sort({ createdAt: -1 })
        .limit(type === 'content' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get creator info
      const creatorWallets = [...new Set(content.map(c => c.creator))];
      const creators = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: creatorWallets } })
        .toArray();
      const creatorMap = new Map(creators.map(c => [c.wallet, c]));

      content.forEach(c => {
        const creator = creatorMap.get(c.creator);
        results.push({
          type: 'content',
          _id: c._id.toString(),
          title: c.title || 'Untitled',
          subtitle: `@${creator?.username || 'creator'} • ${c.platform}`,
          image: c.thumbnail || '📺',
          category: c.category,
          wallet: c.creator,
        });
      });
    }

    // Sort results (prioritize exact matches if searching)
    if (query) {
      results.sort((a, b) => {
        const aExact = a.title.toLowerCase().includes(query.toLowerCase()) ? 1 : 0;
        const bExact = b.title.toLowerCase().includes(query.toLowerCase()) ? 1 : 0;
        return bExact - aExact;
      });
    }

    console.log(`📡 GET /api/search - q="${query}" type=${type} → ${results.length} results`);

    return NextResponse.json<ApiResponse<{ results: SearchResult[]; total: number }>>({
      success: true,
      data: {
        results: results.slice(0, limit),
        total: results.length,
      },
    });
  } catch (error) {
    console.error('❌ Error searching:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to search' },
      { status: 500 }
    );
  }
}
