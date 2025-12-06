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
