"use client";

import Link from 'next/link';
import { Play, Heart, Coins } from 'lucide-react';
import { UserTier } from '@/types';

interface CreatorCardProps {
  creator: {
    _id: string;
    wallet: string;
    displayName?: string;
    username?: string;
    avatar?: string;
    banner?: string;
    bio?: string;
    tier?: number;
    contentCount?: number;
    totalTipsReceived?: string;
    tipCount?: number;
  };
}

export function CreatorCard({ creator }: CreatorCardProps) {
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

  const tierBadge = getTierBadge(creator.tier);

  // Format tips amount
  const formatTips = (tips?: string) => {
    if (!tips || tips === '0') return '0';
    const num = parseFloat(tips) / 1e18;
    if (num < 0.01) return '< 0.01';
    return num.toFixed(2);
  };

  return (
    <Link href={`/creator/${creator.wallet}`}>
      <div className="glass-card overflow-hidden card-hover">
        {/* Banner */}
        <div className="h-16 bg-gradient-to-br from-[var(--pay-purple)]/30 to-[var(--pay-green)]/30 relative">
          {creator.banner && (
            <img 
              src={creator.banner} 
              alt="" 
              className="w-full h-full object-cover"
            />
          )}
        </div>

        {/* Avatar - overlapping banner */}
        <div className="px-4 -mt-8 relative z-10">
          <div className="w-16 h-16 rounded-full bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-3xl">
            {creator.avatar || '🎨'}
          </div>
        </div>

        {/* Content */}
        <div className="p-4 pt-2">
          {/* Name and badge */}
          <div className="flex items-start justify-between gap-2 mb-1">
            <h3 className="font-semibold line-clamp-1">
              {creator.displayName || 'Creator'}
            </h3>
            {tierBadge && (
              <span className={`${tierBadge.class} text-xs shrink-0`}>
                {tierBadge.text}
              </span>
            )}
          </div>

          {/* Username */}
          {creator.username && (
            <p className="text-xs text-[var(--muted-foreground)] mb-2">
              @{creator.username}
            </p>
          )}

          {/* Bio */}
          {creator.bio && (
            <p className="text-xs text-[var(--muted-foreground)] line-clamp-2 mb-3">
              {creator.bio}
            </p>
          )}

          {/* Stats row */}
          <div className="mt-3 pt-3 border-t border-[var(--border)] flex items-center justify-between">
            <div className="flex items-center gap-3 text-xs">
              <span className="flex items-center gap-1">
                <Play className="w-3 h-3 text-[var(--pay-purple)]" />
                <span className="font-medium">{creator.contentCount || 0}</span>
              </span>
              <span className="flex items-center gap-1">
                <Coins className="w-3 h-3 text-[var(--pay-gold)]" />
                <span className="font-medium">{formatTips(creator.totalTipsReceived)} ETH</span>
              </span>
            </div>
            <span className="text-xs text-[var(--pay-purple)]">
              View →
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
