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
