#!/bin/bash

echo "🚀 BasePay API Routes Setup"
echo "============================"

# Create API directories
echo ""
echo "📁 Creating API directories..."
mkdir -p app/api/products
mkdir -p app/api/products/[id]
mkdir -p app/api/content
mkdir -p app/api/content/[id]
mkdir -p app/api/orders
mkdir -p app/api/orders/[id]
mkdir -p app/api/tips
mkdir -p app/api/feed
mkdir -p app/api/stores
mkdir -p app/api/creators

# ============================================
# API: PRODUCTS - List & Create
# ============================================
echo "📝 Creating app/api/products/route.ts..."
cat > app/api/products/route.ts << 'EOF'
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
EOF

# ============================================
# API: PRODUCTS/[ID] - Get, Update, Delete single product
# ============================================
echo "📝 Creating app/api/products/[id]/route.ts..."
cat > 'app/api/products/[id]/route.ts' << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Product, ApiResponse } from '@/types';
import { ObjectId, WithId, Document } from 'mongodb';

function toProduct(doc: WithId<Document>): Product {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Product;
}

// GET - Get single product
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid product ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const product = await db.collection(COLLECTIONS.PRODUCTS).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!product) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Product not found' },
        { status: 404 }
      );
    }

    // Get seller info
    const seller = await db.collection(COLLECTIONS.USERS).findOne({
      wallet: product.seller
    });

    return NextResponse.json<ApiResponse<{ product: Product; seller: any }>>({
      success: true,
      data: {
        product: toProduct(product),
        seller: seller ? {
          displayName: seller.displayName,
          storeName: seller.storeName,
          tier: seller.tier,
          avatar: seller.avatar,
        } : null,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching product:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch product' },
      { status: 500 }
    );
  }
}

// PATCH - Update product
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { seller, ...updateData } = body;

    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid product ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    // Verify ownership
    const existing = await db.collection(COLLECTIONS.PRODUCTS).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Product not found' },
        { status: 404 }
      );
    }

    if (seller && existing.seller !== seller.toLowerCase()) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Not authorized to update this product' },
        { status: 403 }
      );
    }

    // Update
    const result = await db.collection(COLLECTIONS.PRODUCTS).findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: { ...updateData, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Failed to update product' },
        { status: 500 }
      );
    }

    return NextResponse.json<ApiResponse<Product>>({
      success: true,
      data: toProduct(result),
    });
  } catch (error) {
    console.error('❌ Error updating product:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to update product' },
      { status: 500 }
    );
  }
}

// DELETE - Delete product (soft delete)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { searchParams } = new URL(request.url);
    const seller = searchParams.get('seller');

    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid product ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    // Verify ownership
    const existing = await db.collection(COLLECTIONS.PRODUCTS).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Product not found' },
        { status: 404 }
      );
    }

    if (seller && existing.seller !== seller.toLowerCase()) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Not authorized to delete this product' },
        { status: 403 }
      );
    }

    // Soft delete
    await db.collection(COLLECTIONS.PRODUCTS).updateOne(
      { _id: new ObjectId(id) },
      { $set: { isActive: false, deletedAt: new Date() } }
    );

    return NextResponse.json<ApiResponse<{ deleted: boolean }>>({
      success: true,
      data: { deleted: true },
    });
  } catch (error) {
    console.error('❌ Error deleting product:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to delete product' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# API: CONTENT - Creator content CRUD
# ============================================
echo "📝 Creating app/api/content/route.ts..."
cat > app/api/content/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { CreatorContent, ApiResponse, UserType } from '@/types';
import { WithId, Document } from 'mongodb';

function toContent(doc: WithId<Document>): CreatorContent {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as CreatorContent;
}

// GET - List content with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const creator = searchParams.get('creator');
    const category = searchParams.get('category');
    const platform = searchParams.get('platform');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {};
    
    if (creator) {
      query.creator = creator.toLowerCase();
    }
    if (category) {
      query.category = category;
    }
    if (platform) {
      query.platform = platform;
    }

    console.log('📡 GET /api/content - Query:', JSON.stringify(query));

    const content = await db
      .collection(COLLECTIONS.CONTENT)
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.CONTENT).countDocuments(query);

    // Get creator info for each content
    const creatorWallets = [...new Set(content.map(c => c.creator))];
    const creators = await db
      .collection(COLLECTIONS.USERS)
      .find({ wallet: { $in: creatorWallets } })
      .toArray();

    const creatorMap = new Map(creators.map(c => [c.wallet, c]));

    const contentWithCreators = content.map(c => ({
      ...toContent(c),
      creatorInfo: creatorMap.get(c.creator) ? {
        displayName: creatorMap.get(c.creator)?.displayName,
        username: creatorMap.get(c.creator)?.username,
        avatar: creatorMap.get(c.creator)?.avatar,
        tier: creatorMap.get(c.creator)?.tier,
      } : null,
    }));

    return NextResponse.json<ApiResponse<{ content: any[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        content: contentWithCreators,
        total,
        hasMore: skip + content.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching content:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch content' },
      { status: 500 }
    );
  }
}

// POST - Create new content
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      creator,
      platform,
      url,
      title,
      description,
      thumbnail,
      category,
      suggestedTip,
    } = body;

    console.log('📡 POST /api/content - Body:', JSON.stringify(body, null, 2));

    // Validation
    if (!creator || !platform || !url) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'creator, platform, and url are required' },
        { status: 400 }
      );
    }

    if (!['youtube', 'instagram', 'twitter'].includes(platform)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid platform. Must be youtube, instagram, or twitter' },
        { status: 400 }
      );
    }

    const db = await getDatabase();

    // Check if creator is registered
    const user = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: creator.toLowerCase() 
    });

    if (!user) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Creator not registered' },
        { status: 400 }
      );
    }

    if (user.userType !== UserType.Creator) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'User is not a creator' },
        { status: 400 }
      );
    }

    const newContent: Omit<CreatorContent, '_id'> = {
      creator: creator.toLowerCase(),
      platform,
      url,
      title: title || '',
      description: description || '',
      thumbnail: thumbnail || '',
      category: category || 'entertainment',
      suggestedTip: suggestedTip || '0',
      createdAt: new Date(),
      likes: 0,
      tips: '0',
    };

    const result = await db.collection(COLLECTIONS.CONTENT).insertOne(newContent);

    console.log('✅ Content created with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<CreatorContent>>({
      success: true,
      data: {
        ...newContent,
        _id: result.insertedId.toString(),
      } as CreatorContent,
    });
  } catch (error) {
    console.error('❌ Error creating content:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create content' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# API: CONTENT/[ID] - Get, Update, Delete single content
# ============================================
echo "📝 Creating app/api/content/[id]/route.ts..."
cat > 'app/api/content/[id]/route.ts' << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { CreatorContent, ApiResponse } from '@/types';
import { ObjectId, WithId, Document } from 'mongodb';

function toContent(doc: WithId<Document>): CreatorContent {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as CreatorContent;
}

// GET - Get single content
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid content ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const content = await db.collection(COLLECTIONS.CONTENT).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!content) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Content not found' },
        { status: 404 }
      );
    }

    // Get creator info
    const creator = await db.collection(COLLECTIONS.USERS).findOne({
      wallet: content.creator
    });

    return NextResponse.json<ApiResponse<{ content: CreatorContent; creator: any }>>({
      success: true,
      data: {
        content: toContent(content),
        creator: creator ? {
          displayName: creator.displayName,
          username: creator.username,
          tier: creator.tier,
          avatar: creator.avatar,
          bio: creator.bio,
        } : null,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching content:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch content' },
      { status: 500 }
    );
  }
}

// PATCH - Update content
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { creator, ...updateData } = body;

    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid content ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    const existing = await db.collection(COLLECTIONS.CONTENT).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Content not found' },
        { status: 404 }
      );
    }

    if (creator && existing.creator !== creator.toLowerCase()) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Not authorized to update this content' },
        { status: 403 }
      );
    }

    const result = await db.collection(COLLECTIONS.CONTENT).findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: { ...updateData, updatedAt: new Date() } },
      { returnDocument: 'after' }
    );

    if (!result) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Failed to update content' },
        { status: 500 }
      );
    }

    return NextResponse.json<ApiResponse<CreatorContent>>({
      success: true,
      data: toContent(result),
    });
  } catch (error) {
    console.error('❌ Error updating content:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to update content' },
      { status: 500 }
    );
  }
}

// DELETE - Delete content
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { searchParams } = new URL(request.url);
    const creator = searchParams.get('creator');

    if (!ObjectId.isValid(id)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid content ID' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    const existing = await db.collection(COLLECTIONS.CONTENT).findOne({ 
      _id: new ObjectId(id) 
    });

    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Content not found' },
        { status: 404 }
      );
    }

    if (creator && existing.creator !== creator.toLowerCase()) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Not authorized to delete this content' },
        { status: 403 }
      );
    }

    await db.collection(COLLECTIONS.CONTENT).deleteOne({ _id: new ObjectId(id) });

    return NextResponse.json<ApiResponse<{ deleted: boolean }>>({
      success: true,
      data: { deleted: true },
    });
  } catch (error) {
    console.error('❌ Error deleting content:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to delete content' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# API: ORDERS - Order management
# ============================================
echo "📝 Creating app/api/orders/route.ts..."
cat > app/api/orders/route.ts << 'EOF'
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
EOF

# ============================================
# API: ORDERS/[ID] - Get & Update single order
# ============================================
echo "📝 Creating app/api/orders/[id]/route.ts..."
cat > 'app/api/orders/[id]/route.ts' << 'EOF'
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
EOF

# ============================================
# API: TIPS - Tip tracking
# ============================================
echo "📝 Creating app/api/tips/route.ts..."
cat > app/api/tips/route.ts << 'EOF'
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
EOF

# ============================================
# API: FEED - Combined feed (products + content)
# ============================================
echo "📝 Creating app/api/feed/route.ts..."
cat > app/api/feed/route.ts << 'EOF'
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
EOF

# ============================================
# API: STORES - List stores
# ============================================
echo "📝 Creating app/api/stores/route.ts..."
cat > app/api/stores/route.ts << 'EOF'
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
EOF

# ============================================
# API: CREATORS - List creators
# ============================================
echo "📝 Creating app/api/creators/route.ts..."
cat > app/api/creators/route.ts << 'EOF'
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
EOF

# ============================================
# API: STATS - Platform statistics
# ============================================
echo "📝 Creating app/api/stats/route.ts..."
mkdir -p app/api/stats
cat > app/api/stats/route.ts << 'EOF'
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
EOF

# ============================================
# API: LIKE - Like content/products
# ============================================
echo "📝 Creating app/api/like/route.ts..."
mkdir -p app/api/like
cat > app/api/like/route.ts << 'EOF'
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
EOF

echo ""
echo "============================================"
echo "✅ All API Routes Created!"
echo "============================================"
echo ""
echo "📋 API ENDPOINTS CREATED:"
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│ PRODUCTS                                                │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ GET    /api/products         List products (filters)   │"
echo "│ POST   /api/products         Create product            │"
echo "│ GET    /api/products/[id]    Get single product        │"
echo "│ PATCH  /api/products/[id]    Update product            │"
echo "│ DELETE /api/products/[id]    Delete product            │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ CONTENT                                                 │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ GET    /api/content          List content (filters)    │"
echo "│ POST   /api/content          Create content            │"
echo "│ GET    /api/content/[id]     Get single content        │"
echo "│ PATCH  /api/content/[id]     Update content            │"
echo "│ DELETE /api/content/[id]     Delete content            │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ ORDERS                                                  │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ GET    /api/orders           List orders (filters)     │"
echo "│ POST   /api/orders           Create order              │"
echo "│ GET    /api/orders/[id]      Get single order          │"
echo "│ PATCH  /api/orders/[id]      Update order status       │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ TIPS                                                    │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ GET    /api/tips             List tips (with stats)    │"
echo "│ POST   /api/tips             Record new tip            │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ FEED & DISCOVERY                                        │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ GET    /api/feed             Combined feed             │"
echo "│ GET    /api/stores           List stores               │"
echo "│ GET    /api/creators         List creators             │"
echo "│ GET    /api/stats            Platform statistics       │"
echo "│ POST   /api/like             Like content/product      │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
echo "🧪 TO TEST APIs:"
echo ""
echo "# Health check"
echo "curl http://localhost:3000/api/health"
echo ""
echo "# Get feed"
echo "curl http://localhost:3000/api/feed"
echo ""
echo "# Get products"
echo "curl http://localhost:3000/api/products"
echo ""
echo "# Get stats"
echo "curl http://localhost:3000/api/stats"
echo ""
echo "# Create product (example)"
echo 'curl -X POST http://localhost:3000/api/products \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"seller":"0x123...","title":"Test Product","price":"1000000000000000000"}'"'"
echo ""
echo "============================================"