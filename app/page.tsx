"use client";

import { useEffect, useState, useCallback } from "react";
import { useMiniKit } from "@coinbase/onchainkit/minikit";
import { SplashScreen } from "@/components/splash-screen";
import { useUser } from "@/hooks/use-user";
import { APP_NAME } from "@/lib/constants";
import Link from "next/link";

export default function Home() {
  const [showSplash, setShowSplash] = useState(true);
  const { setMiniAppReady, isMiniAppReady } = useMiniKit();
  const { user, isLoading, isConnected, needsOnboarding, address } = useUser();

  useEffect(() => {
    if (!isMiniAppReady) {
      setMiniAppReady();
    }
  }, [setMiniAppReady, isMiniAppReady]);

  const handleSplashComplete = useCallback(() => {
    setShowSplash(false);
  }, []);

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashComplete} />;
  }

  if (isConnected && isLoading) {
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

  return (
    <div className="p-4">
      <div className="glass-card-highlight p-6 mb-6">
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

      <div className="grid grid-cols-2 gap-4 mb-6">
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
        <div className="glass-card p-4 card-hover">
          <div className="text-2xl mb-2">💰</div>
          <h3 className="font-semibold text-sm">Earn $PAY</h3>
          <p className="text-xs text-[var(--muted-foreground)]">Rewards & cashback</p>
        </div>
        <Link href="/create" className="glass-card p-4 card-hover block">
          <div className="text-2xl mb-2">🏪</div>
          <h3 className="font-semibold text-sm">Start Selling</h3>
          <p className="text-xs text-[var(--muted-foreground)]">List your products</p>
        </Link>
      </div>

      <div className="mb-4">
        <h3 className="text-lg font-semibold mb-3">Trending Now 🔥</h3>
        
        <div className="glass-card overflow-hidden card-hover mb-4">
          <div className="h-40 bg-gradient-to-br from-[var(--pay-blue)]/20 to-[var(--pay-purple)]/20 flex items-center justify-center">
            <span className="text-4xl">🎧</span>
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 mb-2">
              <span className="badge-verified">✓ Verified</span>
            </div>
            <h4 className="font-semibold mb-1">Premium Wireless Headphones</h4>
            <p className="text-xs text-[var(--muted-foreground)] mb-3">TechStore Official</p>
            <div className="flex items-center justify-between">
              <span className="price-gradient text-lg">₹2,999</span>
              <button className="btn-pay text-sm py-2 px-4">Buy Now</button>
            </div>
          </div>
        </div>

        <div className="glass-card overflow-hidden card-hover">
          <div className="h-32 bg-gradient-to-br from-[var(--pay-purple)]/20 to-[var(--pay-green)]/20 flex items-center justify-center relative">
            <span className="text-4xl">▶️</span>
            <span className="absolute bottom-2 right-2 badge-live">Live</span>
          </div>
          <div className="p-4">
            <h4 className="font-semibold mb-1">Building the Future of Commerce</h4>
            <p className="text-xs text-[var(--muted-foreground)] mb-3">@TechCreator • 12K views</p>
            <div className="flex items-center justify-between">
              <div className="flex gap-4 text-xs text-[var(--muted-foreground)]">
                <span>❤️ 1.2K</span>
                <span>💬 45</span>
              </div>
              <button className="tip-button text-sm py-2 px-4">💰 Tip</button>
            </div>
          </div>
        </div>
      </div>

      <div className="glass-card-success p-4">
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">1,234</div>
            <div className="text-xs text-[var(--muted-foreground)]">Products</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">567</div>
            <div className="text-xs text-[var(--muted-foreground)]">Creators</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-blue)]">89</div>
            <div className="text-xs text-[var(--muted-foreground)]">Stores</div>
          </div>
        </div>
      </div>
    </div>
  );
}
