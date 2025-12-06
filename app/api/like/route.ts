import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { ApiResponse } from '@/types';
import { ObjectId } from 'mongodb';

// POST - Like content or product
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { itemId, itemType, userWallet } = body;

    if (!itemId || !itemType || !userWallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'itemId, itemType, and userWallet are required' },
        { status: 400 }
      );
    }

    if (!['product', 'content'].includes(itemType)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid itemType' },
        { status: 400 }
      );
    }

    if (!ObjectId.isValid(itemId)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid itemId' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const collection = itemType === 'product' ? COLLECTIONS.PRODUCTS : COLLECTIONS.CONTENT;

    // Increment like count
    const result = await db.collection(collection).findOneAndUpdate(
      { _id: new ObjectId(itemId) },
      { $inc: { likes: 1 } },
      { returnDocument: 'after' }
    );

    if (!result) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Item not found' },
        { status: 404 }
      );
    }

    return NextResponse.json<ApiResponse<{ likes: number }>>({
      success: true,
      data: { likes: result.likes || 1 },
    });
  } catch (error) {
    console.error('❌ Error liking item:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to like item' },
      { status: 500 }
    );
  }
}
