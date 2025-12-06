import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Tip, ApiResponse } from '@/types';
import { WithId, Document, ObjectId } from 'mongodb';

function toTip(doc: WithId<Document>): Tip {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Tip;
}

// GET - List tips with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const from = searchParams.get('from');
    const to = searchParams.get('to');
    const contentId = searchParams.get('contentId');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {};
    
    if (from) {
      query.from = from.toLowerCase();
    }
    if (to) {
      query.to = to.toLowerCase();
    }
    if (contentId) {
      query.contentId = contentId;
    }

    console.log('📡 GET /api/tips - Query:', JSON.stringify(query));

    const tips = await db
      .collection(COLLECTIONS.TIPS)
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.TIPS).countDocuments(query);

    // Calculate totals
    const pipeline = [
      { $match: query },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: { $toDouble: '$amount' } },
          count: { $sum: 1 },
        },
      },
    ];
    const aggregation = await db.collection(COLLECTIONS.TIPS).aggregate(pipeline).toArray();
    const stats = aggregation[0] || { totalAmount: 0, count: 0 };

    return NextResponse.json<ApiResponse<{ tips: Tip[]; total: number; hasMore: boolean; stats: any }>>({
      success: true,
      data: {
        tips: tips.map(toTip),
        total,
        hasMore: skip + tips.length < total,
        stats: {
          totalAmount: stats.totalAmount.toString(),
          count: stats.count,
        },
      },
    });
  } catch (error) {
    console.error('❌ Error fetching tips:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch tips' },
      { status: 500 }
    );
  }
}

// POST - Record new tip
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      contentId,
      from,
      to,
      amount,
      paymentToken,
      txHash,
    } = body;

    console.log('📡 POST /api/tips - Body:', JSON.stringify(body, null, 2));

    // Validation
    if (!from || !to || !amount || !txHash) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'from, to, amount, and txHash are required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();

    const newTip: Omit<Tip, '_id'> = {
      contentId: contentId || '',
      from: from.toLowerCase(),
      to: to.toLowerCase(),
      amount: amount.toString(),
      paymentToken: paymentToken || '0x0000000000000000000000000000000000000000',
      txHash,
      createdAt: new Date(),
    };

    const result = await db.collection(COLLECTIONS.TIPS).insertOne(newTip);

    // Update content tips total if contentId provided
    if (contentId && ObjectId.isValid(contentId)) {
      await db.collection(COLLECTIONS.CONTENT).updateOne(
        { _id: new ObjectId(contentId) },
        { 
          $inc: { 
            tipsCount: 1,
          },
          $set: {
            lastTipAt: new Date(),
          }
        }
      );
    }

    console.log('✅ Tip recorded with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<Tip>>({
      success: true,
      data: {
        ...newTip,
        _id: result.insertedId.toString(),
      } as Tip,
    });
  } catch (error) {
    console.error('❌ Error recording tip:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to record tip' },
      { status: 500 }
    );
  }
}
