import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { User, UserType, ApiResponse } from '@/types';
import { WithId, Document } from 'mongodb';

function toUser(doc: WithId<Document>): User {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as User;
}

// GET - List stores
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const search = searchParams.get('search');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {
      userType: UserType.Store,
      isActive: true,
    };
    
    if (category) {
      query.storeCategory = category;
    }
    if (search) {
      query.$or = [
        { storeName: { $regex: search, $options: 'i' } },
        { displayName: { $regex: search, $options: 'i' } },
      ];
    }

    console.log('📡 GET /api/stores - Query:', JSON.stringify(query));

    const stores = await db
      .collection(COLLECTIONS.USERS)
      .find(query)
      .sort({ totalSales: -1, registeredAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.USERS).countDocuments(query);

    // Get product counts for each store
    const storeWallets = stores.map(s => s.wallet);
    const productCounts = await db
      .collection(COLLECTIONS.PRODUCTS)
      .aggregate([
        { $match: { seller: { $in: storeWallets }, isActive: true } },
        { $group: { _id: '$seller', count: { $sum: 1 } } },
      ])
      .toArray();

    const productCountMap = new Map(productCounts.map(p => [p._id, p.count]));

    const storesWithCounts = stores.map(s => ({
      ...toUser(s),
      productCount: productCountMap.get(s.wallet) || 0,
    }));

    return NextResponse.json<ApiResponse<{ stores: any[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        stores: storesWithCounts,
        total,
        hasMore: skip + stores.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching stores:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch stores' },
      { status: 500 }
    );
  }
}
