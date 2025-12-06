"use client";

import Link from 'next/link';
import { MapPin, Package, Star } from 'lucide-react';
import { UserTier } from '@/types';

interface StoreCardProps {
  store: {
    _id: string;
    wallet: string;
    storeName?: string;
    displayName?: string;
    username?: string;
    avatar?: string;
    banner?: string;
    tier?: number;
    storeCategory?: string;
    location?: string;
    productCount?: number;
    totalSales?: string;
  };
}

export function StoreCard({ store }: StoreCardProps) {
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

  const tierBadge = getTierBadge(store.tier);
  const categoryEmoji = getCategoryEmoji(store.storeCategory);

  return (
    <Link href={`/store/${store.wallet}`}>
      <div className="glass-card overflow-hidden card-hover">
        {/* Banner */}
        <div className="h-20 bg-gradient-to-br from-[var(--pay-blue)]/30 to-[var(--pay-purple)]/30 relative">
          {store.banner && (
            <img 
              src={store.banner} 
              alt="" 
              className="w-full h-full object-cover"
            />
          )}
        </div>

        {/* Avatar - overlapping banner */}
        <div className="px-4 -mt-8 relative z-10">
          <div className="w-16 h-16 rounded-xl bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-3xl">
            {store.avatar || '🏪'}
          </div>
        </div>

        {/* Content */}
        <div className="p-4 pt-2">
          {/* Name and badge */}
          <div className="flex items-start justify-between gap-2 mb-1">
            <h3 className="font-semibold line-clamp-1">
              {store.storeName || store.displayName || 'Store'}
            </h3>
            {tierBadge && (
              <span className={`${tierBadge.class} text-xs shrink-0`}>
                {tierBadge.text}
              </span>
            )}
          </div>

          {/* Username */}
          {store.username && (
            <p className="text-xs text-[var(--muted-foreground)] mb-2">
              @{store.username}
            </p>
          )}

          {/* Stats row */}
          <div className="flex items-center gap-3 text-xs text-[var(--muted-foreground)]">
            {store.storeCategory && (
              <span className="flex items-center gap-1">
                {categoryEmoji} {store.storeCategory}
              </span>
            )}
            {store.location && (
              <span className="flex items-center gap-1">
                <MapPin className="w-3 h-3" />
                {store.location}
              </span>
            )}
          </div>

          {/* Products count */}
          <div className="mt-3 pt-3 border-t border-[var(--border)] flex items-center justify-between">
            <span className="flex items-center gap-1 text-sm">
              <Package className="w-4 h-4 text-[var(--pay-blue)]" />
              <span className="font-medium">{store.productCount || 0}</span>
              <span className="text-[var(--muted-foreground)]">products</span>
            </span>
            <span className="text-xs text-[var(--pay-green)]">
              View Store →
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}

function getCategoryEmoji(category?: string): string {
  const map: Record<string, string> = {
    food: '🍔',
    fashion: '👕',
    art: '🎨',
    tech: '📱',
    beauty: '💄',
    home: '🏠',
    sports: '⚽',
    other: '📦',
  };
  return map[category || ''] || '📦';
}
