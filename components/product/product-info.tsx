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
