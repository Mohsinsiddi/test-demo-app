"use client";

import { useStats } from '@/hooks/use-stats';

export function StatsBanner() {
  const { data: stats, isLoading } = useStats();

  if (isLoading) {
    return (
      <div className="glass-card-success p-4">
        <div className="grid grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="text-center">
              <div className="h-6 shimmer rounded w-12 mx-auto mb-1" />
              <div className="h-3 shimmer rounded w-16 mx-auto" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="glass-card-success p-4">
      <div className="grid grid-cols-3 gap-4 text-center">
        <div>
          <div className="text-xl font-bold text-[var(--pay-green)]">
            {stats?.products?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Products</div>
        </div>
        <div>
          <div className="text-xl font-bold text-[var(--pay-purple)]">
            {stats?.creators?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Creators</div>
        </div>
        <div>
          <div className="text-xl font-bold text-[var(--pay-blue)]">
            {stats?.stores?.toLocaleString() || 0}
          </div>
          <div className="text-xs text-[var(--muted-foreground)]">Stores</div>
        </div>
      </div>
    </div>
  );
}
