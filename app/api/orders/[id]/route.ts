import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Order, ApiResponse } from '@/types';
import { ObjectId, WithId, Document } from 'mongodb';

function toOrder(doc: WithId<Document>): Order {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Order;
}

// GET - Get single order
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid order ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const order = await db.collection(COLLECTIONS.ORDERS).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!order) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Order not found' },
        { status: 404 }
      );
    }

    // Get product info
    let product = null;
    if (order.productId && ObjectId.isValid(order.productId)) {
      product = await db.collection(COLLECTIONS.PRODUCTS).findOne({
        _id: new ObjectId(order.productId)
      });
    }

    // Get buyer and seller info
    const [buyerInfo, sellerInfo] = await Promise.all([
      db.collection(COLLECTIONS.USERS).findOne({ wallet: order.buyer }),
      db.collection(COLLECTIONS.USERS).findOne({ wallet: order.seller }),
    ]);

    return NextResponse.json<ApiResponse<{ order: Order; product: any; buyer: any; seller: any }>>({
      success: true,
      data: {
        order: toOrder(order),
        product: product ? {
          title: product.title,
          images: product.images,
          description: product.description,
        } : null,
        buyer: buyerInfo ? {
          displayName: buyerInfo.displayName,
          username: buyerInfo.username,
        } : null,
        seller: sellerInfo ? {
          displayName: sellerInfo.displayName,
          storeName: sellerInfo.storeName,
          location: sellerInfo.location,
        } : null,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching order:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch order' },
      { status: 500 }
    );
  }
}

// PATCH - Update order status
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { status, trackingInfo, userWallet } = body;

    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid order ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    const existing = await db.collection(COLLECTIONS.ORDERS).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Order not found' },
        { status: 404 }
      );
    }

    // Verify authorization (buyer or seller)
    const normalizedWallet = userWallet?.toLowerCase();
    if (normalizedWallet && 
        existing.buyer !== normalizedWallet && 
        existing.seller !== normalizedWallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Not authorized to update this order' },
        { status: 403 }
      );
    }

    // Validate status transitions
    const validStatuses = ['pending', 'confirmed', 'ready', 'shipped', 'delivered', 'disputed', 'cancelled'];
    if (status && !validStatuses.includes(status)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid status' },
        { status: 400 }
      );
    }

    const updateData: Record<string, any> = { updatedAt: new Date() };
    if (status) updateData.status = status;
    if (trackingInfo) updateData.trackingInfo = trackingInfo;

    const result = await db.collection(COLLECTIONS.ORDERS).findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: updateData },
      { returnDocument: 'after' }
    );

    if (!result) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Failed to update order' },
        { status: 500 }
      );
    }

    return NextResponse.json<ApiResponse<Order>>({
      success: true,
      data: toOrder(result),
    });
  } catch (error) {
    console.error('❌ Error updating order:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to update order' },
      { status: 500 }
    );
  }
}
