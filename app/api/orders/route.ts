import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Order, ApiResponse } from '@/types';
import { WithId, Document } from 'mongodb';

function toOrder(doc: WithId<Document>): Order {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Order;
}

// GET - List orders with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const buyer = searchParams.get('buyer');
    const seller = searchParams.get('seller');
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {};
    
    if (buyer) {
      query.buyer = buyer.toLowerCase();
    }
    if (seller) {
      query.seller = seller.toLowerCase();
    }
    if (status) {
      query.status = status;
    }

    console.log('📡 GET /api/orders - Query:', JSON.stringify(query));

    const orders = await db
      .collection(COLLECTIONS.ORDERS)
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.ORDERS).countDocuments(query);

    // Get product info for each order
    const productIds = orders.map(o => o.productId).filter(Boolean);
    const products = await db
      .collection(COLLECTIONS.PRODUCTS)
      .find({ _id: { $in: productIds.map(id => new (require('mongodb').ObjectId)(id)) } })
      .toArray();

    const productMap = new Map(products.map(p => [p._id.toString(), p]));

    const ordersWithProducts = orders.map(o => ({
      ...toOrder(o),
      product: productMap.get(o.productId) ? {
        title: productMap.get(o.productId)?.title,
        images: productMap.get(o.productId)?.images,
        price: productMap.get(o.productId)?.price,
      } : null,
    }));

    return NextResponse.json<ApiResponse<{ orders: any[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        orders: ordersWithProducts,
        total,
        hasMore: skip + orders.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching orders:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch orders' },
      { status: 500 }
    );
  }
}

// POST - Create new order
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      productId,
      buyer,
      seller,
      amount,
      fee,
      paymentToken,
      deliveryType,
      shippingAddress,
      txHash,
    } = body;

    console.log('📡 POST /api/orders - Body:', JSON.stringify(body, null, 2));

    // Validation
    if (!productId || !buyer || !seller || !amount || !txHash) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'productId, buyer, seller, amount, and txHash are required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();

    const newOrder: Omit<Order, '_id'> = {
      productId,
      buyer: buyer.toLowerCase(),
      seller: seller.toLowerCase(),
      amount: amount.toString(),
      fee: fee?.toString() || '0',
      paymentToken: paymentToken || '0x0000000000000000000000000000000000000000',
      status: 'pending',
      deliveryType: deliveryType || 'pickup',
      shippingAddress: shippingAddress || '',
      trackingInfo: '',
      txHash,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const result = await db.collection(COLLECTIONS.ORDERS).insertOne(newOrder);

    console.log('✅ Order created with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<Order>>({
      success: true,
      data: {
        ...newOrder,
        _id: result.insertedId.toString(),
      } as Order,
    });
  } catch (error) {
    console.error('❌ Error creating order:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create order' },
      { status: 500 }
    );
  }
}
