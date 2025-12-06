"use client";

import { useQuery } from "@tanstack/react-query";

interface FeedUser {
  wallet: string;
  displayName?: string;
  storeName?: string;
  username?: string;
  avatar?: string;
  tier: number;
  userType: number;
}

interface FeedItem {
  _id: string;
  type: 'product' | 'content';
  createdAt: string;
  data: {
    title?: string;
    description?: string;
    price?: string;
    images?: string[];
    category?: string;
    stock?: number;
    platform?: string;
    url?: string;
    thumbnail?: string;
    likes?: number;
    tips?: string;
    suggestedTip?: string;
  };
  user: FeedUser | null;
}

interface FeedResponse {
  items: FeedItem[];
  total: number;
  hasMore: boolean;
  counts: {
    products: number;
    content: number;
  };
}

type FilterType = 'all' | 'products' | 'creators';

export function useFeed(filter: FilterType = 'all', category?: string) {
  return useQuery({
    queryKey: ["feed", filter, category],
    queryFn: async (): Promise<FeedResponse> => {
      const params = new URLSearchParams();
      params.set('filter', filter);
      params.set('limit', '20');
      if (category) params.set('category', category);
      
      console.log(`📡 Fetching feed: filter=${filter}, category=${category || 'all'}`);
      
      const res = await fetch(`/api/feed?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2, // 2 minutes
  });
}

export type { FeedItem, FeedUser, FeedResponse, FilterType };
