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

// GET - List creators
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {
      userType: UserType.Creator,
      isActive: true,
    };
    
    if (search) {
      query.$or = [
        { displayName: { $regex: search, $options: 'i' } },
        { username: { $regex: search, $options: 'i' } },
      ];
    }

    console.log('📡 GET /api/creators - Query:', JSON.stringify(query));

    const creators = await db
      .collection(COLLECTIONS.USERS)
      .find(query)
      .sort({ registeredAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.USERS).countDocuments(query);

    // Get content counts and total tips for each creator
    const creatorWallets = creators.map(c => c.wallet);
    
    const [contentCounts, tipTotals] = await Promise.all([
      db.collection(COLLECTIONS.CONTENT)
        .aggregate([
          { $match: { creator: { $in: creatorWallets } } },
          { $group: { _id: '$creator', count: { $sum: 1 } } },
        ])
        .toArray(),
      db.collection(COLLECTIONS.TIPS)
        .aggregate([
          { $match: { to: { $in: creatorWallets } } },
          { $group: { _id: '$to', totalTips: { $sum: { $toDouble: '$amount' } }, tipCount: { $sum: 1 } } },
        ])
        .toArray(),
    ]);

    const contentCountMap = new Map(contentCounts.map(c => [c._id, c.count]));
    const tipTotalMap = new Map(tipTotals.map(t => [t._id, { total: t.totalTips, count: t.tipCount }]));

    const creatorsWithStats = creators.map(c => ({
      ...toUser(c),
      contentCount: contentCountMap.get(c.wallet) || 0,
      totalTipsReceived: tipTotalMap.get(c.wallet)?.total?.toString() || '0',
      tipCount: tipTotalMap.get(c.wallet)?.count || 0,
    }));

    return NextResponse.json<ApiResponse<{ creators: any[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        creators: creatorsWithStats,
        total,
        hasMore: skip + creators.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching creators:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch creators' },
      { status: 500 }
    );
  }
}
