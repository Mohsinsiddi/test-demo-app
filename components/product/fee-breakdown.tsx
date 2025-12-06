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
