"use client";

import { useEffect, useState, useCallback } from "react";
import { useMiniKit } from "@coinbase/onchainkit/minikit";
import { SplashScreen } from "@/components/splash-screen";
import { useUser } from "@/hooks/use-user";
import { useFeed, FilterType } from "@/hooks/use-feed";
import { useSeedStatus, useSeedDatabase } from "@/hooks/use-seed";
import { FeedFilters } from "@/components/feed/feed-filters";
import { FeedList } from "@/components/feed/feed-list";
import { StatsBanner } from "@/components/feed/stats-banner";
import { APP_NAME } from "@/lib/constants";
import { Loader2, Database } from "lucide-react";
import Link from "next/link";
import { toast } from "sonner";

export default function Home() {
  const [showSplash, setShowSplash] = useState(true);
  const [filter, setFilter] = useState<FilterType>('all');
  const { setMiniAppReady, isMiniAppReady } = useMiniKit();
  const { user, isLoading: isUserLoading, isConnected, needsOnboarding, address } = useUser();
  
  // Feed data
  const { data: feedData, isLoading: isFeedLoading, error: feedError } = useFeed(filter);
  
  // Seed status
  const { data: seedStatus } = useSeedStatus();
  const seedMutation = useSeedDatabase();

  useEffect(() => {
    if (!isMiniAppReady) {
      setMiniAppReady();
    }
  }, [setMiniAppReady, isMiniAppReady]);

  const handleSplashComplete = useCallback(() => {
    setShowSplash(false);
  }, []);

  const handleSeedDatabase = async () => {
    try {
      await seedMutation.mutateAsync();
      toast.success('Database seeded with demo data!');
    } catch (error) {
      toast.error('Failed to seed database');
    }
  };

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashComplete} />;
  }

  if (isConnected && isUserLoading) {
    return (
      <div className="p-4 flex items-center justify-center min-h-[50vh]">
        <div className="text-center">
          <div className="shimmer h-12 w-12 rounded-full mx-auto mb-4" />
          <p className="text-[var(--muted-foreground)]">Loading your profile...</p>
        </div>
      </div>
    );
  }

  if (needsOnboarding) {
    return (
      <div className="p-4">
        <div className="glass-card-highlight p-6 text-center">
          <div className="text-4xl mb-4">🎉</div>
          <h2 className="text-xl font-bold mb-2">Welcome to {APP_NAME}!</h2>
          <p className="text-[var(--muted-foreground)] text-sm mb-4">
            Complete your profile to start buying, selling, or creating content.
          </p>
          <p className="text-xs text-[var(--muted-foreground)] mb-4">
            Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
          </p>
          <Link href="/onboarding" className="btn-pay inline-block">
            Set Up Profile
          </Link>
        </div>
      </div>
    );
  }

  const getTierName = (tier: number) => {
    switch (tier) {
      case 0: return 'Anonymous';
      case 1: return 'Verified';
      case 2: return 'Premium';
      default: return 'Anonymous';
    }
  };

  const getUserTypeName = (type: number) => {
    switch (type) {
      case 1: return '🎨 Creator';
      case 2: return '🏪 Store';
      default: return '👤 User';
    }
  };

  // Check if we need to show seed button
  const showSeedButton = seedStatus && !seedStatus.seeded;

  return (
    <div className="p-4 space-y-4">
      {/* Welcome Card */}
      <div className="glass-card-highlight p-5">
        <h2 className="text-xl font-bold mb-2">
          {user ? `Welcome back${user.displayName ? `, ${user.displayName}` : ''}! 👋` : `Welcome to ${APP_NAME} 👋`}
        </h2>
        <p className="text-[var(--muted-foreground)] text-sm">
          Discover local stores, tip creators, and shop with crypto.
        </p>
        {user && (
          <div className="mt-3 flex gap-2 flex-wrap">
            <span className="badge-info">{getUserTypeName(user.userType)}</span>
            <span className="badge-verified">✓ {getTierName(user.tier)}</span>
          </div>
        )}
        {!isConnected && (
          <p className="text-xs text-[var(--muted-foreground)] mt-3">
            Connect your wallet to get started
          </p>
        )}
      </div>

      {/* Seed Database Button (only if no data) */}
      {showSeedButton && (
        <div className="glass-card p-4 border-2 border-dashed border-[var(--pay-blue)]/50">
          <div className="flex items-center gap-3">
            <Database className="w-8 h-8 text-[var(--pay-blue)]" />
            <div className="flex-1">
              <h3 className="font-semibold text-sm">Database is empty</h3>
              <p className="text-xs text-[var(--muted-foreground)]">
                Add demo data to see the feed in action
              </p>
            </div>
            <button
              onClick={handleSeedDatabase}
              disabled={seedMutation.isPending}
              className="btn-pay text-sm py-2 px-4 flex items-center gap-2"
            >
              {seedMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Seeding...
                </>
              ) : (
                'Seed Data'
              )}
            </button>
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-3">
        <Link href="/explore" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🛍️</div>
          <h3 className="font-semibold text-sm">Browse Products</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Shop local stores</p>
        </Link>
        <Link href="/explore?tab=creators" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🎨</div>
          <h3 className="font-semibold text-sm">Discover Creators</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Support talent</p>
        </Link>
      </div>

      {/* Feed Section */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg font-semibold">Feed 🔥</h3>
          {feedData && (
            <span className="text-xs text-[var(--muted-foreground)]">
              {feedData.total} items
            </span>
          )}
        </div>

        {/* Filters */}
        <FeedFilters activeFilter={filter} onFilterChange={setFilter} />

        {/* Feed Error */}
        {feedError && (
          <div className="glass-card p-4 border border-red-500/30 mt-4">
            <p className="text-red-400 text-sm">Failed to load feed. Please try again.</p>
          </div>
        )}

        {/* Feed List */}
        <div className="mt-4">
          <FeedList 
            items={feedData?.items || []} 
            isLoading={isFeedLoading} 
          />
        </div>

        {/* Load More */}
        {feedData?.hasMore && (
          <div className="mt-4 text-center">
            <button className="btn-secondary text-sm py-2 px-6">
              Load More
            </button>
          </div>
        )}
      </div>

      {/* Stats Banner */}
      <StatsBanner />
    </div>
  );
}
