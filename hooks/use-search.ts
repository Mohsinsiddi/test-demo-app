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
