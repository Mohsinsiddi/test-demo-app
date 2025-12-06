"use client";

import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { Home, Search, PlusCircle, Bell, User } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { href: '/', icon: Home, label: 'Feed' },
  { href: '/explore', icon: Search, label: 'Explore' },
  { href: '/create', icon: PlusCircle, label: 'Create' },
  { href: '/activity', icon: Bell, label: 'Activity' },
  { href: '/profile', icon: User, label: 'Profile' },
];

export function BottomNav() {
  const pathname = usePathname();

  if (pathname.startsWith('/onboarding')) {
    return null;
  }

  return (
    <nav className="bottom-nav">
      <div className="flex justify-around items-center max-w-lg mx-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn('nav-item', isActive && 'active')}
            >
              <item.icon className="w-5 h-5" />
              <span className="text-xs">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
