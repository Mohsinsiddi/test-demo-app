import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { User, UserType, UserTier, ApiResponse } from '@/types';
import { KYC_DEADLINE_DAYS } from '@/lib/constants';
import { WithId, Document } from 'mongodb';

// Helper to convert MongoDB document to User type
function toUser(doc: WithId<Document>): User {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as User;
}

// GET - Fetch user by wallet
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const wallet = searchParams.get('wallet');

    if (!wallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Wallet address required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const user = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: wallet.toLowerCase() 
    });

    console.log('📡 GET /api/users - wallet:', wallet.toLowerCase(), '→', user ? 'Found' : 'Not found');

    if (!user) {
      return NextResponse.json<ApiResponse<null>>({
        success: true,
        data: null,
      });
    }

    return NextResponse.json<ApiResponse<User>>({
      success: true,
      data: toUser(user),
    });
  } catch (error) {
    console.error('❌ Error fetching user:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch user' },
      { status: 500 }
    );
  }
}

// POST - Create or update user
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { wallet, userType, displayName, username, bio, storeName, storeCategory, location } = body;

    console.log('📡 POST /api/users - Body:', JSON.stringify(body, null, 2));

    if (!wallet) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Wallet address required' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const normalizedWallet = wallet.toLowerCase();

    // Check if user exists
    const existingUser = await db.collection(COLLECTIONS.USERS).findOne({ 
      wallet: normalizedWallet 
    });

    if (existingUser) {
      console.log('📡 Updating existing user:', normalizedWallet);
      
      const updateData: Partial<User> = {};
      if (displayName !== undefined) updateData.displayName = displayName;
      if (username !== undefined) updateData.username = username;
      if (bio !== undefined) updateData.bio = bio;
      if (storeName !== undefined) updateData.storeName = storeName;
      if (storeCategory !== undefined) updateData.storeCategory = storeCategory;
      if (location !== undefined) updateData.location = location;
      if (userType !== undefined) updateData.userType = userType;

      await db.collection(COLLECTIONS.USERS).updateOne(
        { wallet: normalizedWallet },
        { $set: updateData }
      );

      const updatedUser = await db.collection(COLLECTIONS.USERS).findOne({ 
        wallet: normalizedWallet 
      });

      console.log('✅ User updated');

      return NextResponse.json<ApiResponse<User>>({
        success: true,
        data: toUser(updatedUser!),
      });
    }

    console.log('📡 Creating new user:', normalizedWallet);

    // Create new user
    const kycDeadline = new Date();
    kycDeadline.setDate(kycDeadline.getDate() + KYC_DEADLINE_DAYS);

    const newUser: Omit<User, '_id'> = {
      wallet: normalizedWallet,
      userType: userType ?? UserType.None,
      tier: UserTier.Anonymous,
      isActive: true,
      totalSales: '0',
      hasCustomFee: false,
      customFee: 0,
      registeredAt: new Date(),
      displayName: displayName || '',
      username: username || '',
      bio: bio || '',
      storeName: storeName || '',
      storeCategory: storeCategory || '',
      location: location || '',
      kycStatus: 'pending',
      kycDeadline,
    };

    const result = await db.collection(COLLECTIONS.USERS).insertOne(newUser);
    
    console.log('✅ User created with ID:', result.insertedId.toString());

    return NextResponse.json<ApiResponse<User>>({
      success: true,
      data: {
        ...newUser,
        _id: result.insertedId.toString(),
      } as User,
    });
  } catch (error) {
    console.error('❌ Error creating/updating user:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create/update user' },
      { status: 500 }
    );
  }
}
