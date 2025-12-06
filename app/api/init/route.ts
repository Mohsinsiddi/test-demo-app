import { NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';

export async function POST() {
  try {
    const db = await getDatabase();
    
    console.log('🔧 Initializing BasePay database...');

    // Create collections if they don't exist
    const existingCollections = await db.listCollections().toArray();
    const existingNames = existingCollections.map(c => c.name);

    // Users collection
    if (!existingNames.includes(COLLECTIONS.USERS)) {
      await db.createCollection(COLLECTIONS.USERS);
      console.log('✅ Created users collection');
    }

    // Products collection
    if (!existingNames.includes(COLLECTIONS.PRODUCTS)) {
      await db.createCollection(COLLECTIONS.PRODUCTS);
      console.log('✅ Created products collection');
    }

    // Content collection
    if (!existingNames.includes(COLLECTIONS.CONTENT)) {
      await db.createCollection(COLLECTIONS.CONTENT);
      console.log('✅ Created content collection');
    }

    // Orders collection
    if (!existingNames.includes(COLLECTIONS.ORDERS)) {
      await db.createCollection(COLLECTIONS.ORDERS);
      console.log('✅ Created orders collection');
    }

    // Tips collection
    if (!existingNames.includes(COLLECTIONS.TIPS)) {
      await db.createCollection(COLLECTIONS.TIPS);
      console.log('✅ Created tips collection');
    }

    // Create indexes for performance
    console.log('🔧 Creating indexes...');

    // Users indexes
    await db.collection(COLLECTIONS.USERS).createIndex(
      { wallet: 1 }, 
      { unique: true }
    );
    await db.collection(COLLECTIONS.USERS).createIndex({ userType: 1 });
    await db.collection(COLLECTIONS.USERS).createIndex({ isActive: 1 });
    await db.collection(COLLECTIONS.USERS).createIndex({ username: 1 }, { sparse: true });
    console.log('✅ Users indexes created');

    // Products indexes
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ seller: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ isActive: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ category: 1 });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ contractId: 1 }, { unique: true, sparse: true });
    await db.collection(COLLECTIONS.PRODUCTS).createIndex({ createdAt: -1 });
    console.log('✅ Products indexes created');

    // Content indexes
    await db.collection(COLLECTIONS.CONTENT).createIndex({ creator: 1 });
    await db.collection(COLLECTIONS.CONTENT).createIndex({ category: 1 });
    await db.collection(COLLECTIONS.CONTENT).createIndex({ createdAt: -1 });
    console.log('✅ Content indexes created');

    // Orders indexes
    await db.collection(COLLECTIONS.ORDERS).createIndex({ buyer: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ seller: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ status: 1 });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ createdAt: -1 });
    console.log('✅ Orders indexes created');

    // Tips indexes
    await db.collection(COLLECTIONS.TIPS).createIndex({ from: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ to: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ createdAt: -1 });
    console.log('✅ Tips indexes created');

    // Get collection stats
    const stats = {
      users: await db.collection(COLLECTIONS.USERS).countDocuments(),
      products: await db.collection(COLLECTIONS.PRODUCTS).countDocuments(),
      content: await db.collection(COLLECTIONS.CONTENT).countDocuments(),
      orders: await db.collection(COLLECTIONS.ORDERS).countDocuments(),
      tips: await db.collection(COLLECTIONS.TIPS).countDocuments(),
    };

    console.log('✅ Database initialization complete!');
    console.log('📊 Collection counts:', stats);

    return NextResponse.json({
      success: true,
      data: {
        message: 'Database initialized successfully',
        collections: Object.keys(COLLECTIONS),
        stats,
      },
    });
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to initialize database' },
      { status: 500 }
    );
  }
}

// GET - Check database status
export async function GET() {
  try {
    const db = await getDatabase();
    
    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);
    
    const stats: Record<string, number> = {};
    for (const name of collectionNames) {
      stats[name] = await db.collection(name).countDocuments();
    }

    return NextResponse.json({
      success: true,
      data: {
        database: 'basepay',
        collections: collectionNames,
        stats,
        initialized: collectionNames.includes('users'),
      },
    });
  } catch (error) {
    console.error('❌ Error checking database:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to check database' },
      { status: 500 }
    );
  }
}
