#!/bin/bash

echo "🚀 BasePay Phase 3: Explore Page"
echo "================================="
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p app/api/search
mkdir -p app/explore
mkdir -p 'app/store/[wallet]'
mkdir -p 'app/creator/[wallet]'
mkdir -p components/explore

# ============================================
# API: Search - Unified Search
# ============================================
echo "📝 Creating app/api/search/route.ts..."
cat > app/api/search/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { getDatabase, COLLECTIONS } from '@/lib/mongodb';
import { UserType, ApiResponse } from '@/types';
import { WithId, Document } from 'mongodb';

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

// GET - Unified search across products, stores, creators, content
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const query = searchParams.get('q') || '';
    const type = searchParams.get('type'); // 'all' | 'products' | 'stores' | 'creators' | 'content'
    const category = searchParams.get('category');
    const limit = parseInt(searchParams.get('limit') || '20');

    const db = await getDatabase();
    const results: SearchResult[] = [];

    const searchRegex = query ? { $regex: query, $options: 'i' } : null;

    // Search Products
    if (!type || type === 'all' || type === 'products') {
      const productQuery: Record<string, any> = { isActive: true };
      if (searchRegex) {
        productQuery.$or = [
          { title: searchRegex },
          { description: searchRegex },
        ];
      }
      if (category) {
        productQuery.category = category;
      }

      const products = await db
        .collection(COLLECTIONS.PRODUCTS)
        .find(productQuery)
        .sort({ createdAt: -1 })
        .limit(type === 'products' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get seller info
      const sellerWallets = [...new Set(products.map(p => p.seller))];
      const sellers = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: sellerWallets } })
        .toArray();
      const sellerMap = new Map(sellers.map(s => [s.wallet, s]));

      products.forEach(p => {
        const seller = sellerMap.get(p.seller);
        results.push({
          type: 'product',
          _id: p._id.toString(),
          title: p.title,
          subtitle: seller?.storeName || seller?.displayName || 'Unknown Store',
          image: p.images?.[0] || '📦',
          price: p.price,
          tier: seller?.tier,
          category: p.category,
        });
      });
    }

    // Search Stores
    if (!type || type === 'all' || type === 'stores') {
      const storeQuery: Record<string, any> = { 
        userType: UserType.Store, 
        isActive: true 
      };
      if (searchRegex) {
        storeQuery.$or = [
          { storeName: searchRegex },
          { displayName: searchRegex },
          { username: searchRegex },
        ];
      }
      if (category) {
        storeQuery.storeCategory = category;
      }

      const stores = await db
        .collection(COLLECTIONS.USERS)
        .find(storeQuery)
        .sort({ totalSales: -1 })
        .limit(type === 'stores' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get product counts
      const storeWallets = stores.map(s => s.wallet);
      const productCounts = await db
        .collection(COLLECTIONS.PRODUCTS)
        .aggregate([
          { $match: { seller: { $in: storeWallets }, isActive: true } },
          { $group: { _id: '$seller', count: { $sum: 1 } } },
        ])
        .toArray();
      const countMap = new Map(productCounts.map(p => [p._id, p.count]));

      stores.forEach(s => {
        results.push({
          type: 'store',
          _id: s._id.toString(),
          title: s.storeName || s.displayName,
          subtitle: `${countMap.get(s.wallet) || 0} products`,
          image: s.avatar || '🏪',
          tier: s.tier,
          category: s.storeCategory,
          wallet: s.wallet,
        });
      });
    }

    // Search Creators
    if (!type || type === 'all' || type === 'creators') {
      const creatorQuery: Record<string, any> = { 
        userType: UserType.Creator, 
        isActive: true 
      };
      if (searchRegex) {
        creatorQuery.$or = [
          { displayName: searchRegex },
          { username: searchRegex },
          { bio: searchRegex },
        ];
      }

      const creators = await db
        .collection(COLLECTIONS.USERS)
        .find(creatorQuery)
        .sort({ registeredAt: -1 })
        .limit(type === 'creators' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get content counts
      const creatorWallets = creators.map(c => c.wallet);
      const contentCounts = await db
        .collection(COLLECTIONS.CONTENT)
        .aggregate([
          { $match: { creator: { $in: creatorWallets } } },
          { $group: { _id: '$creator', count: { $sum: 1 } } },
        ])
        .toArray();
      const contentMap = new Map(contentCounts.map(c => [c._id, c.count]));

      creators.forEach(c => {
        results.push({
          type: 'creator',
          _id: c._id.toString(),
          title: c.displayName || c.username,
          subtitle: `@${c.username} • ${contentMap.get(c.wallet) || 0} posts`,
          image: c.avatar || '🎨',
          tier: c.tier,
          wallet: c.wallet,
        });
      });
    }

    // Search Content
    if (!type || type === 'all' || type === 'content') {
      const contentQuery: Record<string, any> = {};
      if (searchRegex) {
        contentQuery.$or = [
          { title: searchRegex },
          { description: searchRegex },
        ];
      }
      if (category) {
        contentQuery.category = category;
      }

      const content = await db
        .collection(COLLECTIONS.CONTENT)
        .find(contentQuery)
        .sort({ createdAt: -1 })
        .limit(type === 'content' ? limit : Math.ceil(limit / 4))
        .toArray();

      // Get creator info
      const creatorWallets = [...new Set(content.map(c => c.creator))];
      const creators = await db
        .collection(COLLECTIONS.USERS)
        .find({ wallet: { $in: creatorWallets } })
        .toArray();
      const creatorMap = new Map(creators.map(c => [c.wallet, c]));

      content.forEach(c => {
        const creator = creatorMap.get(c.creator);
        results.push({
          type: 'content',
          _id: c._id.toString(),
          title: c.title || 'Untitled',
          subtitle: `@${creator?.username || 'creator'} • ${c.platform}`,
          image: c.thumbnail || '📺',
          category: c.category,
          wallet: c.creator,
        });
      });
    }

    // Sort results (prioritize exact matches if searching)
    if (query) {
      results.sort((a, b) => {
        const aExact = a.title.toLowerCase().includes(query.toLowerCase()) ? 1 : 0;
        const bExact = b.title.toLowerCase().includes(query.toLowerCase()) ? 1 : 0;
        return bExact - aExact;
      });
    }

    console.log(`📡 GET /api/search - q="${query}" type=${type} → ${results.length} results`);

    return NextResponse.json<ApiResponse<{ results: SearchResult[]; total: number }>>({
      success: true,
      data: {
        results: results.slice(0, limit),
        total: results.length,
      },
    });
  } catch (error) {
    console.error('❌ Error searching:', error);
    return NextResponse.json<ApiResponse<null>>(
      { success: false, error: 'Failed to search' },
      { status: 500 }
    );
  }
}
EOF

# ============================================
# COMPONENT: Search Bar
# ============================================
echo "📝 Creating components/explore/search-bar.tsx..."
cat > components/explore/search-bar.tsx << 'EOF'
"use client";

import { useState, useEffect, useCallback } from 'react';
import { Search, X } from 'lucide-react';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  autoFocus?: boolean;
}

export function SearchBar({ 
  value, 
  onChange, 
  placeholder = 'Search products, stores, creators...',
  autoFocus = false,
}: SearchBarProps) {
  const [localValue, setLocalValue] = useState(value);

  // Debounce the onChange callback
  useEffect(() => {
    const timer = setTimeout(() => {
      onChange(localValue);
    }, 300);

    return () => clearTimeout(timer);
  }, [localValue, onChange]);

  // Sync with external value changes
  useEffect(() => {
    setLocalValue(value);
  }, [value]);

  const handleClear = useCallback(() => {
    setLocalValue('');
    onChange('');
  }, [onChange]);

  return (
    <div className="relative">
      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--muted-foreground)]">
        <Search className="w-5 h-5" />
      </div>
      
      <input
        type="text"
        value={localValue}
        onChange={(e) => setLocalValue(e.target.value)}
        placeholder={placeholder}
        autoFocus={autoFocus}
        className="w-full pl-12 pr-10 py-3 bg-[var(--muted)] border border-[var(--border)] rounded-xl text-sm focus:outline-none focus:border-[var(--pay-blue)] focus:ring-2 focus:ring-[var(--pay-blue)]/20 transition-all"
      />
      
      {localValue && (
        <button
          onClick={handleClear}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 rounded-full hover:bg-[var(--border)] transition-colors"
        >
          <X className="w-4 h-4 text-[var(--muted-foreground)]" />
        </button>
      )}
    </div>
  );
}
EOF

# ============================================
# COMPONENT: Category Chips
# ============================================
echo "📝 Creating components/explore/category-chips.tsx..."
cat > components/explore/category-chips.tsx << 'EOF'
"use client";

import { STORE_CATEGORIES, CONTENT_CATEGORIES } from '@/lib/constants';

interface CategoryChipsProps {
  selected: string | null;
  onChange: (category: string | null) => void;
  type?: 'store' | 'content' | 'all';
}

export function CategoryChips({ selected, onChange, type = 'all' }: CategoryChipsProps) {
  const categories = type === 'content' 
    ? CONTENT_CATEGORIES 
    : type === 'store' 
      ? STORE_CATEGORIES 
      : [...STORE_CATEGORIES, ...CONTENT_CATEGORIES.filter(c => 
          !STORE_CATEGORIES.find(s => s.id === c.id)
        )];

  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      <button
        onClick={() => onChange(null)}
        className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
          selected === null
            ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
            : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
        }`}
      >
        All
      </button>
      
      {categories.map((cat) => (
        <button
          key={cat.id}
          onClick={() => onChange(cat.id === selected ? null : cat.id)}
          className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all flex items-center gap-1 ${
            selected === cat.id
              ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
              : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
          }`}
        >
          <span>{cat.icon}</span>
          <span>{cat.label}</span>
        </button>
      ))}
    </div>
  );
}
EOF

# ============================================
# COMPONENT: Store Card
# ============================================
echo "📝 Creating components/explore/store-card.tsx..."
cat > components/explore/store-card.tsx << 'EOF'
"use client";

import Link from 'next/link';
import { MapPin, Package, Star } from 'lucide-react';
import { UserTier } from '@/types';

interface StoreCardProps {
  store: {
    _id: string;
    wallet: string;
    storeName?: string;
    displayName?: string;
    username?: string;
    avatar?: string;
    banner?: string;
    tier?: number;
    storeCategory?: string;
    location?: string;
    productCount?: number;
    totalSales?: string;
  };
}

export function StoreCard({ store }: StoreCardProps) {
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

  const tierBadge = getTierBadge(store.tier);
  const categoryEmoji = getCategoryEmoji(store.storeCategory);

  return (
    <Link href={`/store/${store.wallet}`}>
      <div className="glass-card overflow-hidden card-hover">
        {/* Banner */}
        <div className="h-20 bg-gradient-to-br from-[var(--pay-blue)]/30 to-[var(--pay-purple)]/30 relative">
          {store.banner && (
            <img 
              src={store.banner} 
              alt="" 
              className="w-full h-full object-cover"
            />
          )}
        </div>

        {/* Avatar - overlapping banner */}
        <div className="px-4 -mt-8 relative z-10">
          <div className="w-16 h-16 rounded-xl bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-3xl">
            {store.avatar || '🏪'}
          </div>
        </div>

        {/* Content */}
        <div className="p-4 pt-2">
          {/* Name and badge */}
          <div className="flex items-start justify-between gap-2 mb-1">
            <h3 className="font-semibold line-clamp-1">
              {store.storeName || store.displayName || 'Store'}
            </h3>
            {tierBadge && (
              <span className={`${tierBadge.class} text-xs shrink-0`}>
                {tierBadge.text}
              </span>
            )}
          </div>

          {/* Username */}
          {store.username && (
            <p className="text-xs text-[var(--muted-foreground)] mb-2">
              @{store.username}
            </p>
          )}

          {/* Stats row */}
          <div className="flex items-center gap-3 text-xs text-[var(--muted-foreground)]">
            {store.storeCategory && (
              <span className="flex items-center gap-1">
                {categoryEmoji} {store.storeCategory}
              </span>
            )}
            {store.location && (
              <span className="flex items-center gap-1">
                <MapPin className="w-3 h-3" />
                {store.location}
              </span>
            )}
          </div>

          {/* Products count */}
          <div className="mt-3 pt-3 border-t border-[var(--border)] flex items-center justify-between">
            <span className="flex items-center gap-1 text-sm">
              <Package className="w-4 h-4 text-[var(--pay-blue)]" />
              <span className="font-medium">{store.productCount || 0}</span>
              <span className="text-[var(--muted-foreground)]">products</span>
            </span>
            <span className="text-xs text-[var(--pay-green)]">
              View Store →
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}

function getCategoryEmoji(category?: string): string {
  const map: Record<string, string> = {
    food: '🍔',
    fashion: '👕',
    art: '🎨',
    tech: '📱',
    beauty: '💄',
    home: '🏠',
    sports: '⚽',
    other: '📦',
  };
  return map[category || ''] || '📦';
}
EOF

# ============================================
# COMPONENT: Creator Card
# ============================================
echo "📝 Creating components/explore/creator-card.tsx..."
cat > components/explore/creator-card.tsx << 'EOF'
"use client";

import Link from 'next/link';
import { Play, Heart, Coins } from 'lucide-react';
import { UserTier } from '@/types';

interface CreatorCardProps {
  creator: {
    _id: string;
    wallet: string;
    displayName?: string;
    username?: string;
    avatar?: string;
    banner?: string;
    bio?: string;
    tier?: number;
    contentCount?: number;
    totalTipsReceived?: string;
    tipCount?: number;
  };
}

export function CreatorCard({ creator }: CreatorCardProps) {
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

  const tierBadge = getTierBadge(creator.tier);

  // Format tips amount
  const formatTips = (tips?: string) => {
    if (!tips || tips === '0') return '0';
    const num = parseFloat(tips) / 1e18;
    if (num < 0.01) return '< 0.01';
    return num.toFixed(2);
  };

  return (
    <Link href={`/creator/${creator.wallet}`}>
      <div className="glass-card overflow-hidden card-hover">
        {/* Banner */}
        <div className="h-16 bg-gradient-to-br from-[var(--pay-purple)]/30 to-[var(--pay-green)]/30 relative">
          {creator.banner && (
            <img 
              src={creator.banner} 
              alt="" 
              className="w-full h-full object-cover"
            />
          )}
        </div>

        {/* Avatar - overlapping banner */}
        <div className="px-4 -mt-8 relative z-10">
          <div className="w-16 h-16 rounded-full bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-3xl">
            {creator.avatar || '🎨'}
          </div>
        </div>

        {/* Content */}
        <div className="p-4 pt-2">
          {/* Name and badge */}
          <div className="flex items-start justify-between gap-2 mb-1">
            <h3 className="font-semibold line-clamp-1">
              {creator.displayName || 'Creator'}
            </h3>
            {tierBadge && (
              <span className={`${tierBadge.class} text-xs shrink-0`}>
                {tierBadge.text}
              </span>
            )}
          </div>

          {/* Username */}
          {creator.username && (
            <p className="text-xs text-[var(--muted-foreground)] mb-2">
              @{creator.username}
            </p>
          )}

          {/* Bio */}
          {creator.bio && (
            <p className="text-xs text-[var(--muted-foreground)] line-clamp-2 mb-3">
              {creator.bio}
            </p>
          )}

          {/* Stats row */}
          <div className="mt-3 pt-3 border-t border-[var(--border)] flex items-center justify-between">
            <div className="flex items-center gap-3 text-xs">
              <span className="flex items-center gap-1">
                <Play className="w-3 h-3 text-[var(--pay-purple)]" />
                <span className="font-medium">{creator.contentCount || 0}</span>
              </span>
              <span className="flex items-center gap-1">
                <Coins className="w-3 h-3 text-[var(--pay-gold)]" />
                <span className="font-medium">{formatTips(creator.totalTipsReceived)} ETH</span>
              </span>
            </div>
            <span className="text-xs text-[var(--pay-purple)]">
              View →
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
EOF

# ============================================
# COMPONENT: Search Results
# ============================================
echo "📝 Creating components/explore/search-results.tsx..."
cat > components/explore/search-results.tsx << 'EOF'
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
EOF

# ============================================
# HOOK: useSearch
# ============================================
echo "📝 Creating hooks/use-search.ts..."
cat > hooks/use-search.ts << 'EOF'
"use client";

import { useQuery } from "@tanstack/react-query";

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

interface SearchResponse {
  results: SearchResult[];
  total: number;
}

interface UseSearchOptions {
  query: string;
  type?: 'all' | 'products' | 'stores' | 'creators' | 'content';
  category?: string | null;
  limit?: number;
  enabled?: boolean;
}

export function useSearch({
  query,
  type = 'all',
  category,
  limit = 20,
  enabled = true,
}: UseSearchOptions) {
  return useQuery({
    queryKey: ["search", query, type, category, limit],
    queryFn: async (): Promise<SearchResponse> => {
      const params = new URLSearchParams();
      if (query) params.set('q', query);
      if (type && type !== 'all') params.set('type', type);
      if (category) params.set('category', category);
      params.set('limit', limit.toString());
      
      console.log(`📡 Searching: ${params.toString()}`);
      
      const res = await fetch(`/api/search?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: enabled,
    staleTime: 1000 * 60, // 1 minute
  });
}

export type { SearchResult, SearchResponse };
EOF

# ============================================
# PAGE: Explore
# ============================================
echo "📝 Creating app/explore/page.tsx..."
cat > app/explore/page.tsx << 'EOF'
"use client";

import { useState, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { SearchBar } from '@/components/explore/search-bar';
import { CategoryChips } from '@/components/explore/category-chips';
import { SearchResults } from '@/components/explore/search-results';
import { StoreCard } from '@/components/explore/store-card';
import { CreatorCard } from '@/components/explore/creator-card';
import { useSearch } from '@/hooks/use-search';
import { useQuery } from '@tanstack/react-query';

type TabType = 'all' | 'products' | 'stores' | 'creators';

export default function ExplorePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const initialTab = (searchParams.get('tab') as TabType) || 'all';
  const initialQuery = searchParams.get('q') || '';
  
  const [activeTab, setActiveTab] = useState<TabType>(initialTab);
  const [searchQuery, setSearchQuery] = useState(initialQuery);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  // Search results
  const { data: searchData, isLoading: isSearching } = useSearch({
    query: searchQuery,
    type: activeTab === 'all' ? 'all' : activeTab,
    category: selectedCategory,
    enabled: true,
  });

  // Fetch stores for Stores tab
  const { data: storesData, isLoading: isLoadingStores } = useQuery({
    queryKey: ['stores', selectedCategory],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (selectedCategory) params.set('category', selectedCategory);
      params.set('limit', '20');
      
      const res = await fetch(`/api/stores?${params.toString()}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: activeTab === 'stores' && !searchQuery,
  });

  // Fetch creators for Creators tab
  const { data: creatorsData, isLoading: isLoadingCreators } = useQuery({
    queryKey: ['creators'],
    queryFn: async () => {
      const res = await fetch('/api/creators?limit=20');
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: activeTab === 'creators' && !searchQuery,
  });

  // Handle tab change
  const handleTabChange = useCallback((tab: TabType) => {
    setActiveTab(tab);
    setSelectedCategory(null);
    
    // Update URL
    const params = new URLSearchParams(searchParams.toString());
    params.set('tab', tab);
    if (searchQuery) params.set('q', searchQuery);
    router.push(`/explore?${params.toString()}`, { scroll: false });
  }, [searchQuery, searchParams, router]);

  // Handle search
  const handleSearch = useCallback((query: string) => {
    setSearchQuery(query);
    
    // Update URL
    const params = new URLSearchParams(searchParams.toString());
    if (query) {
      params.set('q', query);
    } else {
      params.delete('q');
    }
    router.push(`/explore?${params.toString()}`, { scroll: false });
  }, [searchParams, router]);

  const tabs: { id: TabType; label: string; icon: string }[] = [
    { id: 'all', label: 'All', icon: '🔍' },
    { id: 'products', label: 'Products', icon: '📦' },
    { id: 'stores', label: 'Stores', icon: '🏪' },
    { id: 'creators', label: 'Creators', icon: '🎨' },
  ];

  return (
    <div className="p-4 space-y-4">
      {/* Search Bar */}
      <SearchBar
        value={searchQuery}
        onChange={handleSearch}
        placeholder="Search products, stores, creators..."
      />

      {/* Tabs */}
      <div className="flex gap-2 overflow-x-auto scrollbar-hide">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => handleTabChange(tab.id)}
            className={`px-4 py-2 rounded-xl text-sm font-medium whitespace-nowrap transition-all flex items-center gap-2 ${
              activeTab === tab.id
                ? 'bg-[var(--pay-blue)] text-white'
                : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
            }`}
          >
            <span>{tab.icon}</span>
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      {/* Category Chips (for products and stores) */}
      {(activeTab === 'products' || activeTab === 'stores' || activeTab === 'all') && (
        <CategoryChips
          selected={selectedCategory}
          onChange={setSelectedCategory}
          type={activeTab === 'stores' ? 'store' : activeTab === 'all' ? 'all' : 'store'}
        />
      )}

      {/* Results */}
      <div className="mt-4">
        {/* Search Results (when searching or All tab) */}
        {(searchQuery || activeTab === 'all' || activeTab === 'products') && (
          <SearchResults
            results={searchData?.results || []}
            isLoading={isSearching}
            query={searchQuery}
          />
        )}

        {/* Stores Grid */}
        {activeTab === 'stores' && !searchQuery && (
          <div>
            <h2 className="text-lg font-semibold mb-3">
              {selectedCategory ? `${selectedCategory} Stores` : 'All Stores'}
            </h2>
            
            {isLoadingStores ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[1, 2, 3, 4].map((i) => (
                  <div key={i} className="glass-card h-48 shimmer" />
                ))}
              </div>
            ) : storesData?.stores?.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {storesData.stores.map((store: any) => (
                  <StoreCard key={store._id} store={store} />
                ))}
              </div>
            ) : (
              <div className="glass-card p-8 text-center">
                <div className="text-4xl mb-4">🏪</div>
                <h3 className="font-semibold mb-2">No stores found</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  {selectedCategory 
                    ? `No ${selectedCategory} stores yet`
                    : 'Be the first to open a store!'}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Creators Grid */}
        {activeTab === 'creators' && !searchQuery && (
          <div>
            <h2 className="text-lg font-semibold mb-3">Featured Creators</h2>
            
            {isLoadingCreators ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[1, 2, 3, 4].map((i) => (
                  <div key={i} className="glass-card h-44 shimmer" />
                ))}
              </div>
            ) : creatorsData?.creators?.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {creatorsData.creators.map((creator: any) => (
                  <CreatorCard key={creator._id} creator={creator} />
                ))}
              </div>
            ) : (
              <div className="glass-card p-8 text-center">
                <div className="text-4xl mb-4">🎨</div>
                <h3 className="font-semibold mb-2">No creators yet</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  Be the first to share your content!
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
EOF

# ============================================
# PAGE: Store Profile
# ============================================
echo "📝 Creating app/store/[wallet]/page.tsx..."
cat > 'app/store/[wallet]/page.tsx' << 'EOF'
"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useProducts } from '@/hooks/use-products';
import { ProductCard } from '@/components/cards/product-card';
import { ChevronLeft, MapPin, Package, Star, Share2 } from 'lucide-react';
import { UserTier } from '@/types';
import { toast } from 'sonner';

interface StorePageProps {
  params: Promise<{ wallet: string }>;
}

export default function StorePage({ params }: StorePageProps) {
  const { wallet } = use(params);
  const router = useRouter();

  // Fetch store info
  const { data: storeData, isLoading: isStoreLoading } = useQuery({
    queryKey: ['store', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/users?wallet=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });

  // Fetch store products
  const { data: productsData, isLoading: isProductsLoading } = useProducts({
    seller: wallet,
    limit: 50,
  });

  const handleBack = () => router.back();

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: storeData?.storeName || 'Store',
          text: `Check out ${storeData?.storeName} on BasePay!`,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success('Link copied!');
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const getTierBadge = (tier?: number) => {
    switch (tier) {
      case UserTier.Premium:
        return { text: '★ Premium Seller', class: 'badge-premium', fee: '0.5%' };
      case UserTier.Verified:
        return { text: '✓ Verified Seller', class: 'badge-verified', fee: '1%' };
      default:
        return { text: 'New Seller', class: 'badge-info', fee: '2%' };
    }
  };

  if (isStoreLoading) {
    return (
      <div className="pb-20">
        <div className="shimmer h-32 w-full" />
        <div className="p-4 space-y-4">
          <div className="flex items-start gap-4">
            <div className="shimmer w-20 h-20 rounded-xl -mt-10" />
            <div className="flex-1 space-y-2">
              <div className="shimmer h-6 w-3/4 rounded" />
              <div className="shimmer h-4 w-1/2 rounded" />
            </div>
          </div>
          <div className="shimmer h-20 rounded-xl" />
          <div className="grid grid-cols-2 gap-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="shimmer h-48 rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!storeData) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Store Not Found</h2>
          <button onClick={handleBack} className="btn-secondary mt-4">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const tierInfo = getTierBadge(storeData.tier);

  return (
    <div className="pb-20">
      {/* Banner */}
      <div className="h-32 bg-gradient-to-br from-[var(--pay-blue)]/40 to-[var(--pay-purple)]/40 relative">
        {storeData.banner && (
          <img src={storeData.banner} alt="" className="w-full h-full object-cover" />
        )}
        
        {/* Header buttons */}
        <div className="absolute top-4 left-4 right-4 flex justify-between">
          <button
            onClick={handleBack}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={handleShare}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <Share2 className="w-5 h-5" />
          </button>
        </div>
      </div>

      <div className="p-4">
        {/* Avatar and basic info */}
        <div className="flex items-start gap-4 -mt-10 relative z-10">
          <div className="w-20 h-20 rounded-xl bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-4xl shrink-0">
            {storeData.avatar || '🏪'}
          </div>
          <div className="pt-10">
            <h1 className="text-xl font-bold">
              {storeData.storeName || storeData.displayName}
            </h1>
            {storeData.username && (
              <p className="text-sm text-[var(--muted-foreground)]">
                @{storeData.username}
              </p>
            )}
          </div>
        </div>

        {/* Badges and location */}
        <div className="flex flex-wrap items-center gap-2 mt-4">
          <span className={tierInfo.class}>{tierInfo.text}</span>
          {storeData.storeCategory && (
            <span className="badge-info">{storeData.storeCategory}</span>
          )}
          {storeData.location && (
            <span className="flex items-center gap-1 text-sm text-[var(--muted-foreground)]">
              <MapPin className="w-3 h-3" />
              {storeData.location}
            </span>
          )}
        </div>

        {/* Bio */}
        {storeData.bio && (
          <p className="mt-4 text-sm text-[var(--muted-foreground)]">
            {storeData.bio}
          </p>
        )}

        {/* Stats */}
        <div className="glass-card p-4 mt-4 grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-blue)]">
              {productsData?.products?.length || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Products</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">
              {tierInfo.fee}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Fee Rate</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">
              {storeData.tier === UserTier.Premium ? '★' : storeData.tier === UserTier.Verified ? '✓' : '-'}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Tier</div>
          </div>
        </div>

        {/* Products */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold mb-3 flex items-center gap-2">
            <Package className="w-5 h-5" />
            Products
          </h2>

          {isProductsLoading ? (
            <div className="grid grid-cols-2 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="shimmer h-48 rounded-xl" />
              ))}
            </div>
          ) : productsData?.products?.length > 0 ? (
            <div className="grid grid-cols-2 gap-4">
              {productsData.products.map((product: any) => (
                <ProductCard
                  key={product._id}
                  item={{
                    _id: product._id,
                    type: 'product',
                    createdAt: product.createdAt,
                    data: {
                      title: product.title,
                      description: product.description,
                      price: product.price,
                      images: product.images,
                      category: product.category,
                      stock: product.stock,
                    },
                    user: {
                      wallet: storeData.wallet,
                      displayName: storeData.displayName,
                      storeName: storeData.storeName,
                      username: storeData.username,
                      avatar: storeData.avatar,
                      tier: storeData.tier,
                      userType: storeData.userType,
                    },
                  }}
                />
              ))}
            </div>
          ) : (
            <div className="glass-card p-8 text-center">
              <div className="text-4xl mb-4">📦</div>
              <p className="text-[var(--muted-foreground)]">No products yet</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# PAGE: Creator Profile
# ============================================
echo "📝 Creating app/creator/[wallet]/page.tsx..."
cat > 'app/creator/[wallet]/page.tsx' << 'EOF'
"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useContent } from '@/hooks/use-content';
import { ContentCard } from '@/components/cards/content-card';
import { ChevronLeft, Play, Coins, Share2 } from 'lucide-react';
import { UserTier } from '@/types';
import { toast } from 'sonner';

interface CreatorPageProps {
  params: Promise<{ wallet: string }>;
}

export default function CreatorPage({ params }: CreatorPageProps) {
  const { wallet } = use(params);
  const router = useRouter();

  // Fetch creator info
  const { data: creatorData, isLoading: isCreatorLoading } = useQuery({
    queryKey: ['creator', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/users?wallet=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });

  // Fetch creator content
  const { data: contentData, isLoading: isContentLoading } = useContent({
    creator: wallet,
    limit: 50,
  });

  // Fetch tip stats
  const { data: tipStats } = useQuery({
    queryKey: ['tips', 'to', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/tips?to=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data.stats;
    },
  });

  const handleBack = () => router.back();

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: creatorData?.displayName || 'Creator',
          text: `Check out ${creatorData?.displayName} on BasePay!`,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success('Link copied!');
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const getTierBadge = (tier?: number) => {
    switch (tier) {
      case UserTier.Premium:
        return { text: '★ Premium Creator', class: 'badge-premium' };
      case UserTier.Verified:
        return { text: '✓ Verified Creator', class: 'badge-verified' };
      default:
        return { text: 'Creator', class: 'badge-info' };
    }
  };

  const formatTips = (amount?: string) => {
    if (!amount || amount === '0') return '0';
    const num = parseFloat(amount) / 1e18;
    return num.toFixed(4).replace(/\.?0+$/, '');
  };

  if (isCreatorLoading) {
    return (
      <div className="pb-20">
        <div className="shimmer h-32 w-full" />
        <div className="p-4 space-y-4">
          <div className="flex items-start gap-4">
            <div className="shimmer w-20 h-20 rounded-full -mt-10" />
            <div className="flex-1 space-y-2 pt-10">
              <div className="shimmer h-6 w-3/4 rounded" />
              <div className="shimmer h-4 w-1/2 rounded" />
            </div>
          </div>
          <div className="shimmer h-20 rounded-xl" />
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="shimmer h-40 rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!creatorData) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Creator Not Found</h2>
          <button onClick={handleBack} className="btn-secondary mt-4">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const tierInfo = getTierBadge(creatorData.tier);

  return (
    <div className="pb-20">
      {/* Banner */}
      <div className="h-32 bg-gradient-to-br from-[var(--pay-purple)]/40 to-[var(--pay-green)]/40 relative">
        {creatorData.banner && (
          <img src={creatorData.banner} alt="" className="w-full h-full object-cover" />
        )}
        
        {/* Header buttons */}
        <div className="absolute top-4 left-4 right-4 flex justify-between">
          <button
            onClick={handleBack}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={handleShare}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <Share2 className="w-5 h-5" />
          </button>
        </div>
      </div>

      <div className="p-4">
        {/* Avatar and basic info */}
        <div className="flex items-start gap-4 -mt-10 relative z-10">
          <div className="w-20 h-20 rounded-full bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-4xl shrink-0">
            {creatorData.avatar || '🎨'}
          </div>
          <div className="pt-10">
            <h1 className="text-xl font-bold">{creatorData.displayName}</h1>
            {creatorData.username && (
              <p className="text-sm text-[var(--muted-foreground)]">
                @{creatorData.username}
              </p>
            )}
          </div>
        </div>

        {/* Badge */}
        <div className="flex flex-wrap items-center gap-2 mt-4">
          <span className={tierInfo.class}>{tierInfo.text}</span>
        </div>

        {/* Bio */}
        {creatorData.bio && (
          <p className="mt-4 text-sm text-[var(--muted-foreground)]">
            {creatorData.bio}
          </p>
        )}

        {/* Social links */}
        {(creatorData.youtube || creatorData.instagram || creatorData.twitter) && (
          <div className="flex gap-2 mt-4">
            {creatorData.youtube && (
              <a
                href={creatorData.youtube}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-red-500/20 text-red-400 rounded-full text-sm"
              >
                YouTube
              </a>
            )}
            {creatorData.instagram && (
              <a
                href={creatorData.instagram}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-pink-500/20 text-pink-400 rounded-full text-sm"
              >
                Instagram
              </a>
            )}
            {creatorData.twitter && (
              <a
                href={creatorData.twitter}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-blue-500/20 text-blue-400 rounded-full text-sm"
              >
                Twitter
              </a>
            )}
          </div>
        )}

        {/* Stats */}
        <div className="glass-card p-4 mt-4 grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">
              {contentData?.content?.length || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Posts</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-gold)]">
              {formatTips(tipStats?.totalAmount)} ETH
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Tips Received</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">
              {tipStats?.count || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Supporters</div>
          </div>
        </div>

        {/* Tip button */}
        <button className="w-full tip-button justify-center mt-4">
          💰 Send Tip
        </button>

        {/* Content */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold mb-3 flex items-center gap-2">
            <Play className="w-5 h-5" />
            Content
          </h2>

          {isContentLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="shimmer h-40 rounded-xl" />
              ))}
            </div>
          ) : contentData?.content?.length > 0 ? (
            <div className="space-y-4">
              {contentData.content.map((content: any) => (
                <ContentCard
                  key={content._id}
                  item={{
                    _id: content._id,
                    type: 'content',
                    createdAt: content.createdAt,
                    data: {
                      platform: content.platform,
                      url: content.url,
                      title: content.title,
                      description: content.description,
                      thumbnail: content.thumbnail,
                      category: content.category,
                      suggestedTip: content.suggestedTip,
                      likes: content.likes,
                      tips: content.tips,
                    },
                    user: {
                      wallet: creatorData.wallet,
                      displayName: creatorData.displayName,
                      username: creatorData.username,
                      avatar: creatorData.avatar,
                      tier: creatorData.tier,
                      userType: creatorData.userType,
                    },
                  }}
                />
              ))}
            </div>
          ) : (
            <div className="glass-card p-8 text-center">
              <div className="text-4xl mb-4">📺</div>
              <p className="text-[var(--muted-foreground)]">No content yet</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================
# Update hooks/index.ts
# ============================================
echo "📝 Updating hooks/index.ts..."
cat > hooks/index.ts << 'EOF'
// User & Feed Hooks
export { useUser } from './use-user';
export { useFeed } from './use-feed';
export type { FeedItem, FeedUser, FeedResponse, FilterType } from './use-feed';
export { useProducts, useProduct, useCreateProduct, useUpdateProduct } from './use-products';
export { useContent, useCreateContent } from './use-content';
export { useStats } from './use-stats';
export { useLike } from './use-like';
export { useSeedStatus, useSeedDatabase } from './use-seed';
export { useSearch } from './use-search';
export type { SearchResult, SearchResponse } from './use-search';

// Transaction Hooks
export { useTransaction, useTransactionFlow } from './use-transaction';

// Contract Hooks
export * from './contract';
EOF

echo ""
echo "============================================"
echo "✅ Phase 3 Complete: Explore Page"
echo "============================================"
echo ""
echo "📁 FILES CREATED:"
echo ""
echo "app/api/"
echo "  └── search/route.ts           (Unified search API)"
echo ""
echo "app/"
echo "  ├── explore/page.tsx          (Main explore page)"
echo "  ├── store/[wallet]/page.tsx   (Store profile)"
echo "  └── creator/[wallet]/page.tsx (Creator profile)"
echo ""
echo "components/explore/"
echo "  ├── search-bar.tsx            (Debounced search input)"
echo "  ├── category-chips.tsx        (Category filter chips)"
echo "  ├── search-results.tsx        (Search results list)"
echo "  ├── store-card.tsx            (Store card component)"
echo "  └── creator-card.tsx          (Creator card component)"
echo ""
echo "hooks/"
echo "  ├── use-search.ts             (Search hook)"
echo "  └── index.ts                  (Updated exports)"
echo ""
echo "============================================"
echo "🎯 FEATURES:"
echo "============================================"
echo ""
echo "  • Unified search across products, stores, creators, content"
echo "  • Tab navigation: All | Products | Stores | Creators"
echo "  • Category filtering with chips"
echo "  • Debounced search (300ms)"
echo "  • URL state sync (?tab=stores&q=food)"
echo "  • Store profile page with products"
echo "  • Creator profile page with content"
echo "  • Tier badges throughout"
echo ""
echo "============================================"
echo "🧪 TO TEST:"
echo "============================================"
echo ""
echo "1. Run the script in your project"
echo ""
echo "2. Visit http://localhost:3000/explore"
echo ""
echo "3. Try searching for products/stores"
echo ""
echo "4. Click on a store → /store/{wallet}"
echo ""
echo "5. Click on a creator → /creator/{wallet}"
echo ""
echo "============================================"