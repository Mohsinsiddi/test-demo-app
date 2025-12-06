"use client";

import { FeedItem } from '@/hooks/use-feed';
import { ProductCard } from '@/components/cards/product-card';
import { ContentCard } from '@/components/cards/content-card';

interface FeedListProps {
  items: FeedItem[];
  isLoading?: boolean;
}

export function FeedList({ items, isLoading }: FeedListProps) {
  if (isLoading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="glass-card overflow-hidden">
            <div className="h-40 shimmer" />
            <div className="p-4 space-y-3">
              <div className="h-4 shimmer rounded w-3/4" />
              <div className="h-3 shimmer rounded w-1/2" />
              <div className="h-8 shimmer rounded w-1/3" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="glass-card p-8 text-center">
        <div className="text-4xl mb-4">📭</div>
        <h3 className="font-semibold mb-2">No items yet</h3>
        <p className="text-sm text-[var(--muted-foreground)]">
          Check back later or be the first to post!
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {items.map((item) => (
        item.type === 'product' 
          ? <ProductCard key={item._id} item={item} />
          : <ContentCard key={item._id} item={item} />
      ))}
    </div>
  );
}
