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
