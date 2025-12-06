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
