import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { ApiResponse } from '@/types';

interface FeedItem {
  _id: string;
  type: 'product' | 'content';
  createdAt: Date;
  data: any;
  user: any;
}

// GET - Combined feed
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const filter = searchParams.get('filter') || 'all'; // all, products, creators
    const category = searchParams.get('category');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    let feedItems: FeedItem[] = [];

    // Fetch products
    if (filter === 'all' || filter === 'products') {
      const productQuery: Record<string, any> = { isActive: true };
      if (category) productQuery.category = category;

      const products = await db
        .collection(COLLECTIONS.PRODUCTS)
        .find(productQuery)
        .sort({ createdAt: -1 })
        .limit(filter === 'all' ? Math.ceil(limit / 2) : limit)
        .skip(filter === 'products' ? skip : 0)
        .toArray();

      // Get seller info
      const sellerWallets = [...new Set(products.map(p => p.seller))];
      const sellers = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: sellerWallets } })
        .toArray();
      const sellerMap = new Map(sellers.map(s => [s.wallet, s]));

      const productItems: FeedItem[] = products.map(p => ({
        _id: p._id.toString(),
        type: 'product',
        createdAt: p.createdAt,
        data: {
          title: p.title,
          description: p.description,
          price: p.price,
          images: p.images,
          category: p.category,
          stock: p.stock,
          deliveryOptions: p.deliveryOptions,
        },
        user: sellerMap.get(p.seller) ? {
          wallet: p.seller,
          displayName: sellerMap.get(p.seller)?.displayName,
          storeName: sellerMap.get(p.seller)?.storeName,
          username: sellerMap.get(p.seller)?.username,
          avatar: sellerMap.get(p.seller)?.avatar,
          tier: sellerMap.get(p.seller)?.tier,
          userType: sellerMap.get(p.seller)?.userType,
        } : null,
      }));

      feedItems = [...feedItems, ...productItems];
    }

    // Fetch content
    if (filter === 'all' || filter === 'creators') {
      const contentQuery: Record<string, any> = {};
      if (category) contentQuery.category = category;

      const content = await db
        .collection(COLLECTIONS.CONTENT)
        .find(contentQuery)
        .sort({ createdAt: -1 })
        .limit(filter === 'all' ? Math.ceil(limit / 2) : limit)
        .skip(filter === 'creators' ? skip : 0)
        .toArray();

      // Get creator info
      const creatorWallets = [...new Set(content.map(c => c.creator))];
      const creators = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: creatorWallets } })
        .toArray();
      const creatorMap = new Map(creators.map(c => [c.wallet, c]));

      const contentItems: FeedItem[] = content.map(c => ({
        _id: c._id.toString(),
        type: 'content',
        createdAt: c.createdAt,
        data: {
          platform: c.platform,
          url: c.url,
          title: c.title,
          description: c.description,
          thumbnail: c.thumbnail,
          category: c.category,
          suggestedTip: c.suggestedTip,
          likes: c.likes,
          tips: c.tips,
        },
        user: creatorMap.get(c.creator) ? {
          wallet: c.creator,
          displayName: creatorMap.get(c.creator)?.displayName,
          username: creatorMap.get(c.creator)?.username,
          avatar: creatorMap.get(c.creator)?.avatar,
          tier: creatorMap.get(c.creator)?.tier,
          userType: creatorMap.get(c.creator)?.userType,
        } : null,
      }));

      feedItems = [...feedItems, ...contentItems];
    }

    // Sort combined feed by date
    feedItems.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    // Apply pagination for 'all' filter
    if (filter === 'all') {
      feedItems = feedItems.slice(skip, skip + limit);
    }

    // Get total counts
    const [productsTotal, contentTotal] = await Promise.all([
      db.collection(COLLECTIONS.PRODUCTS).countDocuments({ isActive: true }),
      db.collection(COLLECTIONS.CONTENT).countDocuments({}),
    ]);

    const total = filter === 'products' ? productsTotal : 
                  filter === 'creators' ? contentTotal : 
                  productsTotal + contentTotal;

    console.log(`📡 GET /api/feed - Filter: ${filter}, Items: ${feedItems.length}`);

    return NextResponse.json<ApiResponse<{ 
      items: FeedItem[]; 
      total: number; 
      hasMore: boolean;
      counts: { products: number; content: number };
    }>>({
      success: true,
      data: {
        items: feedItems,
        total,
        hasMore: skip + feedItems.length < total,
        counts: {
          products: productsTotal,
          content: contentTotal,
        },
      },
    });
  } catch (error) {
    console.error('❌ Error fetching feed:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch feed' },
      { status: 500 }
    );
  }
}
