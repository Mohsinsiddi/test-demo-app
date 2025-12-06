#!/bin/bash

echo "🚀 BasePay Phase 1: Transaction Infrastructure"
echo "==============================================="
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p app/api/transactions
mkdir -p 'app/api/transactions/[txHash]'
mkdir -p hooks

# ============================================
# TYPES: Add Transaction to index.ts
# ============================================
echo "📝 Updating types/index.ts..."
cat > types/index.ts << 'EOF'
// User Types
export enum UserType {
  None = 0,
  Creator = 1,
  Store = 2,
}

export enum UserTier {
  Anonymous = 0,
  Verified = 1,
  Premium = 2,
}

export interface User {
  _id?: string;
  wallet: string;
  userType: UserType;
  tier: UserTier;
  isActive: boolean;
  totalSales: string;
  hasCustomFee: boolean;
  customFee: number;
  registeredAt: Date;
  displayName?: string;
  username?: string;
  bio?: string;
  avatar?: string;
  banner?: string;
  storeName?: string;
  storeCategory?: string;
  location?: string;
  youtube?: string;
  instagram?: string;
  twitter?: string;
  kycStatus: 'pending' | 'submitted' | 'verified' | 'rejected';
  kycDeadline?: Date;
}

export interface Product {
  _id?: string;
  contractId: number;
  seller: string;
  price: string;
  paymentToken: string;
  isActive: boolean;
  metadataUri: string;
  createdAt: Date;
  title: string;
  description?: string;
  images: string[];
  category?: string;
  stock?: number;
  deliveryOptions: {
    pickup: boolean;
    shipping: boolean;
  };
}

export interface CreatorContent {
  _id?: string;
  creator: string;
  platform: 'youtube' | 'instagram' | 'twitter';
  url: string;
  title?: string;
  description?: string;
  thumbnail?: string;
  category?: string;
  suggestedTip?: string;
  createdAt: Date;
  likes: number;
  tips: string;
}

export interface Order {
  _id?: string;
  productId: string;
  buyer: string;
  seller: string;
  amount: string;
  fee: string;
  paymentToken: string;
  status: 'pending' | 'confirmed' | 'ready' | 'shipped' | 'delivered' | 'disputed' | 'cancelled';
  deliveryType: 'pickup' | 'shipping';
  shippingAddress?: string;
  trackingInfo?: string;
  txHash: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Tip {
  _id?: string;
  contentId: string;
  from: string;
  to: string;
  amount: string;
  paymentToken: string;
  txHash: string;
  createdAt: Date;
}

// ============================================
// TRANSACTION TYPES (Phase 1)
// ============================================

export type TransactionType = 'purchase' | 'tip' | 'register' | 'create_product';

export type TransactionStatus = 
  | 'pending'      // TX submitted to blockchain, waiting
  | 'confirmed'    // TX confirmed on blockchain
  | 'failed'       // TX failed
  | 'processed';   // DB fully updated

export interface Transaction {
  _id?: string;
  txHash: string;
  type: TransactionType;
  status: TransactionStatus;
  
  // Participants
  from: string;
  to?: string;
  
  // Transaction details
  amount?: string;
  fee?: string;
  paymentToken?: string;
  
  // Related entities (for linking after confirmation)
  productId?: string;          // MongoDB product ID
  contentId?: string;          // MongoDB content ID
  orderId?: string;            // MongoDB order ID (created after confirmation)
  tipId?: string;              // MongoDB tip ID (created after confirmation)
  contractProductId?: number;  // On-chain product ID
  
  // Blockchain data (filled after confirmation)
  blockNumber?: number;
  blockHash?: string;
  gasUsed?: string;
  
  // Error handling
  error?: string;
  
  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  confirmedAt?: Date;
  processedAt?: Date;
}

export interface TransactionReceipt {
  blockNumber: number;
  blockHash: string;
  gasUsed: string;
  status: 'success' | 'reverted';
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
EOF

# ============================================
# LIB: Update MongoDB with TRANSACTIONS collection
# ============================================
echo "📝 Updating lib/mongodb.ts..."
cat > lib/mongodb.ts << 'EOF'
import { MongoClient, Db } from 'mongodb';

if (!process.env.MONGODB_URI) {
  throw new Error('Please add MONGODB_URI to your environment variables');
}

const uri = process.env.MONGODB_URI;
const options = {};

let client: MongoClient;
let clientPromise: Promise<MongoClient>;

declare global {
  var _mongoClientPromise: Promise<MongoClient> | undefined;
}

if (process.env.NODE_ENV === 'development') {
  if (!global._mongoClientPromise) {
    client = new MongoClient(uri, options);
    global._mongoClientPromise = client.connect();
  }
  clientPromise = global._mongoClientPromise;
} else {
  client = new MongoClient(uri, options);
  clientPromise = client.connect();
}

export default clientPromise;

export async function getDatabase(): Promise<Db> {
  const client = await clientPromise;
  return client.db('basepay');
}

export const COLLECTIONS = {
  USERS: 'users',
  PRODUCTS: 'products',
  CONTENT: 'content',
  ORDERS: 'orders',
  TIPS: 'tips',
  TRANSACTIONS: 'transactions',
} as const;
EOF

# ============================================
# API: Update init route with transactions collection
# ============================================
echo "📝 Updating app/api/init/route.ts..."
cat > app/api/init/route.ts << 'EOF'
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

    // Transactions collection (NEW)
    if (!existingNames.includes(COLLECTIONS.TRANSACTIONS)) {
      await db.createCollection(COLLECTIONS.TRANSACTIONS);
      console.log('✅ Created transactions collection');
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
    await db.collection(COLLECTIONS.ORDERS).createIndex({ txHash: 1 }, { unique: true });
    await db.collection(COLLECTIONS.ORDERS).createIndex({ createdAt: -1 });
    console.log('✅ Orders indexes created');

    // Tips indexes
    await db.collection(COLLECTIONS.TIPS).createIndex({ from: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ to: 1 });
    await db.collection(COLLECTIONS.TIPS).createIndex({ txHash: 1 }, { unique: true });
    await db.collection(COLLECTIONS.TIPS).createIndex({ createdAt: -1 });
    console.log('✅ Tips indexes created');

    // Transactions indexes (NEW)
    await db.collection(COLLECTIONS.TRANSACTIONS).createIndex(
      { txHash: 1 }, 
      { unique: true }
    );
    await db.collection(COLLECTIONS.TRANSACTIONS).createIndex({ status: 1 });
    await db.collection(COLLECTIONS.TRANSACTIONS).createIndex({ type: 1 });
    await db.collection(COLLECTIONS.TRANSACTIONS).createIndex({ from: 1, createdAt: -1 });
    await db.collection(COLLECTIONS.TRANSACTIONS).createIndex({ createdAt: -1 });
    console.log('✅ Transactions indexes created');

    // Get collection stats
    const stats = {
      users: await db.collection(COLLECTIONS.USERS).countDocuments(),
      products: await db.collection(COLLECTIONS.PRODUCTS).countDocuments(),
      content: await db.collection(COLLECTIONS.CONTENT).countDocuments(),
      orders: await db.collection(COLLECTIONS.ORDERS).countDocuments(),
      tips: await db.collection(COLLECTIONS.TIPS).countDocuments(),
      transactions: await db.collection(COLLECTIONS.TRANSACTIONS).countDocuments(),
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
        initialized: collectionNames.includes('users') && collectionNames.includes('transactions'),
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
EOF

# ============================================
# API: Transactions - Create & List
# ============================================
echo "📝 Creating app/api/transactions/route.ts..."
cat > app/api/transactions/route.ts << 'EOF'
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
EOF

# ============================================
# API: Transactions/[txHash] - Get & Update
# ============================================
echo "📝 Creating app/api/transactions/[txHash]/route.ts..."
cat > 'app/api/transactions/[txHash]/route.ts' << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { Transaction, TransactionStatus, Order, Tip, ApiResponse } from '@/types';
import { ObjectId, WithId, Document } from 'mongodb';

function toTransaction(doc: WithId<Document>): Transaction {
  const { _id, ...rest } = doc;
  return {
    _id: _id.toString(),
    ...rest,
  } as Transaction;
}

// GET - Get transaction by txHash
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ txHash: string }> }
) {
  try {
    const { txHash } = await params;
    
    if (!/^0x[a-fA-F0-9]{64}$/.test(txHash)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid txHash format' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    const transaction = await db.collection(COLLECTIONS.TRANSACTIONS).findOne({ txHash });

    if (!transaction) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Transaction not found' },
        { status: 404 }
      );
    }

    return NextResponse.json<ApiResponse<Transaction>>({
      success: true,
      data: toTransaction(transaction),
    });
  } catch (error) {
    console.error('❌ Error fetching transaction:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to fetch transaction' },
      { status: 500 }
    );
  }
}

// PATCH - Update transaction (when confirmed/failed)
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ txHash: string }> }
) {
  try {
    const { txHash } = await params;
    const body = await request.json();
    const {
      status,
      blockNumber,
      blockHash,
      gasUsed,
      error: txError,
      // For creating related records on confirmation
      orderData,
      tipData,
    } = body;

    console.log('📡 PATCH /api/transactions/' + txHash, JSON.stringify(body, null, 2));

    if (!/^0x[a-fA-F0-9]{64}$/.test(txHash)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid txHash format' },
        { status: 400 }
      );
    }

    const db = await getDatabase();
    
    // Find existing transaction
    const existing = await db.collection(COLLECTIONS.TRANSACTIONS).findOne({ txHash });
    if (!existing) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Transaction not found' },
        { status: 404 }
      );
    }

    // Validate status transition
    const validStatuses: TransactionStatus[] = ['pending', 'confirmed', 'failed', 'processed'];
    if (status && !validStatuses.includes(status)) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Invalid status' },
        { status: 400 }
      );
    }

    const now = new Date();
    const updateData: Record<string, any> = {
      updatedAt: now,
    };

    if (status) updateData.status = status;
    if (blockNumber) updateData.blockNumber = blockNumber;
    if (blockHash) updateData.blockHash = blockHash;
    if (gasUsed) updateData.gasUsed = gasUsed;
    if (txError) updateData.error = txError;

    // If confirming, set confirmedAt
    if (status === 'confirmed') {
      updateData.confirmedAt = now;
    }

    // If processing, set processedAt
    if (status === 'processed') {
      updateData.processedAt = now;
    }

    // Handle side effects based on transaction type when confirmed
    if (status === 'confirmed' || status === 'processed') {
      const txType = existing.type;

      // PURCHASE: Create order
      if (txType === 'purchase' && orderData) {
        const newOrder: Omit<Order, '_id'> = {
          productId: existing.productId || orderData.productId,
          buyer: existing.from,
          seller: existing.to || orderData.seller,
          amount: existing.amount || orderData.amount,
          fee: existing.fee || orderData.fee || '0',
          paymentToken: existing.paymentToken,
          status: 'confirmed',
          deliveryType: orderData.deliveryType || 'pickup',
          shippingAddress: orderData.shippingAddress || '',
          trackingInfo: '',
          txHash: txHash,
          createdAt: now,
          updatedAt: now,
        };

        const orderResult = await db.collection(COLLECTIONS.ORDERS).insertOne(newOrder);
        updateData.orderId = orderResult.insertedId.toString();
        updateData.status = 'processed';
        updateData.processedAt = now;

        console.log('✅ Order created:', orderResult.insertedId.toString());

        // Update product stock
        if (existing.productId && ObjectId.isValid(existing.productId)) {
          await db.collection(COLLECTIONS.PRODUCTS).updateOne(
            { _id: new ObjectId(existing.productId) },
            { $inc: { stock: -1 } }
          );
          console.log('✅ Product stock decremented');
        }

        // Update seller total sales
        if (existing.to) {
          await db.collection(COLLECTIONS.USERS).updateOne(
            { wallet: existing.to.toLowerCase() },
            { 
              $inc: { 
                totalSalesCount: 1,
              }
            }
          );
          console.log('✅ Seller stats updated');
        }
      }

      // TIP: Create tip record
      if (txType === 'tip' && tipData) {
        const newTip: Omit<Tip, '_id'> = {
          contentId: existing.contentId || tipData.contentId || '',
          from: existing.from,
          to: existing.to || tipData.to,
          amount: existing.amount || tipData.amount,
          paymentToken: existing.paymentToken,
          txHash: txHash,
          createdAt: now,
        };

        const tipResult = await db.collection(COLLECTIONS.TIPS).insertOne(newTip);
        updateData.tipId = tipResult.insertedId.toString();
        updateData.status = 'processed';
        updateData.processedAt = now;

        console.log('✅ Tip record created:', tipResult.insertedId.toString());

        // Update content tips total
        if (existing.contentId && ObjectId.isValid(existing.contentId)) {
          await db.collection(COLLECTIONS.CONTENT).updateOne(
            { _id: new ObjectId(existing.contentId) },
            { 
              $inc: { tipsCount: 1 },
              $set: { lastTipAt: now }
            }
          );
          console.log('✅ Content tips updated');
        }
      }

      // REGISTER: Update user
      if (txType === 'register') {
        await db.collection(COLLECTIONS.USERS).updateOne(
          { wallet: existing.from.toLowerCase() },
          { 
            $set: { 
              isOnChain: true,
              onChainRegisteredAt: now,
            }
          }
        );
        updateData.status = 'processed';
        updateData.processedAt = now;
        console.log('✅ User marked as on-chain');
      }

      // CREATE_PRODUCT: Link product to contract
      if (txType === 'create_product' && existing.contractProductId) {
        if (existing.productId && ObjectId.isValid(existing.productId)) {
          await db.collection(COLLECTIONS.PRODUCTS).updateOne(
            { _id: new ObjectId(existing.productId) },
            { 
              $set: { 
                contractId: existing.contractProductId,
                isOnChain: true,
                onChainCreatedAt: now,
              }
            }
          );
          updateData.status = 'processed';
          updateData.processedAt = now;
          console.log('✅ Product linked to contract:', existing.contractProductId);
        }
      }
    }

    // Update transaction
    const result = await db.collection(COLLECTIONS.TRANSACTIONS).findOneAndUpdate(
      { txHash },
      { $set: updateData },
      { returnDocument: 'after' }
    );

    if (!result) {
      return NextResponse.json<ApiResponse<null>>(
        { success: false, error: 'Failed to update transaction' },
        { status: 500 }
      );
    }

    console.log('✅ Transaction updated:', txHash, 'Status:', result.status);

    return NextResponse.json<ApiResponse<Transaction>>({
      success: true,
      data: toTransaction(result),
    });
  } catch (error) {
    console.error('❌ Error updating transaction:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to update transaction' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# HOOKS: useTransaction
# ============================================
echo "📝 Creating hooks/use-transaction.ts..."
cat > hooks/use-transaction.ts << 'EOF'
"use client";

import { useState, useCallback } from 'react';
import { useWaitForTransactionReceipt } from 'wagmi';
import { Transaction, TransactionType, TransactionStatus } from '@/types';

interface SubmitTransactionParams {
  txHash: `0x${string}`;
  type: TransactionType;
  from: string;
  to?: string;
  amount?: string;
  fee?: string;
  paymentToken?: string;
  productId?: string;
  contentId?: string;
  contractProductId?: number;
}

interface ConfirmTransactionParams {
  txHash: string;
  blockNumber: number;
  blockHash: string;
  gasUsed: string;
  orderData?: {
    productId?: string;
    seller?: string;
    amount?: string;
    fee?: string;
    deliveryType?: 'pickup' | 'shipping';
    shippingAddress?: string;
  };
  tipData?: {
    contentId?: string;
    to?: string;
    amount?: string;
  };
}

interface UseTransactionReturn {
  // State
  transaction: Transaction | null;
  isSubmitting: boolean;
  isConfirming: boolean;
  isProcessing: boolean;
  error: Error | null;
  
  // Actions
  submitTransaction: (params: SubmitTransactionParams) => Promise<Transaction>;
  confirmTransaction: (params: ConfirmTransactionParams) => Promise<Transaction>;
  failTransaction: (txHash: string, error: string) => Promise<Transaction>;
  getTransaction: (txHash: string) => Promise<Transaction | null>;
  
  // Helpers
  reset: () => void;
  status: TransactionStatus | null;
}

export function useTransaction(): UseTransactionReturn {
  const [transaction, setTransaction] = useState<Transaction | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // Submit transaction to DB (status: pending)
  const submitTransaction = useCallback(async (params: SubmitTransactionParams): Promise<Transaction> => {
    setIsSubmitting(true);
    setError(null);

    try {
      console.log('📤 Submitting transaction to DB:', params.txHash);

      const response = await fetch('/api/transactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to submit transaction');
      }

      console.log('✅ Transaction submitted:', json.data);
      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  // Confirm transaction (status: confirmed → processed)
  const confirmTransaction = useCallback(async (params: ConfirmTransactionParams): Promise<Transaction> => {
    setIsConfirming(true);
    setError(null);

    try {
      console.log('✅ Confirming transaction:', params.txHash);

      const response = await fetch(`/api/transactions/${params.txHash}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'confirmed',
          blockNumber: params.blockNumber,
          blockHash: params.blockHash,
          gasUsed: params.gasUsed,
          orderData: params.orderData,
          tipData: params.tipData,
        }),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to confirm transaction');
      }

      console.log('✅ Transaction confirmed:', json.data);
      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsConfirming(false);
    }
  }, []);

  // Fail transaction
  const failTransaction = useCallback(async (txHash: string, errorMessage: string): Promise<Transaction> => {
    setIsProcessing(true);
    setError(null);

    try {
      console.log('❌ Failing transaction:', txHash, errorMessage);

      const response = await fetch(`/api/transactions/${txHash}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'failed',
          error: errorMessage,
        }),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to update transaction');
      }

      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsProcessing(false);
    }
  }, []);

  // Get transaction by txHash
  const getTransaction = useCallback(async (txHash: string): Promise<Transaction | null> => {
    try {
      const response = await fetch(`/api/transactions/${txHash}`);
      const json = await response.json();

      if (!json.success) {
        return null;
      }

      setTransaction(json.data);
      return json.data;
    } catch (err) {
      console.error('Failed to get transaction:', err);
      return null;
    }
  }, []);

  // Reset state
  const reset = useCallback(() => {
    setTransaction(null);
    setIsSubmitting(false);
    setIsConfirming(false);
    setIsProcessing(false);
    setError(null);
  }, []);

  return {
    transaction,
    isSubmitting,
    isConfirming,
    isProcessing,
    error,
    submitTransaction,
    confirmTransaction,
    failTransaction,
    getTransaction,
    reset,
    status: transaction?.status || null,
  };
}

// ============================================
// Integrated hook for full transaction flow
// ============================================

interface UseTransactionFlowParams {
  onSuccess?: (transaction: Transaction) => void;
  onError?: (error: Error) => void;
}

interface ExecuteParams extends SubmitTransactionParams {
  orderData?: ConfirmTransactionParams['orderData'];
  tipData?: ConfirmTransactionParams['tipData'];
}

export function useTransactionFlow({ onSuccess, onError }: UseTransactionFlowParams = {}) {
  const {
    transaction,
    isSubmitting,
    isConfirming,
    error,
    submitTransaction,
    confirmTransaction,
    failTransaction,
    reset,
    status,
  } = useTransaction();

  const [txHash, setTxHash] = useState<`0x${string}` | undefined>();

  // Wait for transaction receipt
  const { 
    data: receipt, 
    isLoading: isWaiting,
    isSuccess: isReceiptSuccess,
    isError: isReceiptError,
    error: receiptError,
  } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  // Execute full flow: submit → wait → confirm
  const execute = useCallback(async (params: ExecuteParams) => {
    try {
      // 1. Submit to DB
      await submitTransaction(params);
      
      // 2. Set txHash to trigger receipt waiting
      setTxHash(params.txHash);

    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      onError?.(error);
      throw error;
    }
  }, [submitTransaction, onError]);

  // Handle receipt success
  const handleReceiptSuccess = useCallback(async (
    receipt: NonNullable<typeof receipt>,
    orderData?: ConfirmTransactionParams['orderData'],
    tipData?: ConfirmTransactionParams['tipData']
  ) => {
    if (!txHash) return;

    try {
      const confirmed = await confirmTransaction({
        txHash,
        blockNumber: receipt.blockNumber,
        blockHash: receipt.blockHash,
        gasUsed: receipt.gasUsed.toString(),
        orderData,
        tipData,
      });

      onSuccess?.(confirmed);
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to confirm');
      onError?.(error);
    }
  }, [txHash, confirmTransaction, onSuccess, onError]);

  // Handle receipt error
  const handleReceiptError = useCallback(async () => {
    if (!txHash) return;

    try {
      await failTransaction(txHash, receiptError?.message || 'Transaction failed');
    } catch (err) {
      console.error('Failed to mark transaction as failed:', err);
    }

    onError?.(receiptError || new Error('Transaction failed'));
  }, [txHash, receiptError, failTransaction, onError]);

  return {
    transaction,
    receipt,
    txHash,
    
    // States
    isSubmitting,
    isWaiting,
    isConfirming,
    isPending: isSubmitting || isWaiting || isConfirming,
    isSuccess: status === 'processed',
    isError: !!error || isReceiptError,
    
    // Data
    status,
    error: error || receiptError,
    
    // Actions
    execute,
    handleReceiptSuccess,
    handleReceiptError,
    reset: () => {
      reset();
      setTxHash(undefined);
    },
  };
}
EOF

# ============================================
# Update hooks/index.ts
# ============================================
echo "📝 Updating hooks/index.ts..."
cat > hooks/index.ts << 'EOF'
// User & Feed Hooks
export { useUser } from './use-user';
export { useFeed } from './use-feed';
export type { FeedItem, FeedUser, FeedResponse, FilterType } from './use-feed';
export { useProducts, useProduct, useCreateProduct } from './use-products';
export { useContent, useCreateContent } from './use-content';
export { useStats } from './use-stats';
export { useLike } from './use-like';
export { useSeedStatus, useSeedDatabase } from './use-seed';

// Transaction Hooks (Phase 1)
export { useTransaction, useTransactionFlow } from './use-transaction';

// Contract Hooks
export * from './contract';
EOF

# ============================================
# Create example usage component
# ============================================
echo "📝 Creating components/examples/buy-with-transaction.tsx..."
mkdir -p components/examples
cat > components/examples/buy-with-transaction.tsx << 'EOF'
"use client";

/**
 * EXAMPLE: How to use transaction hooks with contract hooks
 * 
 * This demonstrates the full buy flow:
 * 1. User clicks buy
 * 2. Contract hook sends tx to blockchain
 * 3. Transaction hook saves to DB (pending)
 * 4. Wait for receipt
 * 5. Transaction hook updates DB (confirmed → processed)
 * 6. Order created automatically
 */

import { useState } from 'react';
import { useBuyProduct } from '@/hooks/contract';
import { useTransactionFlow } from '@/hooks/use-transaction';
import { Loader2, CheckCircle, XCircle } from 'lucide-react';

interface BuyWithTransactionProps {
  productId: number;
  productMongoId: string;
  seller: string;
  onSuccess?: () => void;
}

export function BuyWithTransaction({ 
  productId, 
  productMongoId,
  seller,
  onSuccess 
}: BuyWithTransactionProps) {
  const [deliveryType, setDeliveryType] = useState<'pickup' | 'shipping'>('pickup');

  // Contract hook for blockchain interaction
  const {
    buy,
    product,
    isLoading: isProductLoading,
    isPending: isBuyPending,
    isConfirmed: isBuyConfirmed,
    txHash: buyTxHash,
    formattedTotal,
    formattedFee,
    error: buyError,
    canBuy,
  } = useBuyProduct({
    productId,
    onSuccess: async (hash) => {
      console.log('🔗 Blockchain tx submitted:', hash);
      // Transaction flow will handle the rest
    },
    onError: (error) => {
      console.error('❌ Buy error:', error);
    },
  });

  // Transaction flow hook for DB tracking
  const {
    execute: executeTransaction,
    handleReceiptSuccess,
    isPending: isTxPending,
    isSuccess: isTxSuccess,
    status: txStatus,
    error: txError,
    reset: resetTransaction,
    receipt,
  } = useTransactionFlow({
    onSuccess: (tx) => {
      console.log('✅ Transaction fully processed:', tx);
      onSuccess?.();
    },
    onError: (error) => {
      console.error('❌ Transaction error:', error);
    },
  });

  // Handle the complete buy flow
  const handleBuy = async () => {
    if (!canBuy || !product || !buyTxHash) return;

    try {
      // 1. Execute contract buy (already done via useBuyProduct)
      // 2. Track in DB
      await executeTransaction({
        txHash: buyTxHash as `0x${string}`,
        type: 'purchase',
        from: '', // Will be filled by hook
        to: seller,
        amount: product.price.toString(),
        paymentToken: product.paymentToken,
        productId: productMongoId,
        contractProductId: productId,
        orderData: {
          productId: productMongoId,
          seller,
          amount: product.price.toString(),
          deliveryType,
        },
      });
    } catch (error) {
      console.error('Buy flow error:', error);
    }
  };

  // When buy tx is confirmed on chain, update our DB
  const handleConfirmation = async () => {
    if (!receipt || !buyTxHash) return;

    await handleReceiptSuccess(receipt, {
      productId: productMongoId,
      seller,
      amount: product?.price.toString(),
      deliveryType,
    });
  };

  // Render states
  if (isProductLoading) {
    return <div className="shimmer h-12 w-full rounded-lg" />;
  }

  const isPending = isBuyPending || isTxPending;
  const isSuccess = isBuyConfirmed && isTxSuccess;
  const error = buyError || txError;

  return (
    <div className="space-y-4">
      {/* Delivery options */}
      <div className="flex gap-2">
        <button
          onClick={() => setDeliveryType('pickup')}
          className={`flex-1 py-2 px-4 rounded-lg text-sm ${
            deliveryType === 'pickup' 
              ? 'bg-[var(--pay-blue)] text-white' 
              : 'bg-[var(--muted)]'
          }`}
        >
          🏪 Pickup
        </button>
        <button
          onClick={() => setDeliveryType('shipping')}
          className={`flex-1 py-2 px-4 rounded-lg text-sm ${
            deliveryType === 'shipping' 
              ? 'bg-[var(--pay-blue)] text-white' 
              : 'bg-[var(--muted)]'
          }`}
        >
          📦 Shipping
        </button>
      </div>

      {/* Price breakdown */}
      <div className="glass-card p-4 space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-[var(--muted-foreground)]">Price</span>
          <span>{formattedTotal} ETH</span>
        </div>
        <div className="flex justify-between">
          <span className="text-[var(--muted-foreground)]">Platform Fee</span>
          <span>{formattedFee} ETH</span>
        </div>
        <div className="divider my-2" />
        <div className="flex justify-between font-bold">
          <span>Total</span>
          <span className="price-gradient">{formattedTotal} ETH</span>
        </div>
      </div>

      {/* Buy button */}
      <button
        onClick={handleBuy}
        disabled={!canBuy || isPending || isSuccess}
        className="w-full btn-pay flex items-center justify-center gap-2"
      >
        {isPending ? (
          <>
            <Loader2 className="w-5 h-5 animate-spin" />
            {txStatus === 'pending' && 'Confirming...'}
            {isBuyPending && 'Processing...'}
          </>
        ) : isSuccess ? (
          <>
            <CheckCircle className="w-5 h-5" />
            Purchase Complete!
          </>
        ) : (
          `Buy for ${formattedTotal} ETH`
        )}
      </button>

      {/* Status */}
      {txStatus && !isSuccess && (
        <div className="text-center text-sm text-[var(--muted-foreground)]">
          Status: {txStatus}
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="glass-card p-3 border border-red-500/30 flex items-center gap-2">
          <XCircle className="w-5 h-5 text-red-400" />
          <span className="text-sm text-red-400">
            {error.message || 'Transaction failed'}
          </span>
        </div>
      )}

      {/* Success message */}
      {isSuccess && (
        <div className="glass-card-success p-4 text-center">
          <p className="font-semibold mb-1">🎉 Order Created!</p>
          <p className="text-sm text-[var(--muted-foreground)]">
            {deliveryType === 'pickup' 
              ? 'Ready for pickup soon' 
              : 'Will be shipped to your address'}
          </p>
        </div>
      )}
    </div>
  );
}
EOF

echo ""
echo "============================================"
echo "✅ Phase 1 Complete: Transaction Infrastructure"
echo "============================================"
echo ""
echo "📁 FILES CREATED/UPDATED:"
echo ""
echo "types/"
echo "  └── index.ts              (Added Transaction types)"
echo ""
echo "lib/"
echo "  └── mongodb.ts            (Added TRANSACTIONS collection)"
echo ""
echo "app/api/"
echo "  ├── init/route.ts         (Added transactions indexes)"
echo "  └── transactions/"
echo "      ├── route.ts          (POST create, GET list)"
echo "      └── [txHash]/route.ts (GET single, PATCH update)"
echo ""
echo "hooks/"
echo "  ├── use-transaction.ts    (Transaction flow hooks)"
echo "  └── index.ts              (Updated exports)"
echo ""
echo "components/examples/"
echo "  └── buy-with-transaction.tsx (Example usage)"
echo ""
echo "============================================"
echo "🔧 NEXT STEPS:"
echo "============================================"
echo ""
echo "1. Run this script in your BasePay project:"
echo "   chmod +x basepay-phase1-transactions.sh"
echo "   ./basepay-phase1-transactions.sh"
echo ""
echo "2. Reinitialize database to add transactions collection:"
echo "   curl -X POST http://localhost:3000/api/init"
echo ""
echo "3. Test the API:"
echo "   # Create a transaction"
echo "   curl -X POST http://localhost:3000/api/transactions \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"txHash\":\"0x123...\",\"type\":\"purchase\",\"from\":\"0xabc...\"}'"
echo ""
echo "   # Get transactions"
echo "   curl http://localhost:3000/api/transactions"
echo ""
echo "============================================"
echo "📊 TRANSACTION FLOW:"
echo "============================================"
echo ""
echo "  1. User clicks Buy"
echo "  2. Contract sends tx → gets txHash"
echo "  3. POST /api/transactions (status: pending)"
echo "  4. Frontend waits for receipt"
echo "  5. Receipt received"
echo "  6. PATCH /api/transactions/{txHash}"
echo "     → status: confirmed → processed"
echo "     → Creates Order/Tip automatically"
echo "  7. Show success to user"
echo ""
echo "============================================"