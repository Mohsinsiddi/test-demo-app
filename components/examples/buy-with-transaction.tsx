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
