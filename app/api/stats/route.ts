import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { UserType, ApiResponse } from '@/types';

// GET - Platform statistics
export async function GET(request: NextRequest) {
  try {
    const db = await getDatabase();
    
    const [
      totalUsers,
      totalStores,
      totalCreators,
      totalProducts,
      totalContent,
      totalOrders,
      totalTips,
    ] = await Promise.all([
      db.collection(COLLECTIONS.USERS).countDocuments({ isActive: true }),
      db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Store, isActive: true }),
      db.collection(COLLECTIONS.USERS).countDocuments({ userType: UserType.Creator, isActive: true }),
      db.collection(COLLECTIONS.PRODUCTS).countDocuments({ isActive: true }),
      db.collection(COLLECTIONS.CONTENT).countDocuments({}),
      db.collection(COLLECTIONS.ORDERS).countDocuments({}),
      db.collection(COLLECTIONS.TIPS).countDocuments({}),
    ]);

    // Get total order volume
    const orderVolume = await db.collection(COLLECTIONS.ORDERS)
      .aggregate([
        { $group: { _id: null, total: { $sum: { $toDouble: '$amount' } } } },
      ])
      .toArray();

    // Get total tips volume
    const tipsVolume = await db.collection(COLLECTIONS.TIPS)
      .aggregate([
        { $group: { _id: null, total: { $sum: { $toDouble: '$amount' } } } },
      ])
      .toArray();

    return NextResponse.json<ApiResponse<{
      users: number;
      stores: number;
      creators: number;
      products: number;
      content: number;
      orders: number;
      tips: number;
      orderVolume: string;
      tipsVolume: string;
    }>>({
      success: true,
      data: {
        users: totalUsers,
        stores: totalStores,
        creators: totalCreators,
        products: totalProducts,
        content: totalContent,
        orders: totalOrders,
        tips: totalTips,
        orderVolume: (orderVolume[0]?.total || 0).toString(),
        tipsVolume: (tipsVolume[0]?.total || 0).toString(),
      },
    });
  } catch (error) {
    console.error('❌ Error fetching stats:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch stats' },
      { status: 500 }
    );
  }
}
