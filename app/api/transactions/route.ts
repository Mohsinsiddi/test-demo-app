import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Transaction, TransactionType, ApiResponse } from '@/types';
import { WithId, Document } from 'mongodb';

function toTransaction(doc: WithId<Document>): Transaction {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Transaction;
}

// GET - List transactions with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const from = searchParams.get('from');
    const type = searchParams.get('type') as TransactionType | null;
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '20');
    const skip = parseInt(searchParams.get('skip') || '0');

    const db = await getDatabase();
    
    const query: Record<string, any> = {};
    
    if (from) {
      query.from = from.toLowerCase();
    }
    if (type) {
      query.type = type;
    }
    if (status) {
      query.status = status;
    }

    console.log('📡 GET /api/transactions - Query:', JSON.stringify(query));

    const transactions = await db
      .collection(COLLECTIONS.TRANSACTIONS)
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    const total = await db.collection(COLLECTIONS.TRANSACTIONS).countDocuments(query);

    return NextResponse.json<ApiResponse<{ transactions: Transaction[]; total: number; hasMore: boolean }>>({
      success: true,
      data: {
        transactions: transactions.map(toTransaction),
        total,
        hasMore: skip + transactions.length < total,
      },
    });
  } catch (error) {
    console.error('❌ Error fetching transactions:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch transactions' },
      { status: 500 }
    );
  }
}

// POST - Create new transaction (when user submits tx to blockchain)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      txHash,
      type,
      from,
      to,
      amount,
      fee,
      paymentToken,
      productId,
      contentId,
      contractProductId,
    } = body;

    console.log('📡 POST /api/transactions - Body:', JSON.stringify(body, null, 2));

    // Validation
    if (!txHash || !type || !from) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'txHash, type, and from are required' },
        { status: 400 }
      );
    }

    // Validate txHash format
    if (!/^0x[a-fA-F0-9]{64}$/.test(txHash)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid txHash format' },
        { status: 400 }
      );
    }

    // Validate type
    const validTypes: TransactionType[] = ['purchase', 'tip', 'register', 'create_product'];
    if (!validTypes.includes(type)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid transaction type' },
        { status: 400 }
      );
    }

    const db = await getDatabase();

    // Check for duplicate txHash
    const existing = await db.collection(COLLECTIONS.TRANSACTIONS).findOne({ txHash });
    if (existing) {
      console.log('⚠️ Transaction already exists:', txHash);
      return NextResponse.json<ApiResponse<Transaction>>({
        success: true,
        data: toTransaction(existing),
      });
    }

    const now = new Date();
    const newTransaction: Omit<Transaction, '_id'> = {
      txHash,
      type,
      status: 'pending',
      from: from.toLowerCase(),
      to: to?.toLowerCase(),
      amount: amount?.toString(),
      fee: fee?.toString(),
      paymentToken: paymentToken || '0x0000000000000000000000000000000000000000',
      productId,
      contentId,
      contractProductId,
      createdAt: now,
      updatedAt: now,
    };

    const result = await db.collection(COLLECTIONS.TRANSACTIONS).insertOne(newTransaction);

    console.log('✅ Transaction created:', txHash);

    return NextResponse.json<ApiResponse<Transaction>>({
      success: true,
      data: {
        ...newTransaction,
        _id: result.insertedId.toString(),
      } as Transaction,
    });
  } catch (error) {
    console.error('❌ Error creating transaction:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to create transaction' },
      { status: 500 }
    );
  }
}
