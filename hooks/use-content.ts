"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { CreatorContent } from "@/types";

interface ContentResponse {
  content: (CreatorContent & { creatorInfo?: any })[];
  total: number;
  hasMore: boolean;
}

interface CreateContentData {
  creator: string;
  platform: 'youtube' | 'instagram' | 'twitter';
  url: string;
  title?: string;
  description?: string;
  category?: string;
  suggestedTip?: string;
}

export function useContent(options?: {
  creator?: string;
  category?: string;
  platform?: string;
  limit?: number;
}) {
  const { creator, category, platform, limit = 20 } = options || {};

  return useQuery({
    queryKey: ["content", creator, category, platform, limit],
    queryFn: async (): Promise<ContentResponse> => {
      const params = new URLSearchParams();
      params.set('limit', limit.toString());
      if (creator) params.set('creator', creator);
      if (category) params.set('category', category);
      if (platform) params.set('platform', platform);
      
      const res = await fetch(`/api/content?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2,
  });
}

export function useCreateContent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateContentData): Promise<CreatorContent> => {
      const res = await fetch("/api/content", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["content"] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
}
