"use client";
import { useEffect } from "react";
import { Wallet } from "@coinbase/onchainkit/wallet";
import { useMiniKit } from "@coinbase/onchainkit/minikit";

export default function Home() {
  const { setMiniAppReady, isMiniAppReady } = useMiniKit();

  useEffect(() => {
    if (!isMiniAppReady) {
      setMiniAppReady();
    }
  }, [setMiniAppReady, isMiniAppReady]);

  return (
    <div className="min-h-screen gradient-bg p-4">
      {/* Header */}
      <header className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gradient">BasePay</h1>
        <Wallet />
      </header>

      {/* Glass Card Test */}
      <div className="glass-card p-5 mb-4 card-hover">
        <h2 className="font-semibold mb-2">Glass Card</h2>
        <p className="text-sm text-[var(--muted-foreground)]">Testing glass effect</p>
      </div>

      {/* Glass Card Highlight */}
      <div className="glass-card-highlight p-5 mb-4 card-hover">
        <h2 className="font-semibold mb-2">Glass Highlight</h2>
        <p className="price-gradient text-2xl">₹499.00</p>
      </div>

      {/* Badges */}
      <div className="flex gap-2 mb-4 flex-wrap">
        <span className="badge-live">Live</span>
        <span className="badge-pending">Pending</span>
        <span className="badge-info">Info</span>
        <span className="badge-verified">✓ Verified</span>
      </div>

      {/* Buttons */}
      <div className="flex gap-3 mb-4">
        <button className="btn-pay">Buy Now</button>
        <button className="btn-pay-outline">Learn More</button>
      </div>

      <div className="mb-4">
        <button className="btn-success w-full">Success Button</button>
      </div>

      {/* Tip Button */}
      <div className="mb-4">
        <button className="tip-button">💰 Tip Creator</button>
      </div>

      {/* Glow Effects */}
      <div className="glass-card p-4 mb-4 glow-blue">
        <p className="text-sm">Blue Glow</p>
      </div>

      <div className="glass-card p-4 mb-4 glow-purple">
        <p className="text-sm">Purple Glow</p>
      </div>

      <div className="glass-card p-4 mb-4 glow-green">
        <p className="text-sm">Green Glow</p>
      </div>

      {/* Gradient Border */}
      <div className="gradient-border p-5 mb-4">
        <h2 className="font-semibold">Gradient Border</h2>
        <p className="text-sm text-[var(--muted-foreground)]">Rainbow border effect</p>
      </div>

      {/* Text Styles */}
      <div className="glass-card p-5 mb-4">
        <p className="text-gradient text-xl mb-2">Text Gradient</p>
        <p className="text-gradient-brand text-xl mb-2">Brand Gradient</p>
        <p className="price-highlight text-xl">₹1,299</p>
      </div>

      {/* Loading States */}
      <div className="mb-4">
        <div className="skeleton h-12 w-full mb-2"></div>
        <div className="shimmer h-12 w-full"></div>
      </div>

      {/* Animated */}
      <div className="glass-card-highlight p-5 animate-glow">
        <p className="text-sm">Animated Glow</p>
      </div>
    </div>
  );
}