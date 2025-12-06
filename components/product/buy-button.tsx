"use client";

import { useState, useEffect, useCallback } from 'react';
import { useAccount } from 'wagmi';
import { Loader2, ShoppingCart, Wallet } from 'lucide-react';
import { useBuyProduct } from '@/hooks/contract';
import { useTransaction } from '@/hooks/use-transaction';
import { TxStatusModal } from '@/components/shared/tx-status-modal';
import { FeeBreakdown } from './fee-breakdown';
import { Product } from '@/types';
import { toast } from 'sonner';

interface BuyButtonProps {
  product: Product;
  seller: string;
  onSuccess?: () => void;
}

export function BuyButton({ product, seller, onSuccess }: BuyButtonProps) {
  const { address, isConnected } = useAccount();
  const [showModal, setShowModal] = useState(false);
  const [deliveryType, setDeliveryType] = useState<'pickup' | 'shipping'>('pickup');

  // Contract hook
  const {
    buy,
    reset: resetBuy,
    isLoading: isProductLoading,
    isPending: isBuyPending,
    isConfirmed: isBuyConfirmed,
    txHash,
    totalPrice,
    feeAmount,
    sellerAmount,
    error: buyError,
    canBuy,
    needsApproval,
    step: buyStep,
  } = useBuyProduct({
    productId: product.contractId,
    onSuccess: (hash) => {
      console.log('🔗 Buy tx submitted:', hash);
    },
    onError: (error) => {
      console.error('❌ Buy error:', error);
      toast.error(error.message || 'Transaction failed');
    },
  });

  // Transaction tracking hook
  const {
    submitTransaction,
    confirmTransaction,
    failTransaction,
    transaction,
    isSubmitting,
    isConfirming,
    error: txError,
  } = useTransaction();

  // Track transaction in DB when tx is submitted
  useEffect(() => {
    if (txHash && !transaction) {
      submitTransaction({
        txHash: txHash as `0x${string}`,
        type: 'purchase',
        from: address || '',
        to: seller,
        amount: totalPrice.toString(),
        fee: feeAmount.toString(),
        productId: product._id,
        contractProductId: product.contractId,
      }).catch(console.error);
    }
  }, [txHash, transaction, address, seller, totalPrice, feeAmount, product, submitTransaction]);

  // Update DB when tx is confirmed
  useEffect(() => {
    if (isBuyConfirmed && txHash && transaction?.status === 'pending') {
      confirmTransaction({
        txHash,
        blockNumber: 0, // Will be filled by receipt
        blockHash: '',
        gasUsed: '',
        orderData: {
          productId: product._id,
          seller,
          amount: totalPrice.toString(),
          fee: feeAmount.toString(),
          deliveryType,
        },
      }).then(() => {
        toast.success('Purchase successful!');
        onSuccess?.();
      }).catch(console.error);
    }
  }, [isBuyConfirmed, txHash, transaction, confirmTransaction, product, seller, totalPrice, feeAmount, deliveryType, onSuccess]);

  // Handle buy click
  const handleBuy = async () => {
    if (!isConnected) {
      toast.error('Please connect your wallet');
      return;
    }

    if (!canBuy) {
      toast.error('Cannot purchase this product');
      return;
    }

    setShowModal(true);
    
    try {
      await buy();
    } catch (error) {
      console.error('Buy failed:', error);
    }
  };

  // Handle modal close
  const handleCloseModal = () => {
    setShowModal(false);
    if (transaction?.status === 'processed' || transaction?.status === 'failed') {
      resetBuy();
    }
  };

  // Check if user is the seller
  const isSeller = address?.toLowerCase() === seller.toLowerCase();

  // Determine button state
  const isLoading = isProductLoading || isBuyPending || isSubmitting || isConfirming;
  const isOutOfStock = product.stock !== undefined && product.stock <= 0;
  const isDisabled = !isConnected || !canBuy || isLoading || isSeller || isOutOfStock;

  const getButtonText = () => {
    if (!isConnected) return 'Connect Wallet';
    if (isSeller) return 'Your Product';
    if (isOutOfStock) return 'Out of Stock';
    if (isLoading) {
      if (buyStep === 'approving') return 'Approving...';
      if (buyStep === 'buying') return 'Confirming...';
      return 'Processing...';
    }
    if (needsApproval) return 'Approve & Buy';
    return 'Buy Now';
  };

  return (
    <div className="space-y-4">
      {/* Delivery Type Selection */}
      {product.deliveryOptions?.pickup && product.deliveryOptions?.shipping && (
        <div className="flex gap-2">
          <button
            onClick={() => setDeliveryType('pickup')}
            className={`flex-1 py-2 px-4 rounded-xl text-sm font-medium transition-all ${
              deliveryType === 'pickup'
                ? 'bg-[var(--pay-blue)] text-white'
                : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
            }`}
          >
            🏪 Pickup
          </button>
          <button
            onClick={() => setDeliveryType('shipping')}
            className={`flex-1 py-2 px-4 rounded-xl text-sm font-medium transition-all ${
              deliveryType === 'shipping'
                ? 'bg-[var(--pay-blue)] text-white'
                : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
            }`}
          >
            📦 Shipping
          </button>
        </div>
      )}

      {/* Fee Breakdown */}
      {totalPrice > 0n && (
        <FeeBreakdown
          price={totalPrice}
          fee={feeAmount}
          sellerAmount={sellerAmount}
          sellerTier={0} // TODO: Get from seller data
          isEth={true}
        />
      )}

      {/* Buy Button */}
      <button
        onClick={handleBuy}
        disabled={isDisabled}
        className={`w-full py-4 rounded-xl font-semibold text-lg flex items-center justify-center gap-2 transition-all ${
          isDisabled
            ? 'bg-[var(--muted)] text-[var(--muted-foreground)] cursor-not-allowed'
            : 'btn-pay'
        }`}
      >
        {isLoading ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : !isConnected ? (
          <Wallet className="w-5 h-5" />
        ) : (
          <ShoppingCart className="w-5 h-5" />
        )}
        {getButtonText()}
      </button>

      {/* Error Display */}
      {(buyError || txError) && (
        <div className="text-center text-sm text-red-400">
          {buyError?.message || txError?.message || 'Something went wrong'}
        </div>
      )}

      {/* Transaction Status Modal */}
      <TxStatusModal
        isOpen={showModal}
        onClose={handleCloseModal}
        status={transaction?.status || (isBuyPending ? 'pending' : null)}
        txHash={txHash}
        title="Purchase"
        successMessage="Your order has been placed! The seller will be notified."
        errorMessage={buyError?.message || txError?.message}
        onSuccess={onSuccess}
      />
    </div>
  );
}
