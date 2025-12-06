"use client";

import Link from 'next/link';
import { UserTier } from '@/types';

interface SearchResult {
  type: 'product' | 'store' | 'creator' | 'content';
  _id: string;
  title: string;
  subtitle?: string;
  image?: string;
  price?: string;
  tier?: number;
  category?: string;
  wallet?: string;
}

interface SearchResultsProps {
  results: SearchResult[];
  isLoading: boolean;
  query: string;
}

export function SearchResults({ results, isLoading, query }: SearchResultsProps) {
  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="glass-card p-4 flex items-center gap-3">
            <div className="shimmer w-12 h-12 rounded-xl" />
            <div className="flex-1 space-y-2">
              <div className="shimmer h-4 w-3/4 rounded" />
              <div className="shimmer h-3 w-1/2 rounded" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (results.length === 0 && query) {
    return (
      <div className="glass-card p-8 text-center">
        <div className="text-4xl mb-4">🔍</div>
        <h3 className="font-semibold mb-2">No results found</h3>
        <p className="text-sm text-[var(--muted-foreground)]">
          Try different keywords or browse categories
        </p>
      </div>
    );
  }

  if (results.length === 0) {
    return null;
  }

  const getResultLink = (result: SearchResult) => {
    switch (result.type) {
      case 'product':
        return `/product/${result._id}`;
      case 'store':
        return `/store/${result.wallet}`;
      case 'creator':
        return `/creator/${result.wallet}`;
      case 'content':
        return `/content/${result._id}`;
      default:
        return '#';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'product': return '📦';
      case 'store': return '🏪';
      case 'creator': return '🎨';
      case 'content': return '📺';
      default: return '📄';
    }
  };

  const getTierBadge = (tier?: number) => {
    switch (tier) {
      case UserTier.Premium:
        return <span className="badge-premium text-xs">★</span>;
      case UserTier.Verified:
        return <span className="badge-verified text-xs">✓</span>;
      default:
        return null;
    }
  };

  const formatPrice = (price?: string) => {
    if (!price) return null;
    const num = parseFloat(price) / 1e18;
    return `${num.toFixed(4).replace(/\.?0+$/, '')} ETH`;
  };

  return (
    <div className="space-y-2">
      {results.map((result) => (
        <Link key={`${result.type}-${result._id}`} href={getResultLink(result)}>
          <div className="glass-card p-4 flex items-center gap-3 card-hover">
            {/* Image */}
            <div className="w-12 h-12 rounded-xl bg-[var(--muted)] flex items-center justify-center text-2xl shrink-0">
              {result.image && result.image.length <= 4 ? result.image : getTypeIcon(result.type)}
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <h4 className="font-medium line-clamp-1">{result.title}</h4>
                {getTierBadge(result.tier)}
              </div>
              {result.subtitle && (
                <p className="text-xs text-[var(--muted-foreground)] line-clamp-1">
                  {result.subtitle}
                </p>
              )}
            </div>

            {/* Price or Type badge */}
            <div className="shrink-0 text-right">
              {result.price ? (
                <span className="price-gradient font-semibold">
                  {formatPrice(result.price)}
                </span>
              ) : (
                <span className="text-xs text-[var(--muted-foreground)] capitalize bg-[var(--muted)] px-2 py-1 rounded-full">
                  {result.type}
                </span>
              )}
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}
