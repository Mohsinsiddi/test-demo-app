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
