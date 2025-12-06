#!/bin/bash

echo "🚀 BasePay Phase 2: Product Detail + Buy Flow"
echo "=============================================="
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p 'app/product/[id]'
mkdir -p components/product
mkdir -p components/shared

# ============================================
# COMPONENT: Transaction Status Modal
# ============================================
echo "📝 Creating components/shared/tx-status-modal.tsx..."
cat > components/shared/tx-status-modal.tsx << 'EOF'
"use client";

import { useEffect } from 'react';
import { Loader2, CheckCircle, XCircle, ExternalLink } from 'lucide-react';
import { TransactionStatus } from '@/types';

interface TxStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  status: TransactionStatus | null;
  txHash?: string;
  title?: string;
  successMessage?: string;
  errorMessage?: string;
  onSuccess?: () => void;
}

export function TxStatusModal({
  isOpen,
  onClose,
  status,
  txHash,
  title = 'Transaction',
  successMessage = 'Transaction completed successfully!',
  errorMessage,
  onSuccess,
}: TxStatusModalProps) {
  // Call onSuccess when processed
  useEffect(() => {
    if (status === 'processed') {
      onSuccess?.();
    }
  }, [status, onSuccess]);

  if (!isOpen) return null;

  const getStatusDisplay = () => {
    switch (status) {
      case 'pending':
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--pay-blue)] animate-spin" />,
          title: 'Confirming Transaction',
          message: 'Waiting for blockchain confirmation...',
          color: 'var(--pay-blue)',
        };
      case 'confirmed':
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--pay-purple)] animate-spin" />,
          title: 'Processing',
          message: 'Updating records...',
          color: 'var(--pay-purple)',
        };
      case 'processed':
        return {
          icon: <CheckCircle className="w-12 h-12 text-[var(--pay-green)]" />,
          title: 'Success!',
          message: successMessage,
          color: 'var(--pay-green)',
        };
      case 'failed':
        return {
          icon: <XCircle className="w-12 h-12 text-red-400" />,
          title: 'Transaction Failed',
          message: errorMessage || 'Something went wrong. Please try again.',
          color: 'red',
        };
      default:
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--muted-foreground)] animate-spin" />,
          title: 'Processing',
          message: 'Please wait...',
          color: 'var(--muted-foreground)',
        };
    }
  };

  const display = getStatusDisplay();
  const isComplete = status === 'processed' || status === 'failed';
  const baseScanUrl = process.env.NEXT_PUBLIC_CHAIN_ID === '8453'
    ? 'https://basescan.org/tx/'
    : 'https://sepolia.basescan.org/tx/';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={isComplete ? onClose : undefined}
      />
      
      {/* Modal */}
      <div className="relative glass-card p-6 max-w-sm w-full text-center animate-in fade-in zoom-in duration-200">
        {/* Icon */}
        <div className="flex justify-center mb-4">
          {display.icon}
        </div>

        {/* Title */}
        <h3 className="text-xl font-bold mb-2">{display.title}</h3>

        {/* Message */}
        <p className="text-[var(--muted-foreground)] text-sm mb-4">
          {display.message}
        </p>

        {/* Progress dots for pending states */}
        {!isComplete && (
          <div className="flex justify-center gap-1 mb-4">
            <div 
              className={`w-2 h-2 rounded-full ${status === 'pending' ? 'bg-[var(--pay-blue)]' : 'bg-[var(--muted)]'}`}
            />
            <div 
              className={`w-2 h-2 rounded-full ${status === 'confirmed' ? 'bg-[var(--pay-purple)]' : 'bg-[var(--muted)]'}`}
            />
            <div 
              className={`w-2 h-2 rounded-full ${status === 'processed' ? 'bg-[var(--pay-green)]' : 'bg-[var(--muted)]'}`}
            />
          </div>
        )}

        {/* Transaction hash link */}
        {txHash && (
          <a
            href={`${baseScanUrl}${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-xs text-[var(--pay-blue)] hover:underline mb-4"
          >
            View on BaseScan
            <ExternalLink className="w-3 h-3" />
          </a>
        )}

        {/* Close button (only when complete) */}
        {isComplete && (
          <button
            onClick={onClose}
            className={`w-full py-3 rounded-xl font-medium transition-colors ${
              status === 'processed'
                ? 'bg-[var(--pay-green)] text-white hover:opacity-90'
                : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
            }`}
          >
            {status === 'processed' ? 'Done' : 'Close'}
          </button>
        )}
      </div>
    </div>
  );
}
EOF

# ============================================
# COMPONENT: Fee Breakdown
# ============================================
echo "📝 Creating components/product/fee-breakdown.tsx..."
cat > components/product/fee-breakdown.tsx << 'EOF'
"use client";

import { UserTier } from '@/types';
import { formatEther } from 'viem';

interface FeeBreakdownProps {
  price: bigint;
  fee: bigint;
  sellerAmount: bigint;
  sellerTier: number;
  isEth?: boolean;
  showTierInfo?: boolean;
}

export function FeeBreakdown({
  price,
  fee,
  sellerAmount,
  sellerTier,
  isEth = true,
  showTierInfo = true,
}: FeeBreakdownProps) {
  const symbol = isEth ? 'ETH' : 'USDC';
  
  const formatAmount = (amount: bigint) => {
    const formatted = formatEther(amount);
    // Show up to 6 decimal places
    const num = parseFloat(formatted);
    if (num < 0.000001) return '< 0.000001';
    return num.toFixed(6).replace(/\.?0+$/, '');
  };

  const getTierInfo = (tier: number) => {
    switch (tier) {
      case UserTier.Premium:
        return { name: 'Premium', fee: '0.5%', color: 'var(--pay-green)', badge: '★' };
      case UserTier.Verified:
        return { name: 'Verified', fee: '1%', color: 'var(--pay-blue)', badge: '✓' };
      default:
        return { name: 'Anonymous', fee: '2%', color: 'var(--muted-foreground)', badge: '' };
    }
  };

  const tierInfo = getTierInfo(sellerTier);

  return (
    <div className="glass-card p-4 space-y-3">
      {/* Tier info */}
      {showTierInfo && (
        <div className="flex items-center justify-between text-sm">
          <span className="text-[var(--muted-foreground)]">Seller Tier</span>
          <span 
            className="flex items-center gap-1 font-medium"
            style={{ color: tierInfo.color }}
          >
            {tierInfo.badge} {tierInfo.name} ({tierInfo.fee} fee)
          </span>
        </div>
      )}

      <div className="divider" />

      {/* Price breakdown */}
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-[var(--muted-foreground)]">Item Price</span>
          <span>{formatAmount(price)} {symbol}</span>
        </div>
        
        <div className="flex justify-between">
          <span className="text-[var(--muted-foreground)]">Platform Fee ({tierInfo.fee})</span>
          <span className="text-[var(--muted-foreground)]">-{formatAmount(fee)} {symbol}</span>
        </div>

        <div className="flex justify-between text-xs text-[var(--muted-foreground)]">
          <span>Seller Receives</span>
          <span>{formatAmount(sellerAmount)} {symbol}</span>
        </div>
      </div>

      <div className="divider" />

      {/* Total */}
      <div className="flex justify-between items-center">
        <span className="font-semibold">You Pay</span>
        <span className="text-xl font-bold price-gradient">
          {formatAmount(price)} {symbol}
        </span>
      </div>
    </div>
  );
}
EOF

# ============================================
# COMPONENT: Product Info
# ============================================
echo "📝 Creating components/product/product-info.tsx..."
cat > components/product/product-info.tsx << 'EOF'
"use client";

import { Product, User, UserTier } from '@/types';
import { MapPin, Package, Truck, Clock } from 'lucide-react';
import { formatEther } from 'viem';
import Link from 'next/link';

interface ProductInfoProps {
  product: Product;
  seller?: {
    displayName?: string;
    storeName?: string;
    tier?: number;
    avatar?: string;
    location?: string;
    wallet?: string;
  } | null;
}

export function ProductInfo({ product, seller }: ProductInfoProps) {
  const formatPrice = (price: string) => {
    const eth = formatEther(BigInt(price));
    const num = parseFloat(eth);
    return num.toFixed(4).replace(/\.?0+$/, '');
  };

  const getTierBadge = (tier?: number) => {
    switch (tier) {
      case UserTier.Premium:
        return { text: '★ Premium', class: 'badge-premium' };
      case UserTier.Verified:
        return { text: '✓ Verified', class: 'badge-verified' };
      default:
        return null;
    }
  };

  const tierBadge = getTierBadge(seller?.tier);
  const timeAgo = getTimeAgo(new Date(product.createdAt));

  return (
    <div className="space-y-4">
      {/* Images */}
      <div className="aspect-square bg-gradient-to-br from-[var(--pay-blue)]/20 to-[var(--pay-purple)]/20 rounded-2xl flex items-center justify-center">
        {product.images?.[0] ? (
          typeof product.images[0] === 'string' && product.images[0].length <= 4 ? (
            <span className="text-8xl">{product.images[0]}</span>
          ) : (
            <img 
              src={product.images[0]} 
              alt={product.title}
              className="w-full h-full object-cover rounded-2xl"
            />
          )
        ) : (
          <span className="text-8xl">📦</span>
        )}
      </div>

      {/* Title & Price */}
      <div>
        <div className="flex items-start justify-between gap-4">
          <h1 className="text-2xl font-bold">{product.title}</h1>
          <div className="text-right">
            <div className="text-2xl font-bold price-gradient">
              {formatPrice(product.price)} ETH
            </div>
            {/* Could add USD equivalent here */}
          </div>
        </div>

        {/* Category & Time */}
        <div className="flex items-center gap-2 mt-2 text-sm text-[var(--muted-foreground)]">
          {product.category && (
            <span className="bg-[var(--muted)] px-2 py-1 rounded-full">
              {product.category}
            </span>
          )}
          <span className="flex items-center gap-1">
            <Clock className="w-3 h-3" />
            {timeAgo}
          </span>
        </div>
      </div>

      {/* Seller Info */}
      {seller && (
        <Link 
          href={`/store/${seller.wallet}`}
          className="glass-card p-4 flex items-center gap-3 card-hover"
        >
          <div className="w-12 h-12 rounded-full bg-[var(--muted)] flex items-center justify-center text-2xl">
            {seller.avatar || '🏪'}
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2">
              <span className="font-semibold">
                {seller.storeName || seller.displayName || 'Store'}
              </span>
              {tierBadge && (
                <span className={tierBadge.class}>{tierBadge.text}</span>
              )}
            </div>
            {seller.location && (
              <div className="flex items-center gap-1 text-sm text-[var(--muted-foreground)]">
                <MapPin className="w-3 h-3" />
                {seller.location}
              </div>
            )}
          </div>
        </Link>
      )}

      {/* Description */}
      {product.description && (
        <div>
          <h3 className="font-semibold mb-2">Description</h3>
          <p className="text-[var(--muted-foreground)] text-sm leading-relaxed">
            {product.description}
          </p>
        </div>
      )}

      {/* Delivery Options */}
      <div>
        <h3 className="font-semibold mb-2">Delivery Options</h3>
        <div className="flex gap-2">
          {product.deliveryOptions?.pickup && (
            <div className="flex items-center gap-2 bg-[var(--muted)] px-3 py-2 rounded-lg text-sm">
              <Package className="w-4 h-4 text-[var(--pay-blue)]" />
              Pickup Available
            </div>
          )}
          {product.deliveryOptions?.shipping && (
            <div className="flex items-center gap-2 bg-[var(--muted)] px-3 py-2 rounded-lg text-sm">
              <Truck className="w-4 h-4 text-[var(--pay-purple)]" />
              Shipping Available
            </div>
          )}
        </div>
      </div>

      {/* Stock */}
      {product.stock !== undefined && (
        <div className="flex items-center gap-2 text-sm">
          <span className={product.stock > 5 ? 'text-[var(--pay-green)]' : 'text-orange-400'}>
            {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
          </span>
        </div>
      )}
    </div>
  );
}

// Helper function
function getTimeAgo(date: Date): string {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor(diff / (1000 * 60));

  if (days > 30) return `${Math.floor(days / 30)}mo ago`;
  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  if (minutes > 0) return `${minutes}m ago`;
  return 'Just now';
}
EOF

# ============================================
# COMPONENT: Buy Button
# ============================================
echo "📝 Creating components/product/buy-button.tsx..."
cat > components/product/buy-button.tsx << 'EOF'
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
EOF

# ============================================
# PAGE: Product Detail
# ============================================
echo "📝 Creating app/product/[id]/page.tsx..."
cat > 'app/product/[id]/page.tsx' << 'EOF'
"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useProduct } from '@/hooks/use-products';
import { ProductInfo } from '@/components/product/product-info';
import { BuyButton } from '@/components/product/buy-button';
import { ChevronLeft, Share2, Heart } from 'lucide-react';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';
import { toast } from 'sonner';

interface ProductPageProps {
  params: Promise<{ id: string }>;
}

export default function ProductPage({ params }: ProductPageProps) {
  const { id } = use(params);
  const router = useRouter();
  const { address } = useUser();
  const { data, isLoading, error } = useProduct(id);
  const likeMutation = useLike();
  const [isLiked, setIsLiked] = useState(false);

  const handleBack = () => {
    router.back();
  };

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: data?.product?.title,
          text: `Check out ${data?.product?.title} on BasePay!`,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success('Link copied to clipboard!');
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const handleLike = async () => {
    if (!address || isLiked) return;
    
    try {
      await likeMutation.mutateAsync({
        itemId: id,
        itemType: 'product',
        userWallet: address,
      });
      setIsLiked(true);
      toast.success('Added to favorites!');
    } catch (error) {
      console.error('Like failed:', error);
    }
  };

  const handlePurchaseSuccess = () => {
    toast.success('Order placed successfully!');
    // Could redirect to orders page or show order details
  };

  if (isLoading) {
    return (
      <div className="p-4 space-y-4">
        {/* Header skeleton */}
        <div className="flex items-center justify-between">
          <div className="shimmer w-10 h-10 rounded-full" />
          <div className="flex gap-2">
            <div className="shimmer w-10 h-10 rounded-full" />
            <div className="shimmer w-10 h-10 rounded-full" />
          </div>
        </div>
        
        {/* Image skeleton */}
        <div className="shimmer aspect-square rounded-2xl" />
        
        {/* Title skeleton */}
        <div className="space-y-2">
          <div className="shimmer h-8 w-3/4 rounded" />
          <div className="shimmer h-6 w-1/2 rounded" />
        </div>
        
        {/* Seller skeleton */}
        <div className="shimmer h-20 rounded-xl" />
        
        {/* Button skeleton */}
        <div className="shimmer h-14 rounded-xl" />
      </div>
    );
  }

  if (error || !data?.product) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Product Not Found</h2>
          <p className="text-[var(--muted-foreground)] text-sm mb-4">
            This product may have been removed or doesn't exist.
          </p>
          <button onClick={handleBack} className="btn-secondary">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const { product, seller } = data;

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="sticky top-0 z-30 bg-[var(--background)]/80 backdrop-blur-lg">
        <div className="flex items-center justify-between p-4">
          <button
            onClick={handleBack}
            className="w-10 h-10 rounded-full bg-[var(--muted)] flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          
          <div className="flex gap-2">
            <button
              onClick={handleLike}
              disabled={isLiked}
              className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                isLiked 
                  ? 'bg-red-500/20 text-red-400' 
                  : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
              }`}
            >
              <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
            </button>
            <button
              onClick={handleShare}
              className="w-10 h-10 rounded-full bg-[var(--muted)] flex items-center justify-center hover:bg-[var(--muted)]/80"
            >
              <Share2 className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 space-y-6">
        <ProductInfo product={product} seller={seller} />
      </div>

      {/* Fixed Buy Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-[var(--background)]/95 backdrop-blur-lg border-t border-[var(--border)]">
        <div className="max-w-lg mx-auto">
          <BuyButton
            product={product}
            seller={product.seller}
            onSuccess={handlePurchaseSuccess}
          />
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# Update Product Card to link to detail page
# ============================================
echo "📝 Updating components/cards/product-card.tsx..."
cat > components/cards/product-card.tsx << 'EOF'
"use client";

import { Heart, ShoppingCart } from 'lucide-react';
import { FeedItem } from '@/hooks/use-feed';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';
import Link from 'next/link';

interface ProductCardProps {
  item: FeedItem;
}

export function ProductCard({ item }: ProductCardProps) {
  const { address } = useUser();
  const likeMutation = useLike();
  const [likes, setLikes] = useState(item.data.likes || 0);
  const [isLiked, setIsLiked] = useState(false);

  const handleLike = async (e: React.MouseEvent) => {
    e.preventDefault(); // Prevent navigation
    e.stopPropagation();
    
    if (!address || isLiked) return;
    
    try {
      const result = await likeMutation.mutateAsync({
        itemId: item._id,
        itemType: 'product',
        userWallet: address,
      });
      setLikes(result.likes);
      setIsLiked(true);
    } catch (error) {
      console.error('Failed to like:', error);
    }
  };

  // Format price (assuming 18 decimals)
  const formatPrice = (price: string) => {
    const num = parseFloat(price) / 1e18;
    if (num < 0.0001) return '< 0.0001 ETH';
    return `${num.toFixed(4).replace(/\.?0+$/, '')} ETH`;
  };

  const getTierBadge = (tier: number) => {
    switch (tier) {
      case 2: return { text: '★ Premium', class: 'badge-premium' };
      case 1: return { text: '✓ Verified', class: 'badge-verified' };
      default: return null;
    }
  };

  const tierBadge = item.user ? getTierBadge(item.user.tier) : null;

  return (
    <Link href={`/product/${item._id}`} className="block">
      <div className="glass-card overflow-hidden card-hover">
        {/* Image */}
        <div className="h-40 bg-gradient-to-br from-[var(--pay-blue)]/20 to-[var(--pay-purple)]/20 flex items-center justify-center relative">
          <span className="text-5xl">{item.data.images?.[0] || '📦'}</span>
          {item.data.stock !== undefined && item.data.stock < 5 && item.data.stock > 0 && (
            <span className="absolute top-2 right-2 badge-warning text-xs">
              Only {item.data.stock} left
            </span>
          )}
          {item.data.stock === 0 && (
            <span className="absolute top-2 right-2 bg-red-500/80 text-white text-xs px-2 py-1 rounded-full">
              Sold Out
            </span>
          )}
        </div>

        {/* Content */}
        <div className="p-4">
          {/* Badge */}
          {tierBadge && (
            <div className="mb-2">
              <span className={tierBadge.class}>{tierBadge.text}</span>
            </div>
          )}

          {/* Title */}
          <h4 className="font-semibold mb-1 line-clamp-1">{item.data.title}</h4>

          {/* Store name */}
          <p className="text-xs text-[var(--muted-foreground)] mb-3">
            {item.user?.avatar} {item.user?.storeName || item.user?.displayName || 'Unknown Store'}
          </p>

          {/* Price and actions */}
          <div className="flex items-center justify-between">
            <span className="price-gradient text-lg font-bold">
              {formatPrice(item.data.price || '0')}
            </span>
            
            <div className="flex items-center gap-2">
              <button 
                onClick={handleLike}
                disabled={isLiked || likeMutation.isPending}
                className={`p-2 rounded-lg transition-colors ${
                  isLiked 
                    ? 'bg-red-500/20 text-red-400' 
                    : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
                }`}
              >
                <Heart className={`w-4 h-4 ${isLiked ? 'fill-current' : ''}`} />
              </button>
              <div className="btn-pay text-sm py-2 px-3 flex items-center gap-1">
                <ShoppingCart className="w-4 h-4" />
              </div>
            </div>
          </div>

          {/* Likes count */}
          <div className="mt-2 text-xs text-[var(--muted-foreground)]">
            ❤️ {likes.toLocaleString()} likes
          </div>
        </div>
      </div>
    </Link>
  );
}
EOF

# ============================================
# Update useProducts hook to get single product with seller
# ============================================
echo "📝 Updating hooks/use-products.ts..."
cat > hooks/use-products.ts << 'EOF'
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Product } from "@/types";

interface ProductsResponse {
  products: Product[];
  total: number;
  hasMore: boolean;
}

interface SingleProductResponse {
  product: Product;
  seller: {
    displayName?: string;
    storeName?: string;
    tier?: number;
    avatar?: string;
    location?: string;
    wallet?: string;
  } | null;
}

interface CreateProductData {
  seller: string;
  title: string;
  description?: string;
  price: string;
  images?: string[];
  category?: string;
  stock?: number;
  deliveryOptions?: {
    pickup: boolean;
    shipping: boolean;
  };
}

export function useProducts(options?: {
  seller?: string;
  category?: string;
  search?: string;
  limit?: number;
}) {
  const { seller, category, search, limit = 20 } = options || {};

  return useQuery({
    queryKey: ["products", seller, category, search, limit],
    queryFn: async (): Promise<ProductsResponse> => {
      const params = new URLSearchParams();
      params.set('limit', limit.toString());
      if (seller) params.set('seller', seller);
      if (category) params.set('category', category);
      if (search) params.set('search', search);
      
      const res = await fetch(`/api/products?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2,
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: ["product", id],
    queryFn: async (): Promise<SingleProductResponse> => {
      console.log('📡 Fetching product:', id);
      const res = await fetch(`/api/products/${id}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      console.log('📡 Product data:', json.data);
      return json.data;
    },
    enabled: !!id,
    staleTime: 1000 * 60 * 2,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateProductData): Promise<Product> => {
      const res = await fetch("/api/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
}

export function useUpdateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...data }: { id: string } & Partial<CreateProductData>): Promise<Product> => {
      const res = await fetch(`/api/products/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["product", variables.id] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
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
export { useProducts, useProduct, useCreateProduct, useUpdateProduct } from './use-products';
export { useContent, useCreateContent } from './use-content';
export { useStats } from './use-stats';
export { useLike } from './use-like';
export { useSeedStatus, useSeedDatabase } from './use-seed';

// Transaction Hooks
export { useTransaction, useTransactionFlow } from './use-transaction';

// Contract Hooks
export * from './contract';
EOF

echo ""
echo "============================================"
echo "✅ Phase 2 Complete: Product Detail + Buy Flow"
echo "============================================"
echo ""
echo "📁 FILES CREATED/UPDATED:"
echo ""
echo "components/shared/"
echo "  └── tx-status-modal.tsx     (Transaction status modal)"
echo ""
echo "components/product/"
echo "  ├── product-info.tsx        (Product details display)"
echo "  ├── fee-breakdown.tsx       (Fee tier breakdown)"
echo "  └── buy-button.tsx          (Buy with transaction tracking)"
echo ""
echo "components/cards/"
echo "  └── product-card.tsx        (Updated with Link to detail)"
echo ""
echo "app/product/[id]/"
echo "  └── page.tsx                (Product detail page)"
echo ""
echo "hooks/"
echo "  ├── use-products.ts         (Added useUpdateProduct)"
echo "  └── index.ts                (Updated exports)"
echo ""
echo "============================================"
echo "🎯 BUY FLOW:"
echo "============================================"
echo ""
echo "  1. User opens /product/{id}"
echo "  2. Sees product info, seller, fee breakdown"
echo "  3. Selects delivery type (pickup/shipping)"
echo "  4. Clicks 'Buy Now'"
echo "  5. Modal shows: 'Confirming Transaction...'"
echo "  6. TX confirmed on blockchain"
echo "  7. Modal shows: 'Processing...'"
echo "  8. Order created in DB"
echo "  9. Modal shows: 'Success!' ✓"
echo ""
echo "============================================"
echo "🧪 TO TEST:"
echo "============================================"
echo ""
echo "1. Run the script:"
echo "   chmod +x basepay-phase2-product.sh"
echo "   ./basepay-phase2-product.sh"
echo ""
echo "2. Click on any product in the feed"
echo "   → Opens /product/{id}"
echo ""
echo "3. Click 'Buy Now'"
echo "   → Wallet prompts for transaction"
echo "   → Modal tracks status"
echo "   → Order created on success"
echo ""
echo "============================================"