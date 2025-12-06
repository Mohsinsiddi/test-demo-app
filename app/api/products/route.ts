import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Product, ApiResponse } from '@/types';
import { ObjectId, WithId, Document } from 'mongodb';

// Helper to convert MongoDB document to Product type
function toProduct(doc: WithId<Document>): Product {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Product;
}

// GET - List products with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const seller = searchParams.get('seller');
    const category = searchParams.get('category');
    const isActive = searchParams.get('isActive');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');
    const search = searchParams.get('search');

    const db = await getDatabase();
    
    // Build query
    const query: Record<string, any> = {};
    
    if (seller) {
      query.seller = seller.toLowerCase();
    }
    if (category) {
      query.category = category;
    }
    if (isActive !== null && isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    console.log('📡 GET /api/products - Query:', JSON.stringify(query));

    const products = await db
      .collection(COLLECTIONS.PRODUCTS)
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.PRODUCTS).countDocuments(query);

    console.log(`📡 Found ${products.length} products (total: ${total})`);

    return NextResponse.json<ApiResponse<{ products: Product[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        products: products.map(toProduct),
        total,
        hasMore: skip + products.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching products:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch products' },
      { status: 500 }
    );
  }
}

// POST - Create new product
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      seller,
      price,
      paymentToken,
      metadataUri,
      title,
      description,
      images,
      category,
      stock,
      deliveryOptions,
      contractId,
    } = body;

    console.log('📡 POST /api/products - Body:', JSON.stringify(body, null, 2));

    // Validation
    if (!seller || !title || !price) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'seller, title, and price are required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();

    // Check if seller is registered
    const user = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: seller.toLowerCase() 
    });

    if (!user) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Seller not registered' },
        { status: 400 }
      );
    }

    const newProduct: Omit<Product, '_id'> = {
      contractId: contractId || 0,
      seller: seller.toLowerCase(),
      price: price.toString(),
      paymentToken: paymentToken || '0x0000000000000000000000000000000000000000',
      isActive: true,
      metadataUri: metadataUri || '',
      createdAt: new Date(),
      title,
      description: description || '',
      images: images || [],
      category: category || 'other',
      stock: stock ?? 1,
      deliveryOptions: deliveryOptions || { pickup: true, shipping: false },
    };

    const result = await db.collection(COLLECTIONS.PRODUCTS).insertOne(newProduct);

    console.log('✅ Product created with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<Product>>({
      success: true,
      data: {
        ...newProduct,
        _id: result.insertedId.toString(),
      } as Product,
    });
  } catch (error) {
    console.error('❌ Error creating product:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create product' },
      { status: 500 }
    );
  }
}
