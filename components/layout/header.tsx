"use client";

import { usePathname } from 'next/navigation';
import { Wallet } from '@coinbase/onchainkit/wallet';
import { APP_NAME } from '@/lib/constants';

export function Header() {
  const pathname = usePathname();

  if (pathname.startsWith('/onboarding')) {
    return null;
  }

  return (
    <header className="sticky top-0 z-40 w-full">
      <div className="glass-card border-0 border-b border-[var(--border)] rounded-none">
        <div className="flex h-14 items-center justify-between px-4">
          <h1 className="text-xl font-bold text-gradient-brand">{APP_NAME}</h1>
          <Wallet />
        </div>
      </div>
    </header>
  );
}
