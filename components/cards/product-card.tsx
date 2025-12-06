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
