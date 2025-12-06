"use client";

import { useQuery } from "@tanstack/react-query";

interface StatsResponse {
  users: number;
  stores: number;
  creators: number;
  products: number;
  content: number;
  orders: number;
  tips: number;
  orderVolume: string;
  tipsVolume: string;
}

export function useStats() {
  return useQuery({
    queryKey: ["stats"],
    queryFn: async (): Promise<StatsResponse> => {
      const res = await fetch("/api/stats");
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
}
